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
  thisprocmetalist = thisrawmeta.oesigchain;

  % Diagnostics.
  diagmsgs = [ diagmsgs { [ '== Open Ephys signal chain for "' ...
    thisrawmeta.folder '".' ] } ];

  % Diagnostics.
  diagmsgs = ...
    [ diagmsgs { sprintf( '.. Signal chain buffer was %.1f ms.', ...
      thisrawmeta.oebufinfo.bufms ) } ];
  diagmsgs = [ diagmsgs { sprintf( ...
    '.. Found %d processor nodes.', length(thisprocmetalist) ) } ];

  % Record human-readable summaries.
  for midx = 1:length(thisprocmetalist)
    thismeta = thisprocmetalist{midx};
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


  % Get derived metadata.

  % All folders associated with this config should have the same raw metadata.
  % Process the first folder (at least one folder should be present).
  thisrawmeta = rawmeta_open{1};

  cookedmeta = euChris_getCookedMetadata_loop2302(thisrawmeta, hintdata);
  expmeta.('cookedmeta') = cookedmeta;


  % Get experiment configuration information.

  [ expconfig expsummary expdetails thisdiaglist thiserrlist ] = ...
    euChris_getExpConfig_loop2302( thisrawmeta, cookedmeta, hintdata );

  expmeta.('expconfig') = expconfig;

  expmeta.('summary') = expsummary;
  expmeta.('details') = expdetails;

  diagmsgs = [ diagmsgs thisdiaglist ];
  errmsgs = [ errmsgs thiserrlist ];

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
  expmeta.('diagmsgs') = diagmsgs;
  expmeta.('errmsgs') = errmsgs;
else
  expmeta = struct([]);
end


% Done.

end


%
% This is the end of the file.
