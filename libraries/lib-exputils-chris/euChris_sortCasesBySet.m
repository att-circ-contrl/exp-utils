function setcases = euChris_sortCasesBySet( caselist )

% function setcases = euChris_sortCasesBySet( caselist )
%
% This accepts a structure array containing case definition structures
% (per CHRISCASEMETA.txt), and sorts them into multiple lists that each
% have the same "setprefix" field within the list.
%
% "caselist" is a structure array containing case definitions, per
%   CHRISCASEMETA.txt.
%
% "setcases" is a cell array. Each cell contains its own structure array
%   containing case definitions that share a common "setprefix" value.
%   While "setcases" may be empty (if "caselist" is empty), the lists
%   contained within "setcases" are guaranteed to be non-empty.


setcases = {};
setlabels = {};

for cidx = 1:length(caselist)
  thiscase = caselist(cidx);
  thislabel = thiscase.setprefix;

  isnew = ~ismember(thislabel, setlabels);

  if isnew
    setlabels = [ setlabels { thislabel } ];
    thisidx = find(strcmp(thislabel, setlabels));
    setcases{thisidx} = thiscase;
  else
    thisidx = find(strcmp(thislabel, setlabels));
    thislist = setcases{thisidx};
    setcases{thisidx} = [ thislist thiscase ];
  end
end


% Done.
end


%
% This is the end of the file.
