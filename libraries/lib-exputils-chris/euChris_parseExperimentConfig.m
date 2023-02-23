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


% FIXME - NYI.


% Done.

end


%
% This is the end of the file.
