function [ bestdeltalist bestcostlist ] = ...
  euAlign_alignUsingFixedMapping( ...
    firsttimes, secondtimes, firstdata, seconddata, ...
    firstcandidates, windowrad )

% function [ bestdeltalist bestcostlist ] = ...
%   euAlign_alignUsingFixedMapping( ...
%     firsttimes, secondtimes, firstdata, seconddata, ...
%     firstcandidates, windowrad )
%
% This performs sliding window time alignment of two event series, optionally
% matching data between series. This uses the squared distance cost function.
% Alignment is performed with windows centered around each "candidate" event.
% A single time shift is applied within the window and optimized to minimize
% the cost function.
%
% NOTE - Each event within the window in the first list is assumed to map to
% the nearest event within the window in the second list. So, approximate
% alignment must already have been performed.
%
% NOTE - This takes O(c*w2) time, so use a small window size.
%
% Timestamps are typically in seconds, but this will tolerate integer
% timestamps.
%
% "firsttimes" is a vector of timestamps for the first set of events being
%   matched. This is expected to be monotonic (sorted in increasing order).
% "secondtimes" is a vector of timestamps for the second set of events.
%   This is expected to be monotonic (sorted in increasing order).
% "firstdata" is a vector containing data values for each event in the first
%   set. Set this to [] to skip data matching.
% "seconddata" is a vector containing data values for each event in the second
%   set. Set this to [] to skip data matching.
% "firstcandidates" is a vector containing indices of elements within
%   "firsttimes" to find optimal time deltas for.
% "windowrad" is the search distance to use when looking for matching
%   elements. This is the sliding window radius.
%
% "bestdeltalist" is a vector containing time deltas such that
%   tfirst + tdelta = tsecond. Each element in "firstcandidates" has a
%   corresponding element in this list (which is NaN if no matching event
%   was found in the second list).
% "bestcostlist" is a vector containing cost function values corresponding to
%   the elements in "bestdeltalist". Deltas are chosen to minimize cost.


% Initialize output.
bestdeltalist = [];
bestcostlist = [];


% Get a list of candidate times, and corresponding data if it exists.

candidatetimes = firsttimes(firstcandidates);
candidatedata = [];
if ~isempty(firstdata)
  candidatedata = firstdata(firstcandidates);
end


% Get windows around the candidates in the first and second lists.
% The first list will always have a valid span (the candidate itself).
% The second list will have NaNs for candidates with no matches.

[ spanfirststart spanfirstend ] = euAlign_getSlidingWindowIndices( ...
  candidatetimes, firsttimes, windowrad );
[ spansecondstart spansecondend ] = euAlign_getSlidingWindowIndices( ...
  candidatetimes, secondtimes, windowrad );


% Walk through the candidate list.

for cidx = 1:length(candidatetimes)

  % Initialize with safe results.
  thisbestdelta = NaN;
  thisbestcost = inf;

  % Proceed only if we did have valid spans.
  if (~isnan(spanfirststart(cidx))) && (~isnan(spansecondstart(cidx)))

    % Get the candidate event's time and data.

    thisfirsttime = candidatetimes(cidx);
    thisfirstdata = NaN;

    if ~isempty(candidatedata)
      thisfirstdata = candidatedata(cidx);
    end


    % Get the windowed first- and second-list events

    thisstart = spanfirststart(cidx);
    thisend = spanfirstend(cidx);

    winfirsttimes = firsttimes(thisstart:thisend);
    winfirstdata = [];

    if ~isempty(firstdata)
      winfirstdata = firstdata(thisstart:thisend);
    end

    thisstart = spansecondstart(cidx);
    thisend = spansecondend(cidx);

    winsecondtimes = secondtimes(thisstart:thisend);
    winseconddata = [];

    if ~isempty(seconddata)
      winseconddata = seconddata(thisstart:thisend);
    end


    % NOTE - In principle, we'd build a list of corresponding first- and
    % second-list events, then use that list to evaluate the derivative of
    % the cost function to find the global minimum.

    % In practice, we can do that implicitly.

    % Cost is sum [t2(k) - (t1(k) + delta)]^2.
    % The global minimum is at delta = (1/n) sum( t2(k) - t1(k) ).
    % I.e. it's just the average distance between matches.

    % So rather than keeping track of what the matches are, we can find
    % the minimum second-window distance for each first-window candidate
    % and not worry about where that second-window match was.


    distancecount = 0;
    distancesum = 0;

    % Keep a tally of total cost as well, per other alignment functions.
    distancecost = 0;

    for fidx = 1:length(winfirsttimes)

      % Find potential matches for this first-window event.

      if isempty(winfirstdata)
        secondcandidates = winsecondtimes;
      else
        thisval = winfirstdata(fidx);
        matchindices = find(winseconddata == thisval);
        secondcandidates = winsecondtimes(matchindices);
      end

      % Find the match with the smallest squared distance.
      % We don't actually need to record where the match was; just the
      % distance.

      if ~isempty(secondcandidates)

        thistime = winfirsttimes(fidx);
        deltalist = winsecondtimes - thistime;

        % Find the element with the minimum squared distance.
        costlist = deltalist .* deltalist;
        bestcost = min(costlist);
        bestidx = find(costlist == bestcost);
        bestidx = bestidx(1);

        % Get the time delta for this element. It's +/- sqrt(bestcost).
        bestdelta = deltalist(bestidx);

        distancesum = distancesum + bestdelta;
        distancecount = distancecount + 1;

        % Keep track of total cost.
        distancecost = distancecost + bestcost;

      end
    end

    % Save the average distance if we had any matches.

    if distancecount > 0
      thisbestdelta = distancesum / distancecount;
      thisbestcost = distancecost;
    end


    % Finished with this candidate from the first list.

  end

  bestdeltalist(cidx) = thisbestdelta;
  bestcostlist(cidx) = thisbestcost;

end


% Done.

end


%
% This is the end of the file.
