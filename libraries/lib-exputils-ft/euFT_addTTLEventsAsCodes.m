function newtable = ...
  euFT_addTTLEventsAsCodes( oldtable, ttltable, timecol, codecol, codelabel )

% function newtable = ...
%   euFT_addTTLEventsAsCodes( oldtable, ttltable, timecol, codecol, codelabel )
%
% This adds TTL events to an event code event table.
%
% "oldtable" is the event code event table to add events to.
% "ttltable" is the event table containing TTL events.
% "timecol" is the name of the column containing timestamps. This must be
%   present in both tables.
% "codecol" is the name of the column in "oldtable" that contains code
%   identification labels.
% "codelabel" is the code identification label to use for added TTL events.
%
% "newtable" is a copy of "oldtable" with TTL events added. Columns from
%   "ttltable" that are present in "oldtable" are copied to the new rows;
%   columns in "ttltable" that are not in "oldtable" are discarded. Columns
%   in "oldtable" that are not in "ttltable" are set to NaN or {''} in the
%   new rows.


% Initialize.
newtable = oldtable;


% Proceed if we have data.

if (~isempty(oldtable)) && (~isempty(ttltable))

  % Build a table with the same fields as oldtable containing only TTL events.

  oldcols = oldtable.Properties.VariableNames;
  ttlcols = ttltable.Properties.VariableNames;

  dummyrow = oldtable(1,:);

  ttlheight = height(ttltable);

  emptycol = cell(ttlheight,1);
  emptycol(:) = {''};

  nancol = nan(ttlheight,1);

  scratchtable = table();

  for cidx = 1:length(oldcols)
    thislabel = oldcols{cidx};
    testcell = dummyrow{1,cidx};

    if ismember(thislabel, ttlcols)
      scratchtable.(thislabel) = ttltable.(thislabel);
    elseif iscell(testcell)
      scratchtable.(thislabel) = emptycol;
    else
      scratchtable.(thislabel) = nancol;
    end
  end

  scratchtable.(codecol)(:) = { codelabel };


  % Append the two tables and sort on timestamp.
  % NOTE - If there are duplicate timestamps, order isn't guaranteed!

  newtable = vertcat(oldtable, scratchtable);
  newtable = sortrows(newtable, timecol);

end


% Done.

end


%
% This is the end of the file.
