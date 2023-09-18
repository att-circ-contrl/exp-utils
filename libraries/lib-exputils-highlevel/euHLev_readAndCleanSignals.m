function ftdata_ephys = euHLev_readAndCleanSignals( folder, ephys_chans, ...
  trial_config, artifact_method, artifact_config, squash_config, ...
  notch_freqs, notch_bw )

% function ftdata_ephys = euHLev_readAndCleanSignals( folder, ephys_chans, ...
%   trial_config, artifact_method, artifact_config, squash_config, ...
%   notch_freqs, notch_bw )
%
% This reads Field Trip trial data from the specified folder, performing
% artifact rejection, NaN squashing/paving, and notch filtering in that order.
%
% This can be used to read continuous data or event-segmented data, depending
% on what's passed as "trial_config".
%
% NOTE - Channel names specified as '' are skipped (removed from the list
% before calling FT's read functions).
%
% NOTE - For large datasets, call euFT_iterateAcrossFolderBatchingDerived
% instead. This is intended for quick and dirty processing of datasets that
% fit in memory.
%
% NOTE - This does _not_ detrend or demean data, so it's safe for reading
% magnitudes, phase angles, event codes, and so forth.
%
% NOTE - Events and waveforms have timestamps relative to the start of the
% recording (or to the trial's t=0 point), not the start of the trim window.
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
% "artifact_method" is an artifact rejection method, per ARTIFACTCONFIG.txt.
%  This can be '' or 'none' to disable artifact rejection.
% "artifact_config" is a structure containing configuration information for
%   the chosen artifact rejection method, per ARTIFACTCONFIG.txt. This may
%   be struct() or struct([]) if no method is used.
% "squash_config" is a structure describing artifact squashing, step
%   correction, and interpolation to be performed, per SQUASHCONFIG.txt.
%   This may be struct() or struct([]) if none of these are to be done.
% "notch_freqs" is a vector containing notch filter frequencies. An empty
%   vector disables notch filtering.
% "notch_bw" is the notch filter bandwidth in Hz. NaN disables filtering.
%
% "ftdata_ephys" is a Field Trip data structure containing ephys data for
%   the specified ephys channels. NOTE - This will be an empty struct array
%   if there were no ephys channels specified or no matching channels found.


ftdata_ephys = struct([]);


% Set input structure defaults.

if isempty(trial_config)
  trial_config = 0;
end

if isempty(artifact_config)
  artifact_config = struct();
end

if isempty(squash_config)
  squash_config = struct();
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
    % This may leave NaN holes.


    % Artifact removal based on excursions in the absolute value of the
    % signal or of its derivative.

    if strcmp(artifact_method, 'sigma')
      artparams = euHLev_getArtifactSigmaDefaults();

      thresh_adjust = artifact_config.threshold_adjust;

      ftdata_ephys = nlFT_removeArtifactsSigma( ftdata_ephys, ...
        artparams.ampdetect + thresh_adjust, ...
        artparams.derivdetect + thresh_adjust, ...
        artparams.ampturnoff, artparams.derivturnoff, ...
        artparams.squashbefore, artparams.squashafter, ...
        artparams.derivsmooth, artparams.dcsmooth );
    end


    % Curve-fitting stimulation artifacts at known locations.
    % NOTE - Locations are specified relative to t=0.

    if strcmp(artifact_method, 'expknown')

      fit_method = '';
      if isfield(artifact_config, 'fit_method')
        fit_method = artifact_config.fit_method;
      end

      [ ftdata_ephys fitlist ] = nlFT_removeMultipleExpDecays( ...
        ftdata_ephys, artifact_config.fit_fenceposts_ms / 1000, ...
        fit_method );
    end


    % Curve-fitting stimulation artifacts, using black magic to guess at
    % curve fit locations.

    if strcmp(artifact_method, 'expguess')

      % This is augmented with verbosity and "want_xx" flags.
      plotconfig = artifact_config.plot_config;

      fitparams = nlFT_guessMultipleExpDecays( ...
        ftdata_ephys, artifact_config, ...
        plotconfig.want_debug_plots, plotconfig.want_reports, ...
        plotconfig, ...
        plotconfig.tattle_verbosity, plotconfig.report_verbosity );

      % Subtract curve fits from t=0 onward, ignoring the DC offsets.
      ftdata_ephys = nlFT_subtractCurveFits( ...
        ftdata_ephys, [ 0 inf ], fitparams, 'ignoredc' );

    end


    %
    % Apply any desired additional NaN-squashing, step/ramp adjustment,
    % and NaN interpolation.

    % NOTE - Move NaN interpolation after filtering, so we can identify
    % discontinuities across NaN spans.

    want_fillnan = false;
    if ~isempty(squash_config)
      if isfield(squash_config, 'want_interp')
        want_fillnan = squash_config.want_interp;
        squash_config.want_interp = false;
      end

      ftdata_ephys = euHLev_doSquashAndFill( ftdata_ephys, squash_config );
    end


    %
    % Perform notch filtering last.

    if (~isempty(notch_freqs)) && (~isnan(notch_bw))

      % Interpolate NaNs, filter, and then restore NaNs.
      % If desired, also detrend every non-NaN segment.

      wantramp = false;
      if ~isempty(squash_config)
        wantramp = isfield(squash_config, 'ramp_endpoint_frac');
      end

      if wantramp
        thisramp = nlFT_getEndpointRamps( ...
          ftdata_ephys, squash_config.ramp_endpoint_frac );
        ftdata_ephys.trial = nlFT_sumTrialArrays( ...
          ftdata_ephys.trial, 1, thisramp, -1 );
      end

      thismask = nlFT_getNaNMask(ftdata_ephys);
      ftdata_ephys = nlFT_fillNaN(ftdata_ephys);

      ftdata_ephys = ...
        euFT_doBrickNotchRemoval( ftdata_ephys, notch_freqs, notch_bw );

      ftdata_ephys = nlFT_applyNaNMask(ftdata_ephys, thismask);

      if wantramp
        ftdata_ephys.trial = nlFT_sumTrialArrays( ...
          ftdata_ephys.trial, 1, thisramp, 1 );
      end

    end

    % Now that we've done notch filtering, apply interpolation if desired.
    if want_fillnan
      ftdata_ephys = nlFT_fillNaN(ftdata_ephys);
    end

  end

end


% Done.
end



%
% This is the end of the file.
