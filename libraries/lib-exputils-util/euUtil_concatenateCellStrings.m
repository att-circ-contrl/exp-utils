function newstring = euUtil_concatenateCellStrings( oldstrings, suffixstr )

% function newstring = euUtil_concatenateCellStrings( oldstrings, suffixstr )
%
% This accepts a cell array containing character vector and concatenates them
% into a single character vector. If a suffix is supplied, that suffix is
% appended to every input character vector. If no suffix is suppled, the
% value of "sprintf('\n')" is used (platform-agnostic line break).
%
% "oldstrings" is a cell array containing character vectors to concatenate.
% "suffixstr" is a cell array containing a suffix to append to all inputs.
%   If this is omitted, the value of "sprintf('\n')" is used.
%
% "newstring" is a character vector containing the concatenated inputs.


newstring = '';

if ~exist('suffixstr', 'var')
  suffixstr = sprintf('\n');
end


for sidx = 1:length(oldstrings)
  newstring = [ newstring oldstrings{sidx} suffixstr ];
end


% Done.
end

%
% This is the end of the file.
