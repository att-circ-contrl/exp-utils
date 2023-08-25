function ftdata_ephys = euHLev_readAndCleanSignals( folder, ephys_chans, ...
  trial_config, artifact_config, notch_freqs, notch_bw )

% function ftdata_ephys = euHLev_readAndCleanSignals( folder, ephys_chans, ...
%   trial_config, artifact_config, notch_freqs, notch_bw )
%
% This reads Field Trip trial data from the specified folder, performing
% artifact rejection and notch filtering.
%
% This can be used to read continuous data or event-segmented data, depending
% on what's passed as "trial_config".
%
% NOTE - Channel names specified as '' are skipped (removed from the list
% before calling FT's read functions).
%
% NOTE - For large datasets, call euFT_iterateAcrossFolderBatchingDerived
% instead. This is intended for quick and dirty processing of datasets that
% fit in memory, without splitting into LFP/spike waveforms.
%
% NOTE - This does _not_ detrend or demean data, so it's safe for reading
% magnitudes, phase angles, event codes, and so forth.
%
% NOTE - Events and waveforms have timestamps relative to the start of the
% recording, not the start of the trim window.
%
% "folder" is the folder to read from.
% "ephys_chans" is a cell array containing channel names to read. If this is
%   empty, no ephys data is read (an empty struct array is returned).
% "trial_config" is a scalar (for monolithic data), a structure (for
%   automatic segmentation around events), or a matrix (for manually
%   supplied trial definitions).
%   As a scalar (in the range 0 to 0.5) it's the amount of time to trim from
%   the start and end of the ephys data as a fraction of the untrimmed length.
%   As a matrix, it's a Field Trip trial definition structure passed as "trl"
%   when reading the data.
%   As a structure, it has the following fields:
%     "trigtimes" is a series of trigger event times, in seconds.
%     "trig_window_ms" [ start stop ] is a duration span in milliseconds
%       to capture for each event, with the trigger at time zero.
%     "train_gap_ms" is a duration in milliseconds. Events that are separated
%       by no more than this time are considered part of an event train, per
%       euFT_getTrainTrialDefs().
% "artifact_config" is a structure containing configuration information for
%   one or more artifact detection methods. Fields may be absent if unused.
%   "detect_level" (-2..+2) is a tuning parameter for automated artifact
%     detection; positive values make it less sensitive. NaN disables it.
%   "event_squash_times" is a vector containing time values (in seconds) of
%     known artifacts to squash (e.g. stimulation trigger times). If this is
%     absent or empty but event_squash_window_ms is provided, the t=0 time
%     in each trial is used.
%   "event_squash_window_ms" [ start stop ] is a duration span in milliseconds
%     to NaN out around squashed events.
%   "exp_fit_fenceposts_ms" is a vector containing fenceposts in milliseconds
%     for exponential curve fitting, per nlArt_removeMultipleExpDecays().
%     FIXME - This ignores squash times and assumes events at t=0!
%   "ramp_span_ms" [ start stop ] is a duration span in milliseconds for
%     correcting DC steps from stimulation, per nlFT_rampOverStimStep().
%     This requires event_squash_window_ms to be set.
%     FIXME - This ignores squash times and assumes events at t=0!
% "notch_freqs" is a vector containing notch filter frequencies. An empty
%   vector disables notch filtering.
% "notch_bw" is the notch filter bandwidth in Hz. NaN disables filtering.
%
% "ftdata_ephys" is a Field Trip data structure containing ephys data for
%   the specified ephys channels. NOTE - This will be an empty struct array
%   if there were no ephys channels specified or no matching channels found.


ftdata_ephys = struct([]);

if isempty(trial_config)
  trial_config = 0;
end

if isempty(artifact_config)
  artifact_config = struct();
end


chanmask = logical([]);
for lidx = 1:length(ephys_chans)
  chanmask(lidx) = ~isempty(ephys_chans{lidx});
end
ephys_chans = ephys_chans(chanmask);


if ~isempty(ephys_chans)

  % Read the header.
  header = ft_read_header( folder, 'headerformat', 'nlFT_readHeader' );


  % Read the raw ephys data.

  chans_wanted = ft_channelselection( ephys_chans, header.label, {} );

  % Only continue if we actually found channels.
  if ~isempty(chans_wanted)

    %
    % Figure out our trial definition(s) and read raw data.

    if isstruct(trial_config)

      % Data structure. Event-based trials.
      samprate = header.Fs;
      sampcount = header.nSamples;

      % This saves train metadata as extra columns, which are preserved
      % as "trialinfo" in the processed data structure.
      trialdef = euFT_getTrainTrialDefs( samprate, sampcount, ...
        trial_config.trigtimes, trial_config.trig_window_ms, ...
        trial_config.train_gap_ms );

    elseif length(trial_config) > 1
      % Matrix. This is a native trial definition structure.
      trialdef = trial_config;
    else
      % 1x1 scalar; this is a trim fraction.
      trim_fraction = trial_config;
      [ sampfirst samplast ] = ...
        nlUtil_getTrimmedSampleSpan( header.nSamples, trim_fraction );
      trialdef = [ sampfirst, samplast, (sampfirst - 1) ];
    end

    config_load = struct( ...
      'headerfile', folder, 'headerformat', 'nlFT_readHeader', ...
      'datafile', folder, 'dataformat', 'nlFT_readDataDouble', ...
      'trl', trialdef, ...
      'detrend', 'no', 'demean', 'no', 'feedback', 'no' );
    config_load.channel = chans_wanted;

    ftdata_ephys = ft_preprocessing( config_load );


    %
    % Perform artifact removal first, so that artifacts don't cause ringing.
    % This will leave NaN holes.


    % Automated artifact removal based on excursions in the absolute value of
    % the signal or of its derivative.

    artifact_detect_level = NaN;
    if isfield(artifact_config, 'detect_level')
      artifact_detect_level = artifact_config.detect_level;
    end

    if ~isnan(artifact_detect_level)
      artparams = nlChan_getArtifactDefaults();
      artparams.ampthresh = artparams.ampthresh + artifact_detect_level;
      artparams.diffthresh = artparams.diffthresh + artifact_detect_level;

      iterfunc_art = ...
        @( wavedata, timedata, samprate, trialidx, chanidx, chanlabel ) ...
          helper_iterate_artifacts( artparams, wavedata, samprate );

      [ newtrials fracbad ] = ...
        nlFT_iterateAcrossData( ftdata_ephys, iterfunc_art );
      ftdata_ephys.trial = newtrials;
    end


    % Curve-fitting known stimulation artifacts.

    if isfield(artifact_config, 'exp_fit_fenceposts_ms')
      % FIXME - This ignores "event_squash_times" and assumes events at t=0!
      [ ftdata_ephys fitlist ] = nlFT_removeMultipleExpDecays( ...
        ftdata_ephys, artifact_config.exp_fit_fenceposts_ms / 1000 );
    end


    % Paving over known stimulation artifacts.

    if isfield(artifact_config, 'event_squash_window_ms')
      if isfield(artifact_config, 'ramp_span_ms')

        % We want ramping.
        % FIXME - This ignores "event_squash_times" and assumes events at t=0!

        ftdata_ephys = nlFT_rampOverStimStep( ftdata_ephys, ...
          artifact_config.ramp_span_ms / 1000, ...
          artifact_config.event_squash_window_ms / 1000 );

      else

        % Just squash the specified areas.

        % Get artifact masks; either trial trigger times or a supplied list.
        if isfield(artifact_config, 'event_squash_times') ...
          windowmasks = ...
            nlFT_getWindowsAroundEvents( ftdata_ephys, ...
              artifact_config.event_squash_window_ms, ...
              artifact_config.event_squash_times );
        else
          % Using t=0 times as event times.
          windowmasks = ...
            nlFT_getWindowsAroundEvents( ftdata_ephys, ...
              artifact_config.event_squash_window_ms, [] );
        end

        % Do the artifact squashing.
        ftdata_ephys = ...
          nlFT_applyTimeWindowSquash( ftdata_ephys, windowmasks );

      end
    end


    %
    % Perform notch filtering second.

    if (~isempty(notch_freqs)) && (~isnan(notch_bw))

      % Interpolate NaNs, filter, and then restore NaNs.

      thismask = nlFT_getNaNMask(ftdata_ephys);
      ftdata_ephys = nlFT_fillNaN(ftdata_ephys);

      ftdata_ephys = ...
        euFT_doBrickNotchRemoval( ftdata_ephys, notch_freqs, notch_bw );

      ftdata_ephys = nlFT_applyNaNMask(ftdata_ephys, thismask);

    end

  end

end


% Done.
end



%
% Helper Functions

function [ newwave fracbad ] = ...
  helper_iterate_artifacts( artparams, oldwave, samprate )

  % Keep NaNs (don't interpolate), and don't re-reference.
  keepnan = true;
  [ newwave fracbad ] = nlChan_applyArtifactReject( ...
    oldwave, [], samprate, artparams, keepnan );

end



%
% This is the end of the file.
