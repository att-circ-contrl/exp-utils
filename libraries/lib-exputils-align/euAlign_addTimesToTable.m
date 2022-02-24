function newtable = euAlign_addTimesToTable( ...
  oldtable, oldcolumn, newcolumn, corresptimes )

% function newtable = euAlign_addTimesToTable( ...
%   oldtable, oldcolumn, newcolumn, corresptimes )
%
% This function augments a table with an additional timestamp column. These
% new timestamps are derived from an existing timestamp column using a
% correspondence table produced by euAlign_alignTables().
%
% If the new timestamp column already exists or if it can't be generated,
% "newtable" is a copy of "oldtable".
%
% "oldtable" is the table to augment.
% "oldcolumn" is the name of the existing table column to use to generate
%   timestamps.
% "newcolumn" is the name of the new table column to generate.
% "corresptimes" is a table containing old and new column timestamps at
%   known-corresponding time points, produced by euAlign_alignTables().
%
% "newtable" is a copy of "oldtable" with the new column added. New timestamp
%   values are linearly interpolated between known points of correspondence.

newtable = oldtable;

if (~isempty(newtable)) && (~isempty(corresptimes))
  if ismember(oldcolumn, corresptimes.Properties.VariableNames) ...
    && ismember(newcolumn, corresptimes.Properties.VariableNames) ...
    && ismember(oldcolumn, newtable.Properties.VariableNames) ...
    && (~ismember(newcolumn, newtable.Properties.VariableNames))

    newtimes = nlProc_interpolateSeries( ...
      corresptimes.(oldcolumn), corresptimes.(newcolumn), ...
      newtable.(oldcolumn) );

    if ~iscolumn(newtimes)
      newtimes = transpose(newtimes);
    end

    newtable.(newcolumn) = newtimes;

  end
end


% Done.

end


%
% This is the end of the file.
