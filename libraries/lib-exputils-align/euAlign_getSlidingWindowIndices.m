function [ firstindices lastindices ] = ...
  euAlign_getSlidingWindowIndices( firsttimes, secondtimes, windowrad )

% function [ firstindices lastindices ] = ...
%   euAlign_getSlidingWindowIndices( firsttimes, secondtimes, windowrad )
%
% This compiles a list of spans within "secondtimes" that are within a
% search range of any given event within "firsttimes". For each time in
% "firsttimes", a span of indices is found such that times in "secondtimes"
% within that span are in the range (t-radius) to (t+radius).
%
% "firsttimes" is a list of event times to use as window centers. This must
%   be sorted in ascending order.
% "secondtimes" is a list of event times to find windows within. This must
%   be sorted in ascending order.
% "windowrad" is the maximum acceptable difference between a window center
%   time from "firstimes" and an event time within "secondtimes".
%
% "firstindices" and "lastindices" are vectors containing the indices of the
%   first and last valid events in "secondtimes", for each time in
%   "firsttimes". For time firsttimes(k), the valid span in secondtimes is
%   from firstindices(k) to lastindices(k).
%
% NOTE - Entries with no matching elements have "NaN" stored. Check for this.


% FIXME - Blithely assume that the input is sorted.


% Handle error cases gracefully.

firstindices = [];
lastindices = [];

if isempty(firsttimes) || isempty(secondtimes) || (windowrad <= 0)

  % Invalid input. Return empty arrays.

elseif windowrad == inf

  % Special case: infinite window.
  % We know this will return everything, so skip the search.

  firstindices = ones(size(firsttimes));
  lastindices = firstindices * length(secondtimes);

else

  % Input seems legit at first glance. Proceed.


  % Initialize using an O(n) operation, since we only need to do this once.

  thismiddle = firsttimes(1);
  thismintime = thismiddle - windowrad;
  thismaxtime = thismiddle + windowrad;

  spanfirst = 1;
  spanlast = 1;
  secondcount = length(secondtimes);

  scratch = ...
    find( (secondtimes >= thismintime) & (secondtimes <= thismaxtime) );
  if ~isempty(scratch)
    spanfirst = min(scratch);
    spanlast = max(scratch);
  end


  % Walk through the input values.
  for fidx = 1:length(firsttimes)

    thismiddle = firsttimes(fidx);
    thismintime = thismiddle - windowrad;
    thismaxtime = thismiddle + windowrad;

    % Adjust the span boundary.
    % Remember to do the range checks before the value checks.

    while (spanlast < secondcount) && ...
      (secondtimes(spanlast + 1) <= thismaxtime)
      spanlast = spanlast + 1;
    end

    while (spanfirst < spanlast) && ...
      (secondtimes(spanfirst) < thismintime)
      spanfirst = spanfirst + 1;
    end

    % The span points to a valid region within secondtimes, but that region
    % isn't necessarily in range (we might not have found an in-range region).

    thisval = secondtimes(spanfirst);
    if (thisval >= thismintime) && (thisval <= thismaxtime)
      % Valid span.
      firstindices(fidx) = spanfirst;
      lastindices(fidx) = spanlast;
    else
      % No matching entries found. Store NaN.
      firstindices(fidx) = NaN;
      lastindices(fidx) = NaN;
    end

  end

end


% Done.

end


%
% This is the end of the file.
