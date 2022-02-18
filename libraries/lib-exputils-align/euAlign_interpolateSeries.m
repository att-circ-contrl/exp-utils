function newdata = euAlign_interpolateSeries( oldtimes, olddata, newtimes )

% function newdata = euAlign_interpolateSeries( oldtimes, olddata, newtimes )
%
% This performs linear interpolation of a sparsely-defined data series to
% a new set of sparse sample points, handling unusual cases (empty lists,
% NaN entries, etc).
%
% NOTE - To interpolate values off the ends of the source list, the first
% and last points in the source list are used to define a ramp. This gives
% a degraded fit that should still be fairly accurate near the endpoints.
%
% "oldtimes" is a list of time values for which the data series has known
%   values.
% "olddata" is a list of known data values for these times.
% "newtimes" is a list of time values to produce interpolated data values
%   for.
%
% "newdata" is a list of interpolated data values at the requested times.


% Most of this is done using "interp1", but we need to manually handle the
% odd cases first.


%
% Force the input to be sorted and remove NaN cases.
% This tolerates empty lists without trouble.

oldvalid = (~isnan(oldtimes)) & (~isnan(olddata));
oldtimes = oldtimes(oldvalid);
olddata = olddata(oldvalid);

% Sort and remove duplicates, rather than just sorting.
[ oldtimes sortidx invidx ] = unique(oldtimes, 'sorted');
olddata = olddata(sortidx);


% FIXME - Not sorting or filling NaNs in the query time series!



%
% Choose an approach depending on how many known data points we have.

if length(oldtimes) < 1

  % No data. Initialize to zero.
  newdata = zeros([ 1 desiredlength ]);

elseif length(oldtimes) < 2

  % A single data point. Initialize to a constant value.
  newdata = ones([ 1 length(newtimes) ]) *  olddata(1);

else

  % Multiple data points.


  % First pass: interpolate between known points.
  % Set the output to zero outside of the known range.

  newdata = interp1( oldtimes, olddata, newtimes, 'linear', 0 );


  % Second pass: Set values out of range to values interpolated using a
  % ramp that's contiguous with the known endpoint values.

  % We've already sorted the "old" series in time order.
  firsttime = oldtimes(1);
  firstdata = olddata(1);
  lasttime = oldtimes(length(oldtimes));
  lastdata = olddata(length(olddata));

  p = polyfit([ firsttime lasttime ], [firstdata lastdata], 1);

  indexmask = (newtimes < firsttime);
  if any(indexmask)
    newdata(indexmask) = polyval( p, newtimes(indexmask) );
  end

  indexmask = (newtimes > lasttime);
  if any(indexmask)
    newdata(indexmask) = polyval( p, newtimes(indexmask) );
  end

end



% Done.

end


%
% This is the end of the file.
