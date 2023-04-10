function ftdata_ephys = euHLev_readAndCleanSignals( folder, ephys_chans, ...
  trim_fraction, artifact_level, notch_freqs, notch_bw )

% function ftdata_ephys = euHLev_readAndCleanSignals( folder, ephys_chans, ...
%   trim_fraction, artifact_level, notch_freqs, notch_bw )
%
% This reads Field Trip trial data from the specified folder, performing
% notch filtering and artifact rejection.
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
% "trim_fraction" (in the range 0 to 0.5) is the amount of time to trim from
%   the start and end of the ephys data as a fraction of the untrimmed length.
% "artifact_level" (-2..+2) is a tuning adjustment for artifact rejection;
%   positive values make it less sensitive. NaN disables artifact rejection.
% "notch_freqs" is a vector containing notch filter frequencies. An empty
%   vector disables notch filtering.
% "notch_bw" is the notch filter bandwidth in Hz. NaN disables filtering.
%
% "ftdata_ephys" is a Field Trip data structure containing ephys data for
%   the specified ephys channels. NOTE - This will be an empty struct array
%   if there were no ephys channels specified or no matching channels found.


ftdata_ephys = struct([]);


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

    [ sampfirst samplast ] = ...
      nlUtil_getTrimmedSampleSpan( header.nSamples, trim_fraction );
    trialdef = [ sampfirst, samplast, (sampfirst - 1) ];

    config_load = struct( ...
      'headerfile', folder, 'headerformat', 'nlFT_readHeader', ...
      'datafile', folder, 'dataformat', 'nlFT_readDataDouble', ...
      'trl', trialdef, ...
      'detrend', 'no', 'demean', 'no', 'feedback', 'no' );
    config_load.channel = chans_wanted;

    ftdata_ephys = ft_preprocessing( config_load );


    % Perform artifact removal first, so that artifacts don't cause ringing.

    if ~isnan(artifact_level)
      artparams = nlChan_getArtifactDefaults();
      artparams.ampthresh = artparams.ampthresh + artifact_level;
      artparams.diffthresh = artparams.diffthresh + artifact_level;

      iterfunc_art = ...
        @( wavedata, timedata, samprate, trialidx, chanidx, chanlabel ) ...
          helper_iterate_artifacts( artparams, wavedata, samprate );

      [ newtrials fracbad ] = ...
        nlFT_iterateAcrossData( ftdata_ephys, iterfunc_art );
      ftdata_ephys.trial = newtrials;
    end


    % Perform notch filtering second.

    if (~isempty(notch_freqs)) && (~isnan(notch_bw))
      ftdata_ephys = ...
        euFT_doBrickNotchRemoval( ftdata_ephys, notch_freqs, notch_bw );
    end

  end

end


% Done.
end



%
% Helper Functions

function [ newwave fracbad ] = ...
  helper_iterate_artifacts( artparams, oldwave, samprate )

  % Don't keep NaNs (interpolate instead), and don't re-reference.
  [ newwave fracbad ] = nlChan_applyArtifactReject( ...
    oldwave, [], samprate, artparams, false );

end



%
% This is the end of the file.
