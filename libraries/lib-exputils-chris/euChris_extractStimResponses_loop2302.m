function responsedata = euChris_extractStimResponses_loop2302( ...
  expmeta, signalconfig, trigtimes, trig_window_ms, train_gap_ms, ...
  want_all, want_lfp, want_narrowband, verbosity )

% function responsedata = euChris_extractStimResponses_loop2302( ...
%   expmeta, signalconfig, trigtimes, trig_window_ms, train_gap_ms, ...
%   want_all, want_lfp, want_narrowband, verbosity )
%
% This function reads ephys data in segments centered around stimulation
% events.
%
% This function works with 'loop2302' type experiments.
%
% "expmeta" is one of the metadata structures returned by
%   euChris_getChrisMetadata(), with the fields described in CHRISEXPMETA.txt
%   (including the "casemeta" additional field).
% "signalconfig" is a structure with the following fields, per
%   SIGNALCONFIG.txt:
%   "notch_freqs" is a vector of frequencies to notch filter (may be empty).
%   "notch_bandwidth" is the bandwidth of the notch filter.
%   "lfp_band" [ min max ] is the broad-band LFP frequency range.
%   "event_squash_type" is the stimulation artifact rejection method. Known
%     methods: 'none', 'nan'
%   "event_squash_window_ms" [ start stop ] is the window around stimulation
%     events to filter for artifacts, in milliseconds. E.g. [ -0.5 1.5 ].
% "trigtimes" is a vector containing trigger timestamps in seconds.
% "trig_window_ms" [ start stop ] is the window around stimulation events
%   to save, in milliseconds. E.g. [ -100 300 ].
% "train_gap_ms" is a duration in milliseconds. Stimulation events with this
%   separation or less are considered to be part of a pulse train.
% "want_all" is true if all channels are to be read, false if only hint and
%   experiment-specified channels are to be read.
% "want_lfp" is true if the broad-band LFP is to be extracted.
% "want_narrowband" is true if the narrow-band LFP is to be extracted.
% "verbosity" is 'normal' or 'quiet'.
%
% "responsedata" is a structure containing the following fields, per
%   CHRISSTIMRESPONSE.txt:
%
%   "ftdata_raw" is a Field Trip data structure containing the wideband data
%     before artifact rejection and notch filtering.
%   "ftdata_wb" is a Field Trip data structure containing the wideband data
%     after artifact rejection and notch filtering.
%   "ftdata_lfp" is a Field Trip data structure with the broad-band LFP data.
%     This is only present if "want_lfp" was true.
%   "ftdata_band" is a Field Trip data structure with the narrow-band LFP
%     data. This is only present if "want_narrowband" was true.
%
%   "tortecidx" is the index of the TORTE input channel in ftdata_XXX.
%   "extracidx" is a vector with indices of hint channels in ftdata_XXX.
%
%   "trainpos" is a vector with one entry per trial, holding the relative
%     position of each trial in an event train (1 for the first event of
%     a train, 2 for the next, and so forth).


responsedata = struct([]);

want_banners = ~strcmp(verbosity, 'quiet');


% Get metadata.

expconfig = expmeta.expconfig;
cookedmeta = expmeta.cookedmeta;
hintdata = expmeta.casemeta.hint;

wbfolder = expconfig.file_path_first;
wbchan = expconfig.chan_wb_ftlabel;

wbextrachans = {};
if isfield(hintdata, 'extrachans')
  wbextrachans = hintdata.extrachans;
end

% Get the raw metadata structure for the wideband folder.
% This gives us the FT header and the analog channel list.
rawmeta = struct([]);
rawmetalist = expmeta.rawmetalist;
for fidx = 1:length(rawmetalist)
  thisfolder = rawmetalist{fidx}.folder;
  if strcmp(thisfolder, wbfolder)
    rawmeta = rawmetalist{fidx};
  end
end

if isempty(rawmeta)
  % Bail out here.
  error('### [euChris_extractStimResponses_loop2302]  Can''t find folder!');
end

wbheader = rawmeta.header_ft;
wballchans = rawmeta.chans_an;

squash_type = 'none';
squash_window_ms = [ -1 2 ];
if isfield(signalconfig, 'event_squash_type')
  squash_type = signalconfig.event_squash_type;
end
if isfield(signalconfig, 'event_squash_window_ms')
  squash_window_ms = signalconfig.event_squash_window_ms;
end



% Get the trial definitions.

samprate = wbheader.Fs;
trialdefs = euFT_getTrainTrialDefs( samprate, wbheader.nSamples, ...
  trigtimes, trig_window_ms, train_gap_ms );
trainpos = trialdefs(4,:);


% Get the desired channels.

desiredchans = [ { wbchan } wbextrachans ];
if want_all
  desiredchans = wballchans;
end
desiredchans = unique(desiredchans);

desiredchans = ft_channelselection( desiredchans, wbheader.label, {} );


% Store channel metadata here too.

tortecidx = find(strcmp( wbchan, wbheader.label ));
if isempty(tortecidx)
  tortecidx = NaN;
else
  tortecidx = tortecidx(1);
end

extracidx = [];
for cidx = 1:length(wbextrachans)
  thisidx = find(strcmp( wbextrachans{cidx}, wbheader.label ));

  if isempty(thisidx)
    thisidx = NaN;
  else
    thisidx = thisidx(1);
  end

  extracidx(cidx) = thisidx;
end


% Read the trials and do any desired filtering.

% FIXME - We should make a helper for reading stim trials and removing
% stimulation artifacts from the "time = 0" point.
% FIXME - Maybe support getting MUA too? Or HPF? Call getDerivedSignals?
% We have a batched version of that too.


if want_banners
  if isempty(desiredchans)
    disp('.. [euChris_extractStimResponses_loop2302]  No channels requested.');
  end
  if isempty(trialdefs)
    disp('.. [euChris_extractStimResponses_loop2302]  No trials defined.');
  end
end


if (~isempty(desiredchans)) && (~isempty(trialdefs))

  % Initialize the return structure.

  responsedata = struct( 'tortecidx', tortecidx, 'extracidx', extracidx, ...
    'trainpos', trainpos );


  % Read wideband.

  if want_banners
    disp('.. Loading event trials.');
  end

  config_load = struct( ...
    'headerfile', wbfolder, 'headerformat', 'nlFT_readHeader', ...
    'datafile', wbfolder, 'dataformat', 'nlFT_readDataDouble', ...
    'trl', trialdefs, ...
    'detrend', 'no', 'demean', 'no', 'feedback', 'no' );
  config_load.channel = desiredchans;

  ftdata_raw = ft_preprocessing( config_load );

  if want_banners
    disp('.. Performing signal conditioning on event trials.');
  end


  ftdata_wb = ftdata_raw;
  trialmasks = {};

  if strcmp(squash_type, 'nan')
    % NaN out everything in the artifact rejection window.
    % FIXME - Since we need to do filtering after this, interpolate the gaps.

    trialmasks = nlFT_getWindowsAroundEvents(ftdata_wb, squash_window_ms);
    ftdata_wb = helper_squashEvents(ftdata_wb, trialmasks, true);
  else
    % No artifact rejection. Wideband stays a copy of raw.
  end

  % FIXME - Consider NaNing out anything past adjacent events.


  if (~isempty(signalconfig.notch_freqs)) ...
    && (~isnan(signalconfig.notch_bandwidth))
    ftdata_wb = euFT_doBrickNotchRemoval( ...
      ftdata_wb, signalconfig.notch_freqs, signalconfig.notch_bandwidth );
  end

  % NOTE - Defer re-squashing and storing wideband until we have any
  % derived signals we wanted.


  % Get broad-band LFP, if requested.

  if want_lfp
    % Don't actually remove DC; FT's low-frequency filtering is iffy.
    config_lfp = struct( 'lpfilter', 'yes', 'lpfilttype', 'but', ...
      'lpfreq', max(signalconfig.lfp_band), 'feedback', 'no' );

    ftdata_lfp = ft_preprocessing(config_lfp, ftdata_wb);

    % Squash artifact regions in the filtered waveform.
    if strcmp(squash_type, 'nan')
      ftdata_lfp = helper_squashEvents(ftdata_lfp, trialmasks, false);
    end

    responsedata.ftdata_lfp = ftdata_lfp;
  end


  % Get narrow-band LFP, if requested.

  if want_narrowband
    torteband = cookedmeta.torteband;
    config_band = struct( 'bpfilter', 'yes', 'bpfilttype', 'but', ...
      'bpinstabilityfix', 'split', 'feedback', 'no', ...
      'bpfreq', [ min(torteband), max(torteband) ] );

    ftdata_band = ft_preprocessing(config_band, ftdata_wb);

    % Squash artifact regions in the filtered waveform.
    if strcmp(squash_type, 'nan')
      ftdata_band = helper_squashEvents(ftdata_band, trialmasks, false);
    end

    responsedata.ftdata_band = ftdata_band;
  end


  % Now that we've finished filtering, re-squash the artifact regions in
  % the wideband signal and store it.
  if strcmp(squash_type, 'nan')
    ftdata_wb = helper_squashEvents(ftdata_wb, trialmasks, false);
  end

  responsedata.ftdata_wb = ftdata_wb;



  % Finished reading.

  if want_banners
    disp('.. Finished loading event trials.');
  end

end



% Done.
end



%
% Helper functions.

function newftdata = helper_squashEvents(oldftdata, trialmasks, wantinterp)

  trialcount = length(trialmasks);
  chancount = length(oldftdata.label);

  newftdata = oldftdata;

  for tidx = 1:trialcount
    thistrial = newftdata.trial{tidx};
    thismask = trialmasks{tidx};
    thistrial(:,thismask) = NaN;

    % Pave over the NaN portion, if desired.
    if wantinterp
      for cidx = 1:chancount
        thiswave = thistrial(cidx,:);
        thistrial(cidx,:) = nlProc_fillNaN(thiswave);
      end
    end

    newftdata.trial{tidx} = thistrial;
  end
end


%
% This is the end of the file.
