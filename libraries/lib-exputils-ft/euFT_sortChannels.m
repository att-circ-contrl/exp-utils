function newftdata = euFT_sortChannels( oldftdata, labelstosort )

% function newftdata = euFT_sortChannels( oldftdata, labelstosort )
%
% This function sorts the channels in a Field Trip dataset using the
% provided list of channel labels or numbers as the input to sort.
%
% The intention is to be able to duplicate Charlie's sorting method (sorting
% the raw field trip names such that the _cooked_ names end up in order).
%
% This shuffles the labels in ftdata.label and shuffles the channel order
% within ftdata.trial{:}. This does _not_ modify any saved header or
% provenance data within ftdata.
%
% "oldftdata" is the Field Trip dataset to modify.
% "labelstosort" is a cell array with character vectors or a vector with
%   numbers. These get sorted, and the same sorting permutation gets applied
%   to ftdata.label.
%
% "newftdata" is the modified Field Trip dataset.


% Initialize.

newftdata = oldftdata;


% Sanity check.

if length(oldftdata.label) ~= length(labelstosort)
  disp('### Sorting list and ftdata.label are different lengths!');
  return;
end


% Perform the sort.

[ sortedlabels sortidx ] = sort(labelstosort);

newftdata.label = newftdata.label(sortidx);

for tidx = 1:length(newftdata.trial)
  newftdata.trial{tidx} = newftdata.trial{tidx}(sortidx,:);
end


% Done.
end


%
% This is the end of the file.
