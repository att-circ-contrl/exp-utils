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
torteextrachan = NaN;
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
filewritehasevents = logical([]);



% Get the signal chain and channel map.
% The signal chain should exist. The channel map may be empty.

sigchain = rawmeta.oesigchain;

ft_chanmap_raw = rawmeta.chanmap_raw;
ft_chanmap_cooked = rawmeta.chanmap_cooked;

oe_chanmap_oldchans = [];


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

    % NOTE - We can't copy FT metadata, since that's what the _wrote_, not
    % what we read.

    % FIXME - Make up channel names based on the channel count.
    % Use the same conventions as Open Ephys's Intan recorder node
    % (CHn, starting with n=1).
    rawchans = {};
    for cidx = 1:thisproc.chancount
      rawchans{cidx} = sprintf('CH%d', cidx);
    end

    % FIXME - Take the sampling rate from FT metadata, since we have no
    % other choice.
    % This is a kludge! It tells us what we _saved_, not what we _read_.
    samprate = rawmeta.header_ft.Fs;

  elseif strcmp(thisproc.procname, 'Channel Map')

    % Open Ephys channel map. This will match the channel list extracted
    % from the signal chain.
    oe_chanmap_oldchans = thisproc.chanmap.oldchan;
    if ~isrow(oe_chanmap_oldchans)
      oe_chanmap_oldchans = transpose(oe_chanmap_oldchans);
    end

  elseif strcmp(thisproc.procname, 'Record Node')

    % Save the node ID (for checking folder names) and the channel mask.
    filewritecount = length(filewritenodes) + 1;
    filewritenodes(filewritecount) = thisproc.procnode;
    filewritechanmasks{filewritecount} = thisproc.savedchans;
    filewritehasevents(filewritecount) = thisproc.wantevents;

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

    % Figure out what the new (magnitude) channel number is.
    % It's the one that we added to the end of the channel list.
    % NOTE - This is 1-based.
    torteextrachan = length(thisproc.channelselect);

  elseif strcmp(thisproc.procname, 'Crossing Detector')

    % Figure out which detector this is and store its metadata.
    if strcmp(thisproc.threshtype, 'constant')
      % Phase threshold.
      crossphasechan = thisproc.inputchan;
      crossphaseval = thisproc.threshold;
      % Convert to 0-based.
      crossphasebit = thisproc.outputTTLchan - 1;
      % FIXME - Empirical bank ID count. May break on other chains!
      crossphasebank = thisproc.eventbanks - 2;
    elseif strcmp(thisproc.threshtype, 'random')
      % Randomly-drawn phase.
      crossrandchan = thisproc.inputchan;
      % Convert to 0-based.
      crossrandbit = thisproc.outputTTLchan - 1;
      % FIXME - Empirical bank ID count. May break on other chains!
      crossrandbank = thisproc.eventbanks - 2;
    elseif strcmp(thisproc.threshtype, 'averagemult')
      % Magnitude threshold.
      crossmagchan = thisproc.inputchan;
      crossmagthresh = thisproc.threshold;
      crossmagtau = thisproc.averageseconds;
      % Convert to 0-based.
      crossmagbit = thisproc.outputTTLchan - 1;
      % FIXME - Empirical bank ID count. May break on other chains!
      crossmagbank = thisproc.eventbanks - 2;
    end

  end
end

% Second pass: Conditional trigger, now that we know what its inputs are.

for pidx = 1:length(sigchain)
  thisproc = sigchain{pidx};

  if strcmp(thisproc.procname, 'TTL Cond Trigger')

    % Convert to 0-based.
    % FIXME - Empirical bank ID count. May break on other chains!
    trigbank = thisproc.eventbanks - 2;

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
if ~isempty(oe_chanmap_oldchans)
  cookedchans = rawchans(oe_chanmap_oldchans);
elseif (~isempty(ft_chanmap_raw)) && (~isempty(ft_chanmap_cooked))
  cookedchans = ...
    nlFT_mapChannelLabels( rawchans, ft_chanmap_raw, ft_chanmap_cooked );
end



% Store what we found.

cookedmeta.samprate = samprate;

cookedmeta.rawchans = rawchans;
cookedmeta.cookedchans = cookedchans;

cookedmeta.chanmapoldnums = oe_chanmap_oldchans;
cookedmeta.chanmapftraw = ft_chanmap_raw;
cookedmeta.chanmapftcooked = ft_chanmap_cooked;

cookedmeta.torteband = torteband;
cookedmeta.tortemode = tortemode;
cookedmeta.torteinchans = torteinchans;
cookedmeta.torteextrachan = torteextrachan;

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
cookedmeta.filewritehasevents = filewritehasevents;


% Done.

end


%
% This is the end of the file.
