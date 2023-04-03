function [ config summary details diagmsgs errmsgs ] = ...
  euChris_getExpConfig_loop2302( rawmeta, cookedmeta, hintdata )

% function [ config summary details diagmsgs errmsgs ] = ...
%   euChris_getExpConfig_loop2302( rawmeta, cookedmeta, hintdata )
%
% This examines an experiment session's metadata and builds an experiment
% configuration structure describing the experiment.
%
% This function works with 'loop2302' type metadata.
%
% "rawmeta" is the raw metadata structure for this experiment folder, per
%   RAWFOLDERMETA.txt.
% "cookedmeta" is the cooked (derived) metadata for this experiment, per
%   CHRISEXPMETA.txt.
% "hintdata" is a structure containing hints for processing metadata. If
%   there are no hints, this will be a structure with no fields.
%
% "config" is a structure describing the experiment configuration, per
%   CHRISEXPCONFIGS.txt.
% "summary" is a cell array of character vectors containing a short
%   human-readable summary of the configuration.
% "details" is a cell array of character vectors containing a
%   human-readable detailed description of the configuration.
% "diagmsgs" is a cell array containing diagnostic messages _and_ error
%   and warning messages generated during processing.
% "errmsg" is a cell array containing _only_ error and warning messages
%   generated during processing.


config = struct();

summary = {};
details = {};

diagmsgs = {};
errmsgs = {};



% FIXME - NYI!
thismsg = 'FIXME - NYI.';
summary = [ summary { thismsg } ];
details = [ details { thismsg } ];


% Done.
end


%
% This is the end of the file.
