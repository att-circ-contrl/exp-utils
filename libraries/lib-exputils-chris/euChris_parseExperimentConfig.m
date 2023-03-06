function [ expmeta errmsgs ] = ...
  euChris_parseExperimentConfig( rawmetalist, exptype, hintdata )

% function [ expmeta errmsgs ] = ...
%   euChris_parseExperimentConfig( rawmetalist, exptype, hintdata )
%
% This is a top-level entry point for parsing configuration data for
% one of Chris's experiment runs.
%
% "rawmetalist" is a structure array with the following fields:
%   "folder" is the data folder (containing structure.oebin, *.rhd, etc).
%   "header_ft" is the Field Trip header for this dataset.
%   "chans_an" is a cell array containing ephys analog channel names.
%   "chans_dig" is a cell array containing digital TTL channel names.
%   "settings" is a struture containing configuration information (such
%     as the XML parse of Open Ephys's "settings.xml").
%   "type" is 'openephys', 'intanrec', or 'intanstim'.
% "exptype" is a label defining the type of dataset being processed.
%   E.g.: 'loop2302'
% "hintdata" is a structure containing hints for processing metadata. This
%   may be a structure with no fields or an empty structure array.
%
% "expmeta" is a structure containing aggregated metadata for this run.
%   This is an empty structure if the run metadata couldn't be parsed.
% "errmsgs" is a cell array containing warning messages and error messages
%   generated while parsing.
%
% FIXME - Metadata for different types goes here!


expmeta = struct([]);
errmsgs = {};


if strcmp(exptype, 'loop2302')

  % Closed-loop experiments from early 2023.
  % This should have at least one Open Ephys recording folder and possibly
  % Intan stimulator folders as well.

  rawmeta_open = {};
  rawmeta_stim = {};

  for midx = 1:length(rawmetalist)
    thisrawmeta = rawmetalist(midx);
    if strcmp(thisrawmeta.type, 'openephys')
      rawmeta_open = [ rawmeta_open { thisrawmeta } ];
    elseif strcmp(thisrawmeta.type, 'intanstim')
      rawmeta_stim = [ rawmeta_stim { thisrawmeta } ];
    end
  end

  % FIXME - Diagnostics.
  disp(sprintf( ...
    '.. Found %d Open Ephys folders and %d Intan stim folders.', ...
    length(rawmeta_open), length(rawmeta_stim) ));


  % Process the Open Ephys folders.

  for fidx = 1:length(rawmeta_open)

    % Get all processor nodes in the signal chain.
    proclist = nlUtil_findXMLStructNodesRecursing( ...
      thisrawmeta.settings, { 'processor' }, {} );

    % FIXME - Diagnostics.
    disp(sprintf( '.. Found %d processor nodes.', length(proclist) ));

% FIXME - NYI.
  end

  % FIXME - Intan stim folders NYI!

else

  % No idea how to parse this.
  errmsgs = [ errmsgs { [ 'Unrecognized experiment type "' exptype '".' ] } ];

end


% Done.

end


%
% This is the end of the file.
