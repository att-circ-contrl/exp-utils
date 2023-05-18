function [ newfomlist newbasislist ] = euHLev_pruneBasisList( ...
  oldfomlist, oldbasislist, threshold, method )

% function [ newfomlist newbasislist ] = euHLev_pruneBasisList( ...
%   oldfomlist, oldbasislist, threshold, method )
%
% This selects one or more "best" basis vector sets from a set that was
% returned by "euHLev_getBasisDecomposition".
%
% "oldfomlist" is a vector of figure of merit values to prune.
% "oldbasislist" is a cell array with basis decompositions to prune.
% "threshold" is a figure-of-merit threshold value to apply.
% "method" is 'highestabove' for the highest above-threshold FOM value,
%   'firstabove' for the above-threshold FOM value earliest in the list,
%   or 'allabove' to keep all cases with above-threshold FOM values.
%
% "newfomlist" is a copy of "oldfomlist" with only those entries that matched
%   the selection criteria.
% "newbasislist" is a copy of the corresponding entries from "oldbasislist".


newfomlist = [];
newbasislist = {};


selectvector = false(size(oldfomlist));

abovemask = (oldfomlist >= threshold);

if strcmp(method, 'highestabove')

  maxval = max(oldfomlist);
  maxmask = (oldfomlist >= maxval);
  maxmask = maxmask & abovemask;

  if any(maxmask)
    thispos = min(find(maxmask));
    selectvector(thispos) = true;
  end

elseif strcmp(method, 'firstabove')

  if any(abovemask)
    thispos = min(find(abovemask));
    selectvector(thispos) = true;
  end

elseif strcmp(method, 'allabove')
  selectvector = abovemask;
else
  disp([ '### [euHLev_pruneBasisList]  Unknown method "' method '".' ]);
end


if any(selectvector)
  newfomlist = oldfomlist(selectvector);
  newbasislist = oldbasislist(selectvector);
end


% Done.
end


%
% This is the end of the file.
