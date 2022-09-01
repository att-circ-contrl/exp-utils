function corresptimes = ...
  euAlign_getUniqueTimestampTuples( evtable, timecolumns )

% function corresptimes = ...
%   euAlign_getUniqueTimestampTuples( evtable, timecolumns )
%
% This function searches a table of events that are labelled with one or more
% different timestamp columns. Timestamps within a column may repeat; for
% these cases, rows with any timestamp that has already been seen are
% discarded.
%
% "evtable" is the data table to read timestamps from.
% "timecolumns" is a cell array containing timestamp column labels.
%
% "corresptimes" is a table containing _only_ timestamp columns, with
%   timestamp values that are guaranteed to be unique.


corresptimes = table();

if ~isempty(evtable)

  % Copy the timestamp columns with duplicates.
  for tidx = 1:length(timecolumns)
    thislabel = timecolumns{tidx};
    corresptimes.(thislabel) = evtable.(thislabel);
  end

  % Build the validity mask.
  evcount = height(evtable);
  validmask = true(evcount, 1);
  if evcount >= 2
    for tidx = 1:length(timecolumns)
      thislabel = timecolumns{tidx};
      timeseries = corresptimes.(thislabel);

      thismask = false(evcount,1);
      thismask(2:evcount) = ...
        ( timeseries(1:(evcount-1)) == timeseries(2:evcount) );
      validmask = validmask & (~thismask);
    end
  end

  % Keep only valid rows.
  corresptimes = corresptimes(validmask,:);
end


% Done.

end


%
% This is the end of the file.
