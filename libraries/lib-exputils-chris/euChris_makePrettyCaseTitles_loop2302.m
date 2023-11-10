function titlelist = euChris_makePrettyCaseTitles_loop3202( labellist )

% function titlelist = euChris_makePrettyCaseTitles_loop3202( labellist )
%
% This attempts to parse a list of case labels, returning a list of
% pretty case titles. Labels that couldn't be parsed are used directly
% as titles.
%
% "labellist" is a cell array of character vectors with case labels.
%
% "titleelist" is a cell array of character vectors with human-readable
%   case titles.


titlelist = labellist;

for lidx = 1:length(labellist)
  [ thisband thiscurrent thisphase ] = ...
    euChris_parseCaseLabel_loop2302( labellist{lidx} );

  if ~isempty(thisband)

    thistitle = thisband;

    if ~isnan(thiscurrent)
      thistitle = [ thistitle sprintf(' %duA', thiscurrent) ];
    end

    if ~isempty(thisphase)
      thistitle = [ thistitle ' ' thisphase ];
    end

    titlelist{lidx} = thistitle;
  end
end


% Done.
end


%
% This is the end of the file.
