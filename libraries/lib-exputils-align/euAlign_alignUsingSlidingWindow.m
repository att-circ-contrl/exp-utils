function [ bestdeltalist bestcostlist ] = ...
  euAlign_alignUsingSlidingWindow( ...
    firsttimes, secondtimes, firstdata, seconddata, ...
    firstcandidates, windowrad, costmethod )

% function [ bestdeltalist bestcostlist ] = ...
%   euAlign_alignUsingSlidingWindow( ...
%     firsttimes, secondtimes, firstdata, seconddata, ...
%     firstcandidates, windowrad, costmethod )
%
% This performs sliding window time alignment of two event series, optionally
% matching data between series. This uses the squared distance cost function,
% and assumes that one matching pair of events will have ideal time alignment.
% Alignment is performed with windows centered around each "candidate" event.
%
% NOTE - This may take a while! There are O(c*w) tests, and each test
% takes O(w2) time for local optimization. So, total time is O(c*w3).
% For global optimization, each test takes O(n*w) time, for O(c*n*w2) time
% in total.
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
% "costmethod" is 'global' or 'local'. If it's 'global', all elements of
%   "firsttimes" and "secondtimes" are used when computing the cost function.
%   If it's 'local', only elements within the window range are used.
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


% Convert "costmethod" to a flag.
wantlocal = strcmp('local', costmethod);


% Get a list of candidate times, and corresponding data if it exists.

candidatetimes = firsttimes(firstcandidates);
candidatedata = [];
if ~isempty(firstdata)
  candidatedata = firstdata(firstcandidates);
end


% Get match candidate spans. Candidates that don't match will get NaNs.
[ spansecondstart spansecondend ] = euAlign_getSlidingWindowIndices( ...
  candidatetimes, secondtimes, windowrad );


% If we're doing local matching, get a list of local source windows too.
spanfirststart = [];
spanfirstend = [];
if wantlocal
  [ spanfirststart spanfirstend ] = euAlign_getSlidingWindowIndices( ...
    candidatetimes, firsttimes, windowrad );
end


% FIXME - Diagnostics.
if (false)
disp(sprintf( [ '.. Window sweep called with %d candidates (out of %d),' ...
' matching %d.' ], length(firstcandidates), length(firsttimes), ...
length(secondtimes) ));
end


%
% First pass: find least-cost matches.

% Walk through the candidate list.
for cidx = 1:length(candidatetimes)

  % Initialize with safe results.
  thisbestdelta = NaN;
  thisbestcost = inf;

  % Proceed only if we did have a matching span.
  if ~isnan(spansecondstart(cidx))

    % Get the first-list event's time and data.

    thisfirsttime = candidatetimes(cidx);
    thisfirstdata = NaN;
    if ~isempty(candidatedata)
      thisfirstdata = candidatedata(cidx);
    end


    % Get the windowed set of second-list events.

    thisstart = spansecondstart(cidx);
    thisend = spansecondend(cidx);
    winsecondtimes = secondtimes(thisstart:thisend);
    winseconddata = [];
    if ~isempty(seconddata)
      winseconddata = seconddata(thisstart:thisend);
    end


    % Get a list of potential time deltas.
    % If we have data values, only consider matching events.

    secondtimelist = winsecondtimes;
    if (~isnan(thisfirstdata)) && (~isempty(winseconddata))
      matchindices = find(winseconddata == thisfirstdata);
      secondtimelist = secondtimelist(matchindices);
    end

    deltalist = secondtimelist - thisfirsttime;


    % For each candidate time delta, evaluate the cost function.

    thisbestdelta = NaN;
    thisbestcost = inf;

    for didx = 1:length(deltalist)
      thisdelta = deltalist(didx);

      % NOTE - We can either evaluate cost using the whole event list, or
      % evaluate it using the windowed list.

      if wantlocal
        % Cost function evaluation using only local events.
        % Get the windowed set of second-list events.

        thisstart = spanfirststart(cidx);
        thisend = spanfirstend(cidx);

        % Only proceed if we have a matching window. This should always
        % be true, given that the candidate event is in the window.
        if ~isnan(thisstart)

          winfirsttimes = firsttimes(thisstart:thisend);
          winfirstdata = [];
          if ~isempty(firstdata)
            winfirstdata = firstdata(thisstart:thisend);
          end

          thiscost = euAlign_evalAlignCostFunctionSquare( ...
            (winfirsttimes + thisdelta), winsecondtimes, ...
            winfirstdata, winseconddata, ...
            windowrad );

          if thiscost < thisbestcost
            thisbestdelta = thisdelta;
            thisbestcost = thiscost;
          end
        end
      else
        % Cost function evaluation using all events.

        thiscost = euAlign_evalAlignCostFunctionSquare( ...
          (firsttimes + thisdelta), secondtimes, firstdata, seconddata, ...
          windowrad );

        if thiscost < thisbestcost
          thisbestdelta = thisdelta;
          thisbestcost = thiscost;
        end
      end
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
