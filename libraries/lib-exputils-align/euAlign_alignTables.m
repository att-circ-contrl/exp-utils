function [ newfirsttab, newsecondtab, ...
  firstmatchmask, secondmatchmask, timecorresp ] = ...
  euAlign_alignTables( firsttab, secondtab, ...
    firsttimelabel, secondtimelabel, firstdatalabel, seconddatalabel, ...
    coarsewindows, medwindows, finewindow, outliersigma, verbosity )

% function [ newfirsttab, newsecondtab, ...
%   firstmatchmask, secondmatchmask, timecorresp ] = ...
%   euAlign_alignTables( firsttab, secondtab, ...
%     firsttimelabel, secondtimelabel, firstdatalabel, seconddatalabel, ...
%     coarsewindows, medwindows, finewindow, outliersigma, verbosity )
%
% This function time-aligns data tables from two sources, using both the
% two sources' timestamps and the recorded data values. Timestamps are
% expected to be monotonic (tables get sorted to guarantee this).
%
% If data field names are empty strings, alignment is performed based on
% timestamps alone.
%
% NOTE - This takes O(n) memory but O(n^3) time vs the number of events.
% Using data values helps a lot, as it reduces the number of potential
% matches. Using small window sizes also helps a lot.
%
% Timestamps are typically in seconds, but this will tolerate integer
% timestamps, and will preserve data types for interpolated values.
%
% Each input table is augmented with a new column containing aligned
% timestamp values from the other table. A table with known corresponding
% timestamps is also returned, along with vectors indicating which rows in
% the input tables had matching events in the other table.
%
%
% "Coarse" alignment is performed using a sliding window that moves in steps
% equal to the window radius. We pick one representative sample near the
% middle of the window and consider all samples in the window as alignment
% candidates for it.
%
% An alignment using a constant global delay is performed using the first
% coarse window value, before sliding-window coarse alignment is performed.
%
% "Medium" alignment uses each sample in turn as the center of a sliding
% window. All samples in the window are considered as alignment candidates
% for the central sample.
%
% "Fine" alignment uses each sample in turn as the center of a sliding
% window. Within each window, all samples are considered to be aligned with
% their closest corresponding candidates. A fixed time offset is applied to
% all samples and optimized to minimize cost given these matchings. The
% result is used as a final correction for the central sample's time offset.
%
%
% "firsttab" is a table containing event tuples from the first source.
% "secondtab" is a table containing event tuples from the second source.
% "firsttimelabel" specifies the first source's column containing timestamps.
% "secondtimelabel" specifies the second source's column containing timestamps.
% "firstdatalabel" if non-empty specifies the first source's column containing
%   data samples to compare.
% "seconddatalabel" if non-empty specifies the second source's column
%   containing data samples to compare.
% "coarsewindows" is a vector containing window half-widths for the first
%   pass of sliding-window time shifting. These are applied from widest to
%   narrowest.
% "medwindows" is a vector containing window half-widths for the second pass
%   of sliding-window time shifting. These are applied from widest to
%   narrowest.
% "finewindow" is the window half-width for final non-uniform time shifting.
%   this freezes the event mapping from the previous step and optimizes delay.
% "outliersigma" is used to reject spurious matches. If, within a window, a
%   match's time delay is this many deviations from the mean, it's squashed.
% "verbosity" is 'verbose', 'normal', or 'quiet'.
%
% "newfirsttab" is a copy of "firsttab" with a "secondtimelabel" column added.
% "newsecondtab" is a copy of "secondtab" with a "firsttimelabel" column.
% "firstmatchmask" is a vector indicating which rows in "firsttab" had
%   matching partners in "secondtab".
% "secondmatchmask" is a vector indicating which rows in "secondtab" had
%   matching partners in "firsttab".
% "timecorresp" is a table with "firsttimelabel" and "secondtimelabel"
%   columns, containing tuples with known-good time alignment. This is the
%   "canonical" set of timestamps used to interpolate the time values in
%   "newfirsttab" and "newsecondtab".


%
% Diagnostics switches.

% Normal verbosity settings.
want_verbose = false;
want_quiet = false;

% Bowing tests are enabled/disabled here too.
want_bowing = false;

if strcmp(verbosity, 'verbose')
  % Tattle everything.
  want_verbose = true;
  want_quiet = false;
  want_bowing = true;
elseif strcmp(verbosity, 'quiet')
  % No text output.
  want_verbose = false;
  want_quiet = true;
  want_bowing = false;
end


% Force consistency.
if want_quiet
  want_verbose = false;
end


%
% Get column names.

firstcols = firsttab.Properties.VariableNames;
secondcols = secondtab.Properties.VariableNames;


%
% Sort the tables, forcing monotonicity.
% This shouldn't be necessary, but do it just in case.

if ismember(firsttimelabel, firstcols)
  firsttab = sortrows(firsttab, { firsttimelabel } );
end

if ismember(secondtimelabel, secondcols)
  secondtab = sortrows(secondtab, { secondtimelabel } );
end


%
% Get time and data series.

% NOTE - Convert these to row vectors, from column vectors.

firsttimes = [];
if ismember(firsttimelabel, firstcols)
  firsttimes = firsttab.(firsttimelabel);
  firsttimes = firsttimes';
end

secondtimes = [];
if ismember(secondtimelabel, secondcols)
  secondtimes = secondtab.(secondtimelabel);
  secondtimes = secondtimes';
end

firstdata = [];
seconddata = [];

if (~isempty(firstdatalabel)) && (~isempty(seconddatalabel))
  if ismember(firstdatalabel, firstcols) ...
    && ismember(seconddatalabel, secondcols)

    firstdata = firsttab.(firstdatalabel);
    firstdata = firstdata';

    seconddata = secondtab.(seconddatalabel);
    seconddata = seconddata';

  end
end


%
% Sort the window sizes, just in case.

coarsewindows = flip(sort(coarsewindows));
medwindows = flip(sort(medwindows));



%
% Perform constant alignment.

% This is done using the coarse alignment routine but with a single input
% span covering the entire event list.

% Get the window size for cost evaluation.
constantwindow = max(coarsewindows);

% FIXME - Diagnostics.
if ~want_quiet
disp(sprintf( ...
'(%s)  Starting constant time alignment with window size %.4f.', ...
string(datetime), constantwindow ));
end


% Initialize our estimate of the constant offset, and the list of nonuniform
% time deltas.
bestdelta = mean(secondtimes) - mean(firsttimes);
firstdeltas = ones(size(firsttimes)) * bestdelta;

% Initialize our estimate of "aligned" time.
firsttimesaligned = firsttimes + firstdeltas;


% We're using an infinite search radius, so return values are scalars
% (there's only one window).
[ thismost, thismedian, thisleast ] = euAlign_getWindowExemplars( ...
  firsttimesaligned, secondtimes, firstdata, seconddata, inf );

% We want the exemplar with the fewest potential matches, for speed.
chosenlist = thisleast;

% Initialize to safe values.
bestdelta = 0;
bestcost = inf;

% Handle the "couldn't find anything" case gracefully.
if ~isempty(chosenlist)
  thiscandidate = chosenlist(1);

  % Evaluate cost globally.
  % We have only one candidate, so the return values are scalars.
  [ bestdeltalist bestcostlist ] = euAlign_alignUsingSlidingWindow( ...
      firsttimesaligned, secondtimes, firstdata, seconddata, ...
      thiscandidate, constantwindow, 'global' );

  % FIXME - Bulletproof this just in case.
  if (~isempty(bestdeltalist)) && (~isnan(bestdeltalist(1)))
    bestdelta = bestdeltalist(1);
    bestcost = bestcostlist(1);
  end
end

% Update the list of nonuniform time deltas.
firstdeltas = firstdeltas + bestdelta;


% FIXME - Diagnostics
if want_verbose && (~isempty(firstdeltas))
disp(sprintf( '(%s)  Best constant time delta: %.4f', ...
string(datetime), double(firstdeltas(1)) ));
end



%
% Perform coarse sliding-window alignment.

% This optimizes around a small number of "exemplar" events, rather than
% around all events.

for widx = 1:length(coarsewindows)

  thiswinrad = coarsewindows(widx);

% FIXME - Diagnostics.
if ~want_quiet
disp(sprintf( '(%s)  Starting coarse adjustment with window size %.4f.', ...
string(datetime), thiswinrad ));
end

  firsttimesaligned = firsttimes + firstdeltas;

  % Decompose input into spans with less than half overlap and pick
  % exemplar events for each span.
  [ thismost, thismedian, thisleast ] = euAlign_getWindowExemplars( ...
    firsttimesaligned, secondtimes, firstdata, seconddata, thiswinrad );

  % We want the exemplars with the fewest potential matches, for speed.
  firstcandidates = thisleast;

  % Perform alignment, evaluating cost locally around candidates.
  % Handle the "couldn't find anything" case gracefully.
  bestdeltalist = [];
  bestcostlist = [];
  bestfirsttimes = [];
  if ~isempty(chosenlist)
    [ bestdeltalist bestcostlist ] = euAlign_alignUsingSlidingWindow( ...
        firsttimesaligned, secondtimes, firstdata, seconddata, ...
        firstcandidates, thiswinrad, 'local' );
  end

  % Prune "couldn't find match" cases.
  if ~isempty(bestdeltalist)

    % Get the subset of the delta list that's valid (found matching events).
    valididx = ~isnan(bestdeltalist);
    bestdeltalist = bestdeltalist(valididx);
    bestcostlist = bestcostlist(valididx);

    % Get the times corresponding to these deltas, so that we can interpolate.
    firstcandidates = firstcandidates(valididx);
    bestfirsttimes = firsttimes(firstcandidates);

  end

  % Interpolate the new delta series and add it to the old delta series.
  % Our time basis is "firsttimes", not "firsttimesaligned".
  % Either one would work as long as we use it consistently (here and above).
  firstdeltas = firstdeltas + nlProc_interpolateSeries( ...
    bestfirsttimes, bestdeltalist, firsttimes );

% FIXME - Diagnostics.
if want_verbose
percvec = prctile(firstdeltas, [ 10 50 90 ]);
disp(sprintf( ...
'(%s)  Adjusted time decile/median/decile:   %.4f / %.4f / %.4f', ...
string(datetime), percvec(1), percvec(2), percvec(3) ));
end

end



%
% Perform medium sliding-window alignment.

% This optimizes around all events in the first list.

for widx = 1:length(medwindows)

  thiswinrad = medwindows(widx);

% FIXME - Diagnostics.
if ~want_quiet
disp(sprintf( '(%s)  Starting medium adjustment with window size %.4f.', ...
string(datetime), thiswinrad ));
end

  firsttimesaligned = firsttimes + firstdeltas;

  % Optimize around all events.
  firstcandidates = 1:length(firsttimesaligned);

  [ bestdeltalist bestcostlist ] = euAlign_alignUsingSlidingWindow( ...
    firsttimesaligned, secondtimes, firstdata, seconddata, ...
    firstcandidates, thiswinrad, 'local' );

  % We now have a list of perturbations to apply to "firstdeltas".

  % FIXME - How we handle invalid entries (entries with nothing in the
  % match window) depends on what we assume the data looks like.
  % If it's high-jitter, low-drift, we should keep the previous step's delta.
  % If it's low-jitter, high-drift, we should interpolate between entries.

  % For now, just keep the previous deltas for NaN entries.
  bestdeltalist(isnan(bestdeltalist)) = 0;

  % Apply the perturbation.
  firstdeltas = firstdeltas + bestdeltalist;

% FIXME - Diagnostics.
if want_verbose
percvec = prctile(firstdeltas, [ 10 50 90 ]);
disp(sprintf( ...
'(%s)  Adjusted time decile/median/decile:   %.4f / %.4f / %.4f', ...
string(datetime), percvec(1), percvec(2), percvec(3) ));
end

end



%
% Perform fine-tuning alignment with frozen event matching.

if (~isempty(finewindow)) && (~isnan(finewindow))

% FIXME - Diagnostics.
if ~want_quiet
disp(sprintf( '(%s)  Starting fine adjustment with window size %.4f.', ...
string(datetime), finewindow ));
end

  firsttimesaligned = firsttimes + firstdeltas;

  % Optimize around all events.
  firstcandidates = 1:length(firsttimesaligned);

  [ bestdeltalist bestcostlist ] = euAlign_alignWithFixedMapping( ...
    firsttimesaligned, secondtimes, firstdata, seconddata, ...
    firstcandidates, finewindow );

  % We now have a list of perturbations to apply to "firstdeltas".

  % FIXME - How we handle invalid entries (entries with nothing in the
  % match window) depends on what we assume the data looks like.
  % If it's high-jitter, low-drift, we should keep the previous step's delta.
  % If it's low-jitter, high-drift, we should interpolate between entries.

  % For now, just keep the previous deltas for NaN entries.
  bestdeltalist(isnan(bestdeltalist)) = 0;

  % Apply the perturbation.
  firstdeltas = firstdeltas + bestdeltalist;

% FIXME - Diagnostics.
if want_verbose
percvec = prctile(firstdeltas, [ 10 50 90 ]);
disp(sprintf( ...
'(%s)  Adjusted time decile/median/decile:   %.4f / %.4f / %.4f', ...
string(datetime), percvec(1), percvec(2), percvec(3) ));
end

end



%
% Diagnostics: Report final time alignment statistics.

lincoeffs = polyfit(firsttimes, firstdeltas, 1);
rampcoeff = lincoeffs(1);
constcoeff = lincoeffs(2);

deltaramp = constcoeff + firsttimes * rampcoeff;
deltaresidue = firstdeltas - deltaramp;

% Boil this down to a ramp plus a gaussian for baseline reporting.
% Report percentiles as auxiliary information.

% Get standard deviation in milliseconds.
deltasigma = 1e3 * std(deltaresidue);
% Get the 7-number summary, converted to milliseconds.
percvec = 1e3 * prctile(deltaresidue, [ 2 9 25 50 75 91 98 ]);

if ~want_quiet
disp(sprintf( ...
  '(%s)  Mean align %.4f s, drift %.1f ppm, jitter %.3f ms.', ...
  string(datetime), mean(firstdeltas), abs(rampcoeff) * 1e6, deltasigma ));
end

% FIXME - Diagnostics.
if want_verbose
disp(sprintf( '(%s)  7-number jitter stats:', string(datetime) ));
disp(sprintf( ...
'  %.2f  /  %.2f  /  %.2f /  [ %.2f ]  /  %.2f  / %.2f  /  %.2f', ...
percvec(1), percvec(2), percvec(3), percvec(4), percvec(5), percvec(6), ...
percvec(7) ));
end

%
% FIXME - More diagnostics. See if there was a bowing component.

if want_bowing

quadcoeffs = polyfit(firsttimes, firstdeltas, 2);
quadvals = polyval(quadcoeffs, firsttimes);
deltaresidue = firstdeltas - quadvals;

% Get standard deviation in milliseconds.
deltasigma = 1e3 * std(deltaresidue);
% Get the 7-number summary, converted to milliseconds.
percvec = 1e3 * prctile(deltaresidue, [ 2 9 25 50 75 91 98 ]);

if want_verbose
disp(sprintf( ...
'(%s)  With bowing subtracted, jitter %.3f ms, with 7-figure stats:', ...
string(datetime), deltasigma ));
disp(sprintf( ...
'  %.2f  /  %.2f  /  %.2f /  [ %.2f ]  /  %.2f  / %.2f  /  %.2f', ...
percvec(1), percvec(2), percvec(3), percvec(4), percvec(5), percvec(6), ...
percvec(7) ));
end

end



%
% Reject outliers.

% NOTE - We're doing ramp removal first!
fitcoeffs = polyfit(firsttimes, firstdeltas, 1);
fitvals = polyval(fitcoeffs, firsttimes);
fitresidue = firstdeltas - fitvals;

% Diagnostics.
beforecount = sum(isnan(fitresidue));

fitresidue = euAlign_squashOutliers( firsttimes, fitresidue, ...
  constantwindow, outliersigma);

% Figure out what to squash.
squashmask = isnan(fitresidue);

% Diagnostics.
squashcount = sum(squashmask) - beforecount;
if want_verbose
  disp(sprintf( '.. Squashed %d outliers out of %d samples (%.1f sigma).', ...
    squashcount, length(fitresidue), outliersigma ));
end

% NOTE - We need to have a series of deltas with no NaNs.
% So, get a sparse list and interpolate.
sparsedeltas = firstdeltas(~squashmask);
sparsetimes = firsttimes(~squashmask);



%
% Build augmented output tables and the canonical time table.


firstdeltas = ...
  nlProc_interpolateSeries( sparsetimes, sparsedeltas, firsttimes );

% This is the first table's estimate of the second table's times.
firsttimesaligned = firsttimes + firstdeltas;

% Find time deltas lined up with the second time series.
% Remember that firstaligned = (first + delta) = second.
seconddeltas = nlProc_interpolateSeries( ...
  firsttimesaligned, firstdeltas, secondtimes );

% This gets the second table's estimate of the first table's times.
secondtimesaligned = secondtimes - seconddeltas;


% Store the relevant tables.
% NOTE - We need to transpose the data row vectors to make table columns.

newfirsttab = firsttab;
newfirsttab.(secondtimelabel) = transpose(firsttimesaligned);

newsecondtab = secondtab;
newsecondtab.(firsttimelabel) = transpose(secondtimesaligned);

% Remember that (first + delta) = second.
timecorresp = table( transpose(sparsetimes), ...
  transpose(sparsetimes + sparsedeltas), ...
  'VariableNames', { firsttimelabel, secondtimelabel } );



%
% Assemble matching event masks.


% This finds unique matches, and gives NaN for non-matching events.

[ firstmatches secondmatches ] = euAlign_findMatchingEvents( ...
  firsttimesaligned, secondtimes, firstdata, seconddata, finewindow );

firstmatchmask = ~isnan(firstmatches);
secondmatchmask = ~isnan(secondmatches);



% Done.

end


%
% This is the end of the file.
