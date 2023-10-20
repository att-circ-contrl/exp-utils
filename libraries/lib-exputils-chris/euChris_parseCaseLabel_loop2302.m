function [ band current phase ] = ...
  euChris_parseCaseLabel_loop2302( caselabel )

% function [ band current phase ] = ...
%   euChris_parseCaseLabel_loop2302( caselabel )
%
% This attempts to parse a case label ("prefix" in the set definitions)
% using Chris's 2023 naming conventions.
%
% These have the form: (band)(current)(phase)
%
% (band) is letters, (current) is digits, and (phase) is both.
%
% If (band) is omitted, it's assumed to be beta.
% Target phases of 0 were recorded as both "cal" and "0deg".
% Current is in uA, and is converted to a number. Other values are kept as
% character vectors.
%
% "caselabel" is a character vector holding the label to convert.
%
% "band" is a character vector indicating band.
% "current" is a number indicating the stimulation current in uA.
% "phase" is a character vector indicating target phase.
%
% Values that couldn't be extracted are returned as '' (char) or NaN (number).


band = '';
current = NaN;
phase = '';


% Try several parse patterns, from most specific to least specific.

tokenlist = regexp(caselabel, '^([a-z]+)(\d+)(\w+)$', 'tokens');
if ~isempty(tokenlist)

  % Full pattern match.

  band = tokenlist{1}{1};
  current = str2double( tokenlist{1}{2} );
  phase = tokenlist{1}{3};

else

  tokenlist = regexp(caselabel, '^(\d+)(\w+)$', 'tokens');
  if ~isempty(tokenlist)

    % Initial pilot run with implicit beta band.
    % NOTE - Testing cases may parse as this too and give bizarre results!

    band = 'be';
    current = str2double( tokenlist{1}{1} );
    phase = tokenlist{1}{2};

  end

end


% Done.
end


%
% This is the end of the file.
