function [ datenum datetext suffix ] = ...
  euChris_parseSessionLabel_loop2302( sessionlabel )

% function [ datenum datetext suffix ] = ...
%   euChris_parseSessionLabel_loop2302( sessionlabel )
%
% This attempts to parse a session label ("setprefix" in the set definitions)
% using Chris's 2023 naming convention.
%
% These have the form: (date)(suffix)
%
% (date) is digits, (suffix) is letters.
% For tests that didn't repeat, (suffix) is omitted.
%
% If a cell array is passed instead of a character vector, return values
% are vectors/cell arrays.
%
% "sessionlabel" is a character vector holding the label to convert.
%
% "datenum" is a number indicating the date the dataset was recorded.
% "datetext" is a character vector indicated the date the dataset was
%   recorded.
% "suffix" is a character vector indicating which cycle or session from
%   that date this set belongs to.
%
% Values that couldn't be extracted are returned as '' (char) or NaN (number).


if iscell(sessionlabel)

  % We were passed a cell array. Recurse.

  % FIXME - Blithely assume one-dimensional input.

  datenum = NaN(size(sessionlabel));
  datetext = cell(size(sessionlabel));
  suffix = cell(size(sessionlabel));

  for cidx = 1:length(sessionlabel)
    [ thisdatenum thisdatetext thissuffix ] = ...
      euChris_parseSessionLabel_loop2302( sessionlabel{cidx} );
    datenum(cidx) = thisdatenum;
    datetext{cidx} = thisdatetext;
    suffix{cidx} = thissuffix;
  end

else

  % We were passed a character vector label. Parse it.

  datenum = NaN;
  datetext = '';
  suffix = '';

  % Try several parse patterns, from most specific to least specific.

  tokenlist = regexp(sessionlabel, '^(\d+)([a-z]+)$', 'tokens');
  if ~isempty(tokenlist)

    % Full pattern match.

    datetext = tokenlist{1}{1};
    datenum = str2double( datetext );
    suffix = tokenlist{1}{2};

  else

    tokenlist = regexp(sessionlabel, '^(\d+)$', 'tokens');
    if ~isempty(tokenlist)

      % Single-cycle run.
      datetext = tokenlist{1}{1};
      datenum = str2double( datetext );

    end

  end

end


% Done.
end


%
% This is the end of the file.
