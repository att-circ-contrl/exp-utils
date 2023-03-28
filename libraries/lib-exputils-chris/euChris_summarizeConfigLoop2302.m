function [ summary details ] = euChris_summarizeConfigLoop2302( expmeta )

% function [ summary details ] = euChris_summarizeConfigLoop2302( expmeta )
%
% This generates a human-readable summary and detailed human-readable
% description of the specified experiment configuration.
%
% This function works with 'loop2302' type metadata.
%
% "expmeta" is a structure containing aggregated metadata for an experiment,
%   per "CHRISEXPMETA.txt".
%
% "summary" is a short human-readable summary of the configuration.
% "details" is a human-readable detailed description of the configuration.


eol = sprintf('\n');

summary = [ 'Experiment type "' expmeta.exptype '".' eol ];
details = summary;

if ~strcmp( 'loop2302', expmeta.exptype )
  thismsg = [ 'Not supported by this summarization function!' eol ];
  summary = [ summary thismsg ];
  details = [ details thismsg ];

  % Bail out.
  return;
end


% We're a supported type.

% FIXME - NYI!
thismsg = [ 'FIXME - NYI.' eol ];
summary = [ summary thismsg ];
details = [ details thismsg ];


% Done.
end


%
% This is the end of the file.
