function [ newvals newtimes ] = euUSE_deglitchEvents( oldvals, oldtimes )

% function [ newvals newtimes ] = euUSE_deglitchEvents( oldvals, oldtimes )
%
% This checks a list of event timestamps for events that are one sample
% apart, and merges them. This happens when event codes change at a sampling
% boundary.
%
% This will also catch the situation where events are reported multiple
% times with the same timestamp.
%
% "oldvals" is a list of event data samples (integer data values).
% "oldtimes" is a list of event timestamps (in samples).
%
% "newvals" is a revised list of event data samples.
% "newtimes" is a revised list of event timestamps.


% Default output.
newvals = oldvals;
newtimes = oldtimes;


% Drop any samples where the distance to the _next_ timestamp is 1 or less.
% The sample at the end of the dataset is always kept (no "next" timestamp).

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
