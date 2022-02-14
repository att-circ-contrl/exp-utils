function [ firstmatches secondmatches ] = euAlign_findMatchingEvents( ...
  firsttimes, secondtimes, firstdata, seconddata, windowrad )

% function [ firstmatches secondmatches ] = euAlign_findMatchingEvents( ...
%   firsttimes, secondtimes, firstdata, seconddata, windowrad )
%
% This performs sliding-window matching between two event series, finding
% corresponding events from the two input series. Matching events are those
% with the smallest squared time distance. This optionally requires matching
% data values between corresponding events.
%
% NOTE - Matches are a 1:1 mapping. Any given first-list event will match at
% most one second-list event, and vice-versa.
%
% Timestamps are typically in seconds, but this will tolerate integer
% timestamps.
%
% NOTE - This takes O(n*w) time, so it should be fairly fast.
%
% "firsttimes" is a vector of timestamps for the first set of events being
%   matched. This is expected to be monotonic (sorted in increasing order).
% "secondtimes" is a vector of timestamps for the second set of events.
%   This is expected to be monotonic (sorted in increasing order).
% "firstdata" is a vector containing data values for each event in the first
%   set. Set this to [] to skip data matching.
% "seconddata" is a vector containing data values for each event in the second
%   set. Set this to [] to skip data matching.
% "windowrad" is the search distance to use when looking for matching
%   elements. This is the sliding window radius.
%
% "firstmatches" is a vector with one element per entry in the first list
%   containing the index of the matching entry in the second list, or NaN
%   if there was no match.
% "secondmatches" is a vector with one element per entry in the second list
%   containing the index of the matching entry in the first list, or NaN if
%   there was no match.


% Initialize.

firstmatches = NaN * ones(size(firsttimes));
secondmatches = NaN * ones(size(secondtimes));


% Get window spans. We only need to do this for the first list's elements,
% since matching is symmetrical.
% NOTE - Indices will be NaN if corresponding spans weren't found!

[ spanstart spanend ] = euAlign_getSlidingWindowIndices( ...
  firsttimes, secondtimes, windowrad );


% Walk through the first-list events, computing distances and finding
% matches.

secondcosts = inf * ones(size(secondtimes));

for fidx = 1:length(firsttimes)

  % Get this first-list event.

  thisfirsttime = firsttimes(fidx);
  thisfirstdata = NaN;
  if ~isempty(firstdata)
    thisfirstdata = firstdata(fidx);
  end


  % Get the windowed list of second-list events.

  % If we have no matching events, these are NaN.
  thisstart = spanstart(fidx);
  thisend = spanend(fidx);

  winsecondtimes = [];
  winsecondindices = [];
  winseconddata = [];

  if (~isnan(thisstart)) && (~isnan(thisend))
    winsecondindices = thisstart:thisend;
    winsecondtimes = secondtimes(winsecondindices);
    if ~isempty(seconddata)
      winseconddata = seconddata(thisstart:thisend);
    end
  end


  % Find the closest matching candidate, without checking for duplicates.

  bestidx = NaN;
  bestcost = inf;

  % Do data filtering.
  % This tolerates an empty candidate list.
  if (~isnan(thisfirstdata)) && (~isempty(winseconddata))
    validmask = (winseconddata == thisfirstdata);

    winsecondindices = winsecondindices(validmask);
    winsecondtimes = winsecondtimes(validmask);
    winseconddata = winseconddata(validmask);
  end

  if ~isempty(winsecondtimes)
    winsecondcosts = winsecondtimes - thisfirsttime;
    winsecondcosts = winsecondcosts .* winsecondcosts;

    bestcost = min(winsecondcosts);
    bestidx = find(winsecondcosts == bestcost);

    if isempty(bestidx)
      % Shouldn't happen, but handle it anyways.
      bestidx = NaN;
      bestcost = inf;
    else
      % Handle the "tie" case.
      bestidx = bestidx(1);
      % Turn this back into a global index.
      bestidx = winsecondindices(bestidx);
    end
  end


  % If we found a match, store it, handling duplicate checking.

  if ~isnan(bestidx)
    oldsecondidx = secondmatches(bestidx);
    oldsecondcost = secondcosts(bestidx);

    if isnan(oldsecondidx)

      % This is the first match for this second-list event. Store it.

      firstmatches(fidx) = bestidx;
      secondmatches(bestidx) = fidx;
      secondcosts(bestidx) = bestcost;

    elseif bestcost < oldsecondcost

      % This is a better match for this second-list event. Un-store the
      % previous match and store the new one.

      firstmatches(oldsecondidx) = NaN;
      firstmatches(fidx) = bestidx;
      secondmatches(bestidx) = fidx;
      secondcosts(bestidx) = bestcost;

    end
  end

end


% Done.

end


%
% This is the end of the file.
