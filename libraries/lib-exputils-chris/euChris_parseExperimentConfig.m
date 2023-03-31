function [ expmeta errmsgs ] = ...
  euChris_parseExperimentConfig( rawmetalist, exptype, hintdata )

% function [ expmeta errmsgs ] = ...
%   euChris_parseExperimentConfig( rawmetalist, exptype, hintdata )
%
% This is a top-level entry point for parsing configuration data for
% one of Chris's experiment runs.
%
% "rawmetalist" is a cell array containing metadata structures returned by
%   euHLev_getAllMetadata_XXX, per RAWFOLDERMETA.txt.
% "exptype" is a label defining the type of dataset being processed.
%   E.g.: 'loop2302'
% "hintdata" is a structure containing hints for processing metadata. This
%   may be a structure with no fields or an empty structure array.
%
% "expmeta" is a structure containing aggregated metadata for this run.
%   This is an empty structure if the run metadata couldn't be parsed.
%   Detailed contents are per "CHRISEXPMETA.txt".
% "errmsgs" is a cell array containing warning messages and error messages
%   generated while parsing.


isok = true;

diagmsgs = {};
errmsgs = {};
expsummary = '-bogus-';
expdetails = '-bogus-';

% Regularlize the hint data. If an empty array was provided, make a struct
% with no fields instead.
if isempty(hintdata)
  hintdata = struct();
end

% Initialize the metadata structure. We'll either add to it or clear it.
expmeta = struct();
expmeta.('rawmetalist') = rawmetalist;
expmeta.('exptype') = exptype;
expmeta.('hintdata') = hintdata;



%
% Extract raw metadata.

rawmeta_open = {};
rawmeta_stim = {};

for midx = 1:length(rawmetalist)
  thisrawmeta = rawmetalist{midx};
  if strcmp(thisrawmeta.type, 'openephys')
    rawmeta_open = [ rawmeta_open { thisrawmeta } ];
  elseif strcmp(thisrawmeta.type, 'intanstim')
    rawmeta_stim = [ rawmeta_stim { thisrawmeta } ];
  end
end

% Diagnostics.
diagmsgs = [ diagmsgs { sprintf( ...
  '.. Found %d Open Ephys folders and %d Intan stim folders.', ...
  length(rawmeta_open), length(rawmeta_stim) ) } ];


% Tattle details about the Open Ephys signal chain.

% Do this per folder, if we have multiple folders, even though the
% signal chain should be the same for setups with multiple file-recording
% nodes.

for fidx = 1:length(rawmeta_open)

  thisrawmeta = rawmeta_open{fidx};
  thiscookedmetalist = thisrawmeta.oesigchain;

  % Diagnostics.
  diagmsgs = [ diagmsgs { [ '== Open Ephys signal chain for "' ...
    thisrawmeta.folder '".' ] } ];

  % Diagnostics.
  diagmsgs = ...
    [ diagmsgs { sprintf( '.. Signal chain buffer was %.1f ms.', ...
      thisrawmeta.oebufinfo.bufms ) } ];
  diagmsgs = [ diagmsgs { sprintf( ...
    '.. Found %d processor nodes.', length(thiscookedmetalist) ) } ];

  % Record human-readable summaries.
  for midx = 1:length(thiscookedmetalist)
    thismeta = thiscookedmetalist{midx};
    thissummary = thismeta.descsummary;
    if isempty(thissummary)
      % Flag anything we didn't recognize.
      thissummary = ...
        { sprintf( '-- Node %d has no cooked metadata (%s).', ...
          thismeta.procnode, thismeta.procname ) };
    end
    diagmsgs = [ diagmsgs thissummary ];
  end

  diagmsgs = [ diagmsgs { '== End of Open Ephys signal chain.' } ];

end


% FIXME - Completely ignoring Intan stimulator recordings for now.



%
% Try to figure out what the signal chain is doing.

diagmsgs = [ diagmsgs { '== Beginning experiment parse.' } ];

if strcmp(exptype, 'loop2302')

  % Closed-loop experiments from early 2023.
  % This should have at least one Open Ephys recording folder and possibly
  % Intan stimulator folders as well.

  % Diagnostics.
  diagmsgs = [ diagmsgs { '.. Experiment type is "2023 Feb closed-loop".' } ];


  % Get the signal chain and channel map.

  % There should be at least one signal chain and they all should be the same.
  sigchain = rawmeta_open{1}.oesigchain;

  chanmap_raw = rawmeta_open{1}.chanmap_raw;
  chanmap_cooked = rawmeta_open{1}.chanmap_cooked;


  % Walk through the processing nodes, gathering selected metadata.
  % NOTE - We're making assumptions about what's in the chain. That's the
  % point of the 'loop2302' label.

  rawchans = {};
  monkeychan = '';
  samprate = NaN;
  ardinbit = NaN;

  torteband = [];
  torteinchan = NaN;
  tortemodeok = false;
  tortechanok = false;

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

  % First pass: Everything except the conditional trigger.
  % We need to guarantee that we have the crossing detector output bits first.

  for pidx = 1:length(sigchain)
    thisproc = sigchain{pidx};

    if strcmp(thisproc.procname, 'Intan Rec. Controller')

      % Save the raw channel names and sampling rate.
      rawchans = thisproc.chanlabels;
      samprate = thisproc.samprate;

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
      tortemodeok = strcmp(thisproc.outputmode, 'both');
      torteinchan = find(thisproc.channelselect);
      tortechanok = (1 == length(torteinchan));
      if ~isempty(torteinchan)
        torteinchan = torteinchan(1);
      end

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


  % Store what we found in a low-level metadata structure.

  cookedmeta = struct();

  cookedmeta.samprate = samprate;

  cookedmeta.torteband = torteband;
  cookedmeta.torteinchan = torteinchan;

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


% FIXME - Need to get a cooked channel list to translate channel numbers.


% FIXME - Copy of metadata variables for reference.
if false
  chanmap_raw = rawmeta_open{1}.chanmap_raw;
  chanmap_cooked = rawmeta_open{1}.chanmap_cooked;


  % Walk through the processing nodes, gathering selected metadata.
  % NOTE - We're making assumptions about what's in the chain. That's the
  % point of the 'loop2302' label.

  rawchans = {};
  monkeychan = '';
  samprate = NaN;
  ardinbit = NaN;

  torteband = [];
  torteinchan = NaN;
  tortemodeok = false;
  tortechanok = false;

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
end


  % Save the derived information.
  expmeta.('cookedmeta') = cookedmeta;

  % Get a human-readable summary.
  [ expsummary expdetails ] = euChris_summarizeConfigLoop2302( expmeta );

else

  % No idea how to parse this.
  thismsg = [ '###  Unrecognized experiment type "' exptype '".' ];
  diagmsgs = [ diagmsgs { thismsg } ];
  errmsgs = [ errmsgs { thismsg } ];
  isok = false;

end

diagmsgs = [ diagmsgs { '== Finished experiment parse.' } ];



% Augment the returned structure, or set it to an empty struct array if
% we weren't able to finish parsing.

if isok
  expmeta.('summary') = expsummary;
  expmeta.('details') = expdetails;

  expmeta.('diagmsgs') = diagmsgs;
  expmeta.('errmsgs') = errmsgs;
else
  expmeta = struct([]);
end


% Done.

end


%
% This is the end of the file.
