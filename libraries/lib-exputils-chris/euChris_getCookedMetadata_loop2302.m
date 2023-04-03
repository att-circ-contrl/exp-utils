function cookedmeta = euChris_getCookedMetadata_loop2302( rawmeta, hintdata )

% function cookedmeta = euChris_getCookedMetadata_loop2302( rawmeta, hintdata )
%
% This function accepts raw configuration metadata for a "loop2302"
% experiment and produces derived (cooked) metadata.
%
% "rawmeta" is a metadata structure for the Open Ephys v5 folder
%   associated with the experiment, per RAWFOLDERMETA.txt.
% "hintdata" is a structure containing hints for processing metadata. This
%   may be a structure with no fields or an empty structure array.
%
% "cookedmeta" is a metadata structure containing derived configuration
% information, per CHRISEXPMETA.txt.


cookedmeta = struct();

% Regularize the hint data.
if isempty(hintdata)
  hintdata = struct();
end


% Initialize.

rawchans = {};
cookedchans = {};

samprate = NaN;
ardinbit = NaN;

torteband = [];
torteinchans = [];
tortemode = '';

crossmagchan = NaN;
crossphasechan = NaN;
crossrandchan = NaN;

crossmagthresh = NaN;
crossmagtau = NaN;
crossphaseval = NaN;

crossmagbit = NaN;
crossphasebit = NaN;
crossrandbit = NaN;

crossmagbank = NaN;
crossphasebank = NaN;
crossrandbank = NaN;

trigphasebit = NaN;
trigrandbit = NaN;
trigmagbit = NaN;
trignowbit = NaN;

trigbank = NaN;

randwasjitter = false;

filewritenodes = [];
filewritechanmasks = {};



% Get the signal chain and channel map.
% The signal chain should exist. The channel map may be empty.

sigchain = rawmeta.oesigchain;

chanmap_raw = rawmeta.chanmap_raw;
chanmap_cooked = rawmeta.chanmap_cooked;


% Walk through the processing nodes, gathering selected metadata.
% NOTE - We're making assumptions about what's in the chain. That's the
% point of the 'loop2302' label.


% First pass: Everything except the conditional trigger.
% We need to guarantee that we have the crossing detector output bits first.

for pidx = 1:length(sigchain)
  thisproc = sigchain{pidx};

  if strcmp(thisproc.procname, 'Intan Rec. Controller')

    % Save the raw channel names and sampling rate.
    % FIXME - These channel labels won't match the ones in FT's list!
    rawchans = thisproc.chanlabels;
    samprate = thisproc.samprate;

  elseif strcmp(thisproc.procname, 'File Reader')

    % We don't have useful information about the input channels from the
    % node metadata.

    % FIXME - Copy it from the Field Trip metadata.
    % This is a kludge! It tells us what we _saved_, not what we _read_.
    samprate = rawmeta.header_ft.Fs;
    rawchans = rawmeta.header_ft.label;
    mincount = min(length(rawchans), thisproc.chancount);
    rawchans = rawchans(1:mincount);

  elseif strcmp(thisproc.procname, 'Record Node')

    % Save the node ID (for checking folder names) and the channel mask.
    filewritecount = length(filewritenodes) + 1;
    filewritenodes(filewritecount) = thisproc.procnode;
    filewritechanmasks{filewritecount} = thisproc.savedchans;

  elseif strcmp(thisproc.procname, 'Arduino Output')

    % Blithely assume that we're reading from the conditional trigger.
    % This is 0-based.
    ardinbit = thisproc.inputbit;

  elseif strcmp(thisproc.procname, 'Phase Calculator')

    % Check that we're set up for mag-plus-phase and record the band.
    % Also record what our input channel is (one or more, anyways).
    torteband = thisproc.bandcorners;
    tortemode = thisproc.outputmode;
    torteinchans = find(thisproc.channelselect);

  elseif strcmp(thisproc.procname, 'Crossing Detector')

    % Figure out which detector this is and store its metadata.
    if strcmp(thisproc.threshtype, 'constant')
      % Phase threshold.
      crossphasechan = thisproc.inputchan;
      crossphaseval = thisproc.threshold;
      crossphasebit = thisproc.outputTTLchan;
      % Convert to 0-based.
      crossphasebank = thisproc.eventbanks - 1;
    elseif strcmp(thisproc.threshtype, 'random')
      % Randomly-drawn phase.
      crossrandchan = thisproc.inputchan;
      crossrandbit = thisproc.outputTTLchan;
      % Convert to 0-based.
      crossrandbank = thisproc.eventbanks - 1;
    elseif strcmp(thisproc.threshtype, 'averagemult')
      % Magnitude threshold.
      crossmagchan = thisproc.inputchan;
      crossmagthresh = thisproc.threshold;
      crossmagtau = thisproc.averageseconds;
      crossmagbit = thisproc.outputTTLchan;
      % Convert to 0-based.
      crossmagbank = thisproc.eventbanks - 1;
    end

  end
end

% Second pass: Conditional trigger, now that we know what its inputs are.

for pidx = 1:length(sigchain)
  thisproc = sigchain{pidx};

  if strcmp(thisproc.procname, 'TTL Cond Trigger')

    % Convert to 0-based.
    trigbank = thisproc.eventbanks - 1;

    % Walk through the outputs, figuring out what they are.
    for outidx = 1:length(thisproc.outconditions)

      thisout = thisproc.outconditions{outidx};

      had_mag = false;
      had_phase = false;
      had_rand = false;
      had_other = false;

      for inidx = 1:length(thisout.inconditions)
        thisin = thisout.inconditions{inidx};
        % FIXME - Kludge based on knowing that we assigned unique bit
        % indices to the different crossing detectors.
        thisbit = thisin.digbit;
        if thisin.enabled
          if thisbit == crossmagbit
            had_mag = true;
          elseif thisbit == crossphasebit
            had_phase = true;
          elseif thisbit == crossrandbit
            had_rand = true;
          else
            had_other = true;
          end
        end
      end

      had_jitter = false;
      if thisout.delaymaxsamps ~= thisout.delayminsamps
        had_jitter = true;
      end

      % Remember that our iterating index is 1-based but bits are 0-based.

      if had_mag
        if had_phase
          if had_jitter
            % Random phase by adding jitter to a fixed phase.
            trigrandbit = outidx - 1;
            randwasjitter = true;
          else
            % Fixed phase.
            trigphasebit = outidx - 1;
          end
        elseif had_rand
          % Uniformly sampled random phase.
          trigrandbit = outidx - 1;
        else
          % Magnitude alone.
          trigmagbit = outidx - 1;
        end
      elseif had_other
        % Triggering on RwdB only.
        trignowbit = outidx - 1;
      end

    end

  end
end


% Get the cooked channel list, if we can.
% This falls back to reasonable defaults.

cookedchans = rawchans;
if (~isempty(chanmap_raw)) && (~isempty(chanmap_cooked))
  cookedchans = ...
    nlFT_mapChannelLabels( rawchans, chanmap_raw, chanmap_cooked );
end



% Store what we found.

cookedmeta.samprate = samprate;

cookedmeta.rawchans = rawchans;
cookedmeta.cookedchans = cookedchans;

cookedmeta.torteband = torteband;
cookedmeta.tortemode = tortemode;
cookedmeta.torteinchans = torteinchans;

cookedmeta.crossmagchan = crossmagchan;
cookedmeta.crossmagthresh = crossmagthresh;
cookedmeta.crossmagtau = crossmagtau;
cookedmeta.crossmagbank = crossmagbank;
cookedmeta.crossmagbit = crossmagbit;

cookedmeta.crossphasechan = crossphasechan;
cookedmeta.crossphaseval = crossphaseval;
cookedmeta.crossphasebank = crossphasebank;
cookedmeta.crossphasebit = crossphasebit;

cookedmeta.crossrandchan = crossrandchan;
cookedmeta.crossrandbank = crossrandbank;
cookedmeta.crossrandbit = crossrandbit;

cookedmeta.randwasjitter = randwasjitter;

cookedmeta.trigbank = trigbank;
cookedmeta.trigphasebit = trigphasebit;
cookedmeta.trigrandbit = trigrandbit;
cookedmeta.trigmagbit = trigmagbit;
cookedmeta.trignowbit = trignowbit;

cookedmeta.ardinbit = ardinbit;

cookedmeta.filewritenodes = filewritenodes;
cookedmeta.filewritechanmasks = filewritechanmasks;


% Done.

end


%
% This is the end of the file.