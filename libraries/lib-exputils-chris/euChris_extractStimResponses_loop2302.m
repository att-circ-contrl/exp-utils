function responsedata = euChris_extractStimResponses_loop2302( ...
  expmeta, signalconfig, trigtimes, trig_window_ms, train_gap_ms, ...
  chans_wanted, want_lfp, want_narrowband, verbosity )

% function responsedata = euChris_extractStimResponses_loop2302( ...
%   expmeta, signalconfig, trigtimes, trig_window_ms, train_gap_ms, ...
%   chans_wanted, want_lfp, want_narrowband, verbosity )
%
% This function reads ephys data in segments centered around stimulation
% events.
%
% This function works with 'loop2302' type experiments.
%
% Wideband data has artifact regions replaced with NaN. Broad-band LFP and
% narrow-band LFP have smoothed replacement segments in these regions.
%
% "expmeta" is one of the metadata structures returned by
%   euChris_getChrisMetadata(), with the fields described in CHRISEXPMETA.txt
%   (including the "casemeta" additional field).
% "signalconfig" is a structure with fields noted in SIGNALCONFIG.txt,
%   including the following:
%   - Notch filtering configuration.
%   - LFP band configuration.
%   - Artifact suppression settings.
% "trigtimes" is a vector containing trigger timestamps in seconds. If this
%   is [], the trials' t=0 times are used.
% "trig_window_ms" [ start stop ] is the window around stimulation events
%   to save, in milliseconds. E.g. [ -100 300 ].
% "train_gap_ms" is a duration in milliseconds. Stimulation events with this
%   separation or less are considered to be part of a pulse train.
% "chans_wanted" is either a character array or a cell array, per
%   CHRISBATCHDEFS.txt. If it's a character array, it's 'trig' to read the
%   trigger channel, 'hint' to read the hint channels (if any; trigger
%   channel if not), and 'all' to read all ephys channels. If it's a cell
%   array, it's treated as a list of FT channels to read.
% "want_lfp" is true if the broad-band LFP is to be extracted.
% "want_narrowband" is true if the narrow-band LFP is to be extracted.
% "verbosity" is 'normal' or 'quiet'.
%
% "responsedata" is a structure containing the following fields, per
%   CHRISSTIMRESPONSE.txt:
%
%   "ftdata_wb" is a Field Trip data structure containing the wideband data
%     after artifact rejection and notch filtering. This contains NaN spans.
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
%   "trainrevpos" is a vector with one entry per trial, holding the relative
%    position of each trial with respect to the _end_ of its event train
%    (1 for the last event of a train, 2 for the second-last, and so forth).


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


% Get artifact configuration information.
[ artmethod artconfig ] = ...
  euChris_getArtifactConfigFromSignalConfig( signalconfig );



% Get the trial definitions.

samprate = wbheader.Fs;
trialdefs = euFT_getTrainTrialDefs( samprate, wbheader.nSamples, ...
  trigtimes, trig_window_ms, train_gap_ms );
trainpos = trialdefs(:,4);

% Figure out where elements are relative to the end of each train.

lastpos = -inf;
laststart = NaN;
trainrevpos = ones(size(trainpos));

for tidx = length(trainpos):-1:1
  thispos = trainpos(tidx);
  if thispos >= lastpos
    laststart = thispos;
  end
  lastpos = thispos;

  trainrevpos(tidx) = 1 + laststart - thispos;
end


% Get the desired channels.

% The trigger channel is in "wbchan".
% The hint channels are in "wbextrachans".
% The full channel list is in "wballchans".
% NOTE - Remember that "wbchan" is _not_ a cell array. The others are.

desiredchans = { wbchan };

if iscell(chans_wanted)
  if ~isempty(chans_wanted)
    desiredchans = chans_wanted;
  end
elseif ischar(chans_wanted)
  if strcmp(chans_wanted, 'trig')
    desiredchans = { wbchan };
  elseif strcmp(chans_wanted, 'hint') && (~isempty(wbextrachans))
    desiredchans = wbextrachans;
  elseif strcmp(chans_wanted, 'all') && (~isempty(wballchans))
    desiredchans = wballchans;
  end
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


%
% Read the trials and do any desired filtering.

% FIXME - Consider supporting MUA and HPF filters too.
% FIXME - Consider doing most of this through getDerivedSignals().

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
    'trainpos', trainpos, 'trainrevpos', trainrevpos );


  % Read wideband.
  % Artifacts are squashed, leaving NaN gaps.

  if want_banners
    disp('.. Loading event trials.');
  end

% FIXME - Add squash config here.
  ftdata_wb = euHLev_readAndCleanSignals( wbfolder, desiredchans, ...
    trialdefs, artmethod, artconfig, struct([]), ...
    signalconfig.notch_freqs, signalconfig.notch_bandwidth );


  % Pave over NaN segments but remember where they were.

  nanmask = nlFT_getNaNMask(ftdata_wb);
  ftdata_wb = nlFT_fillNaN(ftdata_wb);


  % Get broad-band LFP, if requested.

  if want_lfp
    % Don't actually remove DC; FT's low-frequency filtering is iffy.
    config_lfp = struct( 'lpfilter', 'yes', 'lpfilttype', 'but', ...
      'lpfreq', max(signalconfig.lfp_band), 'feedback', 'no' );

    ftdata_lfp = ft_preprocessing(config_lfp, ftdata_wb);

    % NOTE - Keeping the filtered interpolated version.
    % The caller can squash NaN regions if they really want to.

    responsedata.ftdata_lfp = ftdata_lfp;
  end


  % Get narrow-band LFP, if requested.

  if want_narrowband
    torteband = cookedmeta.torteband;
    config_band = struct( 'bpfilter', 'yes', 'bpfilttype', 'but', ...
      'bpinstabilityfix', 'split', 'feedback', 'no', ...
      'bpfreq', [ min(torteband), max(torteband) ] );

    ftdata_band = ft_preprocessing(config_band, ftdata_wb);

    % NOTE - Keeping the filtered interpolated version.
    % The caller can squash NaN regions if they really want to.

    responsedata.ftdata_band = ftdata_band;
  end


  % Now that we've finished filtering, re-squash the NaN regions in
  % the wideband signal and store it.

  ftdata_wb = nlFT_applyNaNMask(ftdata_wb, nanmask);
  responsedata.ftdata_wb = ftdata_wb;



  % Finished reading.

  if want_banners
    disp('.. Finished loading event trials.');
  end

end



% Done.
end



%
% This is the end of the file.
