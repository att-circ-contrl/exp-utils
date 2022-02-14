function totalcost = euAlign_evalAlignCostFunctionSquare( ...
  firsttimes, secondtimes, firstdata, seconddata, windowrad )

% function totalcost = euAlign_evalAlignCostFunctionSquare( ...
%   firsttimes, secondtimes, firstdata, seconddata, windowrad )
%
% This evaluates a cost function for an attempted alignment between two
% event lists. Optionally event data codes are presented that also have to
% match. Only events within the window radius of each other can match.
%
% This particular cost function is the sum of the squared distances between
% matching events. This takes O(n*w) time to compute.
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
%   elements.
%
% "totalcost" is the value of the cost function (smaller is better).


% Initialize.
totalcost = 0;


% Get a list of second event ranges to check for each event in the first list.
% NOTE - Indices will be NaN if corresponding spans weren't found!
[ spanfirst spanlast ] = euAlign_getSlidingWindowIndices( ...
  firsttimes, secondtimes, windowrad );


% Walk through the list of first events, compiling match costs.

for fidx = 1:length(firsttimes)

  % First, get the span to search. NaN indicates no match.

  thisfirst = spanfirst(fidx);
  thislast = spanlast(fidx);

  spantimes = [];
  spandata = [];
  if (~isnan(thisfirst)) && (~isnan(thislast))
    spantimes = secondtimes(thisfirst:thislast);
    if ~isempty(seconddata)
      spandata = seconddata(thisfirst:thislast);
    end
  end


  % Second, filter by data, if we have data to filter on.

  if isempty(spandata)
    secondtimelist = spantimes;
  else
    thisval = firstdata(fidx);
    matchindices = find(spandata == thisval);
    secondtimelist = spantimes(matchindices);
  end


  % Compute this element's cost contribution.
  % Cost is the squared distance to the closest event.

  % FIXME - Not pruning endpoints or worrying about a 1:1 mapping!
  % FIXME - Giving "no matching data" cases a cost of zero!

  if ~isempty(secondtimelist)
    thistime = firsttimes(fidx);
    thiscostlist = secondtimelist - thistime;
    thiscost = min(thiscostlist .* thiscostlist);

    totalcost = totalcost + thiscost;
  end

  end


% Done.
end



%
% This is the end of the file.
