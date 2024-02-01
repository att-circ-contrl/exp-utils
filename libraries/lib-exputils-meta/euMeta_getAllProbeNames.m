function [ probelabels probetitles ] = euMeta_getAllProbeNames( probedefs )

% function [ probelabels probetitles ] = euMeta_getAllProbeNames( probedefs )
%
% This function aggregates all probe labels and probe titles from a list of
% probe definition structures.
%
% Duplicate definitions are assumed to have consistent label/title mapping.
% Duplicates are normal (replicated per-session).
%
% "probedefs" is either a struct array of probe definition structures (per
%   PROBEDEFS.txt), or a cell array of structs and/or struct arrays.
%
% "probelabels" is a list of unique fieldname-safe probe labels encountered.
% "probetitles" is a list of corresponding human-readable probe titles.


% Initialize.
probelabels = {};
probetitles = {};


% If we didn't start with a cell array, turn it into one.
if ~iscell(probedefs)
  probedefs = { probedefs };
end


% Walk through cells and entries within cells.
for cidx = 1:length(probedefs)
  thislist = probedefs{cidx};
  for lidx = 1:length(thislist)
    thisdef = thislist(lidx);

    thislabel = thisdef.label;
    thistitle = thisdef.title;

    % Add this entry if it isn't in already in the list.
    if ~any(strcmp( thislabel, probelabels ))
      probelabels = [ probelabels { thislabel } ];
      probetitles = [ probetitles { thistitle } ];
    end
  end
end


% Sort the list in lexical order.
if ~isempty(probelabels)
  [ probelabels, sortidx ] = sort(probelabels);
  probetitles = probetitles(sortidx);
end


% Done.
end


%
% This is the end of the file.
