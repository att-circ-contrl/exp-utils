function newtable = euUSE_cleanEventsTabular( oldtable, datacol, timecol )

% function newtable = euUSE_cleanEventsTabular( oldtable, datacol, timecol )
%
% This processes a data table of raw code word events, removing entries that
% have a value of zero (the idle state) and merging events that are one
% sample apart (which happens when event codes change at a sampling boundary).
%
% "oldtable" is a table containing event tuples to process.
% "datacol" is the label of the column that contains data values.
% "timecol" is the label of the column that contains timestamps (in samples).
%
% "newtable" is the revised table.

if isempty(oldtable)
  newtable = oldtable;
else

  oldvals = oldtable.(datacol);
  oldtimes = oldtable.(timecol);

  sampcount = length(oldtimes);

  % Zero test.
  zerokeepidx = (oldvals > 0);

  % Sample time test.
  if sampcount < 2
    diffkeepidx = logical(ones(size(zerokeepidx)));
  else
    diffkeepidx = ( (1 + oldtimes(1:(sampcount-1))) < oldtimes(2:sampcount) );
    diffkeepidx(sampcount) = true;
  end

  % Keep only the rows that passed the tests.
  newtable = oldtable((zerokeepidx & diffkeepidx),:);
end


% Done.

end


%
% This is the end of the file.
