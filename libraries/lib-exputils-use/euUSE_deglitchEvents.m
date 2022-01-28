function [ newvals newtimes ] = euUSE_deglitchEvents( oldvals, oldtimes )

% function [ newvals newtimes ] = euUSE_deglitchEvents( oldvals, oldtimes )
%
% This checks a list of event timestamps for events that are one sample
% apart, and merges them. This happens when event codes change at a sampling
% boundary.
%
% This will also catch the situation where an event is reported multiple
% times with the same timestamp (as can happen with OpenEphys data).
%
% FIXME - This applies black magic kludgery to guess at rising vs falling
% bit edges.
%
% "oldvals" is a list of event data samples (integer data values).
% "oldtimes" is a list of event timestamps (in samples).
%
% "newvals" is a revised list of event data samples.
% "newtimes" is a revised list of event timestamps.


% Default output.
newvals = oldvals;
newtimes = oldtimes;


% First pass: Merge runs that have the same timestamp.

% FIXME - Kludging this!
% The problem is that we can't tell if bits are rising or falling.
% So, we'll assume "falling" if any code word is zero, and set output to
% zero; otherwise we'll assume "rising" and OR the bits together.
% This is specific to how USE event codes are sent (zero is the idle state).

sampcount = length(newtimes);
if sampcount > 1
  % Build a run mask.
  % This indicates whether the _following_ sample is the same.
  % This is always false for the last sample in the series.
  runmask = ( newtimes(1:(sampcount-1)) == newtimes(2:sampcount) );
  runmask(sampcount) = false;


  % We need to identify the start and end of each run.
  % Do this by building masks and then using "find".

  % We need a leading and trailing zero. We already have a trailing one.
  if ~isrow(runmask) ; runmask = transpose(runmask); end;
  runmask = [ false runmask ];

  runstart = (~runmask(1:sampcount)) & runmask(2:(sampcount+1));
  runend = runmask(1:sampcount) & (~runmask(2:(sampcount+1)));

  % This finds the 0 before a shifted 1, so it's the starting sample.
  runstart = find(runstart);
  % This finds the _shifted_ 1 before a 0, so it's already the ending sample.
  % The shift already accounted for "following sample", from above.
  runend = find(runend);


  % Iterate through the spans, giving them consistent data.
  % NOTE - We don't need to merge the spans; the next pass does that.

  for ridx = 1:length(runstart)
    thisstart = runstart(ridx);
    thisend = runend(ridx);
    thisdata = newvals(thisstart:thisend);

    if any(thisdata == 0)
      % FIXME - Assume this is a "returning to zero" sequence.
      % This coerces 0 into the same type as "thisval"/"thisdata".
      thisval = thisdata(1);
      thisval(1) = 0;
    else
      % FIXME - Assume all bit edges are rising edges.
      % FIXME - There doesn't seem to be notation for "bitwise-or the
      % elements of this vector". A "for" loop can do this but will be slow.
      thisval = thisdata(1);
      for didx = 2:length(thisdata)
        thisval = bitor(thisval, thisdata(didx));
      end
    end

    newvals(thisstart:thisend) = thisval;
  end
end


% Second pass: Drop any samples where the distance to the _next_ timestamp
% is 1 or less. We're always keeping the last sample in the dataset.

sampcount = length(newtimes);
if sampcount > 1
  keepidx = ( (1 + newtimes(1:(sampcount-1))) < newtimes(2:sampcount) );
  keepidx(sampcount) = true;
  newvals = newvals(keepidx);
  newtimes = newtimes(keepidx);
end


% Done.

end


%
% This is the end of the file.
