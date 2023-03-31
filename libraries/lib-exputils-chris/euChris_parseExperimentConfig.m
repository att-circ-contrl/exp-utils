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
thissummary = '-bogus-';
thisdetails = '-bogus-';

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


diagmsgs = [ diagmsgs { '== Beginning experiment parse.' } ];

if strcmp(exptype, 'loop2302')

  % Closed-loop experiments from early 2023.
  % This should have at least one Open Ephys recording folder and possibly
  % Intan stimulator folders as well.

  % Diagnostics.
  diagmsgs = [ diagmsgs { '.. Experiment type is "2023 Feb closed-loop".' } ];



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


  %
  % Initialize cooked metadata.

  cookedmeta_open = {};
  cookedmeta_stim = {};

  intanreccount = 0;
  intanrecmeta = {};


  %
  % Process the Open Ephys folders.

  for fidx = 1:length(rawmeta_open)

    thisrawmeta = rawmeta_open{fidx};
    thiscookedmetalist = thisrawmeta.oesigchain;
    cookedmetaopen{fidx} = thiscookedmetalist;

    % Diagnostics.
    diagmsgs = [ diagmsgs { [ '== Analyzing Open Ephys metadata for "' ...
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


    % Walk through the nodes looking for ones relevant to us.
    for midx = 1:length(thiscookedmetalist)
      thismeta = thiscookedmetalist{midx};
      if strcmp(thismeta.procname, 'Intan Rec. Controller')

% FIXME - NYI; stopped here.

        % Recording controller. Support more than one of these.

        intanreccount = intanreccount + 1;
        intanrecmeta{intanreccount} = thismeta;

        diagmsgs = [ diagmsgs thismeta.descsummary ];

      end

    end

% FIXME - NYI; stopped here.
  end


  %
  % Process Intan stimulator folders.

  for fidx = 1:length(rawmeta_stim)

    thisrawmeta = rawmeta_stim{fidx};

    % Diagnostics.
    diagmsgs = [ diagmsgs { [ '.. Parsing Intan stimulator metadata for "' ...
      thisrawmeta.folder '".' ] } ];

    % FIXME - Intan stim folders NYI!

    thismsg = '### Intan stimulator parsing NYI!';
    diagmsgs = [ diagmsgs { thismsg } ];
    errmsgs = [ errmsgs { thismsg } ];
  end


  %
  % Build the metadata record and remaining auxiliary info.

  % Get a human-readable summary.
  [ thissummary thisdetails ] = euChris_summarizeConfigLoop2302( expmeta );

else

  % No idea how to parse this.
  thismsg = [ 'Unrecognized experiment type "' exptype '".' ];
  diagmsgs = [ diagmsgs { thismsg } ];
  errmsgs = [ errmsgs { thismsg } ];
  isok = false;

end

diagmsgs = [ diagmsgs { '== Finished experiment parse.' } ];



% Augment the returned structure, or set it to an empty struct array if
% we weren't able to finish parsing.

if isok
  expmeta.('summary') = thissummary;
  expmeta.('details') = thisdetails;

  expmeta.('diagmsgs') = diagmsgs;
  expmeta.('errmsgs') = errmsgs;
else
  expmeta = struct([]);
end


% Done.

end


%
% This is the end of the file.
