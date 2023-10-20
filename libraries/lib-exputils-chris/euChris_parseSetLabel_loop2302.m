function [ datenum suffix ] = euChris_parseSetLabel_loop2302( setlabel )

% function [ datenum suffix ] = euChris_parseSetLabel_loop2302( setlabel )
%
% This attempts to parse a set label ("setprefix" in the set definitions)
% using Chris's 2023 naming convention.
%
% These have the form: (date)(suffix)
%
% (date) is digits, (suffix) is letters.
% For tests that didn't repeat, (suffix) is omitted.
%
% "setlabel" is a character vector holding the label to convert.
%
% "datenum" is a number indicating the date the dataset was recorded.
% "suffix" is a character vector indicating which cycle or session from
%   that date this set belongs to.
%
% Values that couldn't be extracted are returned as '' (char) or NaN (number).


datenum = NaN;
suffix = '';


% Try several parse patterns, from most specific to least specific.

tokenlist = regexp(setlabel, '^(\d+)([a-z]+)$', 'tokens');
if ~isempty(tokenlist)

  % Full pattern match.

  datenum = str2double( tokenlist{1}{1} );
  suffix = tokenlist{1}{2};

else

  tokenlist = regexp(setlabel, '^(\d+)$', 'tokens');
  if ~isempty(tokenlist)

    % Single-cycle run.
    datenum = str2double( tokenlist{1}{1} );

  end

end


% Done.
end


%
% This is the end of the file.
