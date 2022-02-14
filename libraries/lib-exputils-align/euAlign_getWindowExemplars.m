function [ mostidxlist medianidxlist leastidxlist ] = ...
  euAlign_getWindowExemplars( ...
    firsttimes, secondtimes, firstdata, seconddata, windowrad )

% function [ mostidxlist medianidxlist leastidxlist ] = ...
%   euAlign_getWindowExemplars( ...
%     firsttimes, secondtimes, firstdata, seconddata, windowrad )
%
% This picks "exemplar" events from an event series, for purposes of alignment
% between two event series.
%
% The "first" event series is segmented into windows whose overlap is less
% than the window radius. Corresponding windows within the "second" event
% series are found. For each such pair of windows, each event within the first
% window is considered, and the number of potential matches it has in the
% second window is computed (typically requiring matching "data" values).
%
% For each "first" event window, the events having the most potential matches,
% least potential matches, and median number of potential matches are chosen.
% The indices of these events within the "first" event list are returned.
%
% NOTE - This may take a while. It's O(n*w).
%
% "firsttimes" is a vector of timestamps for the first set of events being
%   matched. This is expected to be monotonic (sorted in increasing order).
% "secondtimes" is a vector of timestamps for the second set of events.
%   This is expected to be monotonic (sorted in increasing order).
% "firstdata" is a vector containing data values for each event in the first
%   set. Set this to [] to skip data matching.
% "seconddata" is a vector containing data values for each event in the second
%   set. Set this to [] to skip data matching.
% "windowrad" is the window radius (half-width).
%
% "mostidxlist" is a vector containing indices of elements within
%   "firsttimes" that are window exemplars with large numbers of matches.
% "medianidxlist" is a vector containing indices of elements within
%   "firsttimes" that are window exemplars with typical numbers of matches.
% "leastidxlist" is a vector containing indices of elements within
%   "firsttimes" that are window exemplars with small numbers of matches.


% Initialize to bogus but safe values.
mostidxlist = [];
medianidxlist = [];
leastidxlist = [];



% Walk through the first event list segmenting into windows.

spanfirststart = [];
spanfirstend = [];
spancount = 0;

prevstartidx = 1;
prevstarttime = NaN;
if ~isempty(firsttimes)
  prevstarttime = firsttimes(1);
end

for fidx = 2:length(firsttimes)
  thisstarttime = firsttimes(fidx);
  if thisstarttime > (prevstarttime + windowrad)

    % End the previous segment and start a new one.

    spancount = spancount + 1;
    spanfirststart(spancount) = prevstartidx;
    spanfirstend(spancount) = fidx - 1;

    prevstartidx = fidx;
    prevstarttime = thisstarttime;

  end
end

% Save the final segment.
if ~isnan(prevstarttime)
  spancount = spancount + 1;
  spanfirststart(spancount) = prevstartidx;
  spanfirstend(spancount) = length(firsttimes);
end



% Walk through the list of windows, performing matching.
% Windows are guaranteed to contain at least one element.
% NOTE - There might not be any matching candidates! Tolerate that.

matchcount = 0;

% Segment the second list before looping, to keep it O(n).
% NOTE - Indices will be NaN if corresponding spans weren't found!
[ spansecondstart spansecondend ] = euAlign_getSlidingWindowIndices( ...
  firsttimes, secondtimes, windowrad );

for sidx = 1:length(spanfirststart)

  thisfirststart = spanfirststart(sidx);
  thisfirstend = spanfirstend(sidx);

  % Switch depending on whether we're doing data matching or not.

  if isempty(firstdata) || isempty(seconddata)

    % No data to match. Just pick the midpoint of the span.

    fidx = round(0.5 * (thisfirststart + thisfirstend));

    matchcount = matchcount + 1;
    mostidxlist(matchcount) = fidx;
    medianidxlist(matchcount) = fidx;
    leastidxlist(matchcount) = fidx;

  else

    % We have data; filter matches using it.

    % Test each candidate within the window.
    % Since the windows are at most half-overlapping, each candidate is
    % tested at most twice, keeping it O(n*w) rather than O(n*w2).

    candidatelist = [];
    candidatequantities = [];
    candidatecount = 0;

    % NOTE - Adjust the first series to be the middle half of the window.
    % We don't want exemplars that were from the extreme ends.
    oldfirststart = thisfirststart;
    thisfirststart = round(0.75 * thisfirststart + 0.25 * thisfirstend);
    thisfirstend = round(0.25 * oldfirststart + 0.75 * thisfirstend);

    for fidx = thisfirststart:thisfirstend

      thisdata = firstdata(fidx);

      % Get the data span within search range of this candidate.
      % NOTE - Indices will be NaN if corresponding spans weren't found!
      thissecondstart = spansecondstart(fidx);
      thissecondend = spansecondend(fidx);
      if (~isnan(thissecondstart)) && (~isnan(thissecondend))
        winseconddata = seconddata(thissecondstart:thissecondend);

        % Count the number of matches. This might be zero.
        thismatchcount = sum(winseconddata == thisdata);
        if thismatchcount > 0
          candidatecount = candidatecount + 1;
          candidatelist(candidatecount) = fidx;
          candidatequantities(candidatecount) = thismatchcount;
        end
      end
    end


    % If we had any viable candidates, pick candidates to return.

    if ~isempty(candidatelist)

      % Sort the lists.
      [ candidatequantities sortidx ] = sort(candidatequantities);
      candidatelist = candidatelist(sortidx);

      % Store indices with least, greatest, and median match quantities.

      matchcount = matchcount + 1;

      leastidxlist(matchcount) = candidatelist(1);
      mostidxlist(matchcount) = candidatelist(length(candidatelist));

      cidx = round( 0.5 * (1 + length(candidatelist)) );
      medianidxlist(matchcount) = candidatelist(cidx);

    end

  end

end

% FIXME - Diagnostics.
if(false)
disp(sprintf( ...
'-- Exemplars called; %d (%d) first, %d (%d) second, %.4f window', ...
length(firsttimes), length(firstdata), ...
length(secondtimes), length(seconddata), windowrad ));
disp(sprintf( '.. Tested %d and %d spans, found %d candidates.', ...
length(spanfirststart), length(spansecondstart), matchcount ));
end


% Done.

end


%
% This is the end of the file,
