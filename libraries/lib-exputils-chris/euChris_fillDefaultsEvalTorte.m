function newconfig = euChris_fillDefaultsEvalTorte( oldconfig )

% function newconfig = euChris_fillDefaultsEvalTorte( oldconfig )
%
% This function fills in any missing fields in the supplied configuration
% structure.
%
% This function builds configuration structures for euChris_evalTorte().
%
% "oldconfig" is the structure to augment. It may be struct() or struct([]).
%
% "newconfig" is a copy of "oldconfig" with any missing fields added and set
%   to reasonable default values.


newconfig = oldconfig;

if isempty(newconfig)
  newconfig = struct();
end

if ~isfield(newconfig, 'resample_ms')
  newconfig.resample_ms = 1.0;
end

if ~isfield(newconfig, 'average_tau')
  newconfig.average_tau = 10.0;
end

if ~isfield(newconfig, 'magcategory_edges')
  newconfig.magcategory_edges = [ 0.1 0.3 0.7 1.5 3.0 10.0 ];
end

if ~isfield(newconfig, 'phasecategory_count')
  newconfig.phasecategory_count = 8;
end


% Done.
end


%
% This is the end of the file.
