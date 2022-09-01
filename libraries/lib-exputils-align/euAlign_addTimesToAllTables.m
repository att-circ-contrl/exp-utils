function newtables = euAlign_addTimesToAllTables( ...
  oldtables, oldcolumn, newcolumn, corresptimes )

% function newtables = euAlign_addTimesToAllTables( ...
%   oldtables, oldcolumn, newcolumn, corresptimes )
%
% This function augments several tables with an additional timestamp column.
% these new timestamps are derived from an existing timestamp column using a
% correspondence table produced by euAlign_alignTables().
%
% This is a wrapper for euAlign_addTimesToTable().
%
% "oldtables" is a structure with zero or more fields. Each field contains
%   an event table that is to be augmented.
% "oldcolumn" is the name of the existing table column to use to generate
%   timestamps.
% "newcolumn" is the name of the new table column to generate.
% "corresptimes" is a table containing old and new column timestamps at
%   known-corresponding time points, produced by euAlign_alignTableS().
%
% "newtables" is a copy of "oldtables"; all tables in "newtables" have the
%   new timestamp column added. New timestamp values are linearly
%   interpolated between known points of correspondence.


newtables = struct();

tablist = fieldnames(oldtables);
for tidx = 1:length(tablist)
  thislabel = tablist{tidx};
  thistable = oldtables.(thislabel);

  % Tolerate an empty correspondence table.
  % Just copy the input without adding columns if that happens.
  if ~isempty(corresptimes)
    thistable = euAlign_addTimesToTable( ...
      thistable, oldcolumn, newcolumn, corresptimes );
  end

  newtables.(thislabel) = thistable;
end


% Done.

end


%
% This is the end of the file.
