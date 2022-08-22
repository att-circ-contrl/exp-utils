function timecorresp = euAlign_fakeAlignmentWithExtents( ...
  firsttimelabel, firsttimeseries, secondtimelabel, secondtimeseries )

% function timecorresp = euAlign_fakeAlignmentWithExtents( ...
%   firsttimelabel, firsttimeextents, secondtimelabel, secondtimeextents )
%
% This function produces a fake time alignment reference table using the
% extents of two timestamp series. The fake alignment centers the series
% on each other.
%
% This is intended to be used when there isn't enough information to call
% "euAlign_alignTables()".
%
% NOTE - Time ranges shorter than 1 microsecond are assumed to be bogus.
%
% "firsttimelabel" is a column label for timestamps from the first series.
% "firsttimeseries" contains timestamp values from the first series. This
%   typically just holds the minimum and maximum timestamp value.
% "secondtimelabel" is a column label for timestamps from the second series.
% "secondtimeseries" contains timestamp values from the second series. This
%   typically just holds the minimum and maximum timestamp value.
%
% "timecorresp" is a table with "firsttimelabel" and "secondtimelabel"
%   columns, containing tuples with corresponding timestamps. This may be
%   used to interpolate time values from one time base to the other.


% Force sanity.

if isempty(firsttimeseries)
  firsttimeseries = 0;
end

if isempty(secondtimeseries)
  secondtimeseries = 0;
end


% Get extents.

firstmin = min(firsttimeseries);
firstmax = max(firsttimeseries);
firstavg = mean([ firstmin firstmax ]);
firstspan = firstmax - firstmin;

secondmin = min(secondtimeseries);
secondmax = max(secondtimeseries);
secondavg = mean([ secondmin secondmax ]);
secondspan = secondmax - secondmin;


% Force sanity again.

mintime = 1e-6;

if firstspan < mintime
  firstmin = firstavg - mintime;
  firstmax = firstavg + mintime;
  firstspan = mintime + mintime;
end

if secondspan < mintime
  secondmin = secondavg - mintime;
  secondmax = secondavg + mintime;
  secondspan = mintime + mintime;
end


% We now have extents and averages for the two time series.
% Adjust the smaller set of extents to match the larger.

if secondspan < firstspan
  secondmin = secondavg - 0.5 * firstspan;
  secondmax = secondavg + 0.5 * firstspan;
else
  firstmin = firstavg - 0.5 * secondspan;
  firstmax = firstavg + 0.5 * secondspan;
end


% Build the output table.

timecorresp = table();
timecorresp.(firsttimelabel) = [ firstmin ; firstmax ];
timecorresp.(secondtimelabel) = [ secondmin ; secondmax ];


% Done.

end


%
% This is the end of the file.
