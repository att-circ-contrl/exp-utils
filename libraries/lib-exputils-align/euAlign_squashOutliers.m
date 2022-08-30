function newdata = euAlign_squashOutliers( ...
  timeseries, olddata, windowrad, outliersigma )

% function newdata = euAlign_squashOutliers( ...
%   timeseries, olddata, windowrad, outliersigma )
%
% This performs sliding-window outlier rejection. Data elements that are
% more than the specified number of deviations from the mean within the
% window are replaced with NaN in the output.
%
% There must be at least 6 non-NaN data elements in the window for squashing
% to be performed; otherwise all samples are kept.
%
% "timeseries" is a vector of timestamps for the data values being processed.
% "olddata" is a vector containing data values to remove outliers from.
% "windowrad" is the window half-width to use when evaluating statistics.
% "outliersigma" is the rejection threshold, in deviations from the mean.
%
% "newdata" is a copy of "olddata" with outlier values replaced with NaN.

% Initialize output.
newdata = olddata;

% Get window boundaries.
% NOTE - Because we're comparing the time series with itself, we'll
% always have valid corresponding windows (no NaN windows).
[ spanstart spanend ] = ...
  euAlign_getSlidingWindowIndices( timeseries, timeseries, windowrad );

% Walk through the list of samples.
for sidx = 1:length(newdata)
  thisval = newdata(sidx);
  if ~isnan(thisval)

    % Get the windowed list of data.
    % This always contains at least one element (the sample under test).
    thisstart = spanstart(sidx);
    thisend = spanend(sidx);
    windata = olddata(thisstart:thisend);

    % Squash NaNs and proceed if we have enough samples left.
    windata = windata(~isnan(windata));
    if length(windata) >= 6

% NOTE - Using > and <, not >= and <=, to handle the pathological case where
% values are nearly-constant, resulting in a very low deviation.

% FIXME - Standard deviation approach.
if false
      datasigma = std(windata);
      datamean = mean(windata);
      if abs(thisval - datamean) > (outliersigma * datasigma)
        newdata(sidx) = NaN;
      end
end

% FIXME - Percentile approach.
if false
      % One sigma is roughly 16%..84%.
      percvec = prctile(windata, [16 50 84]);
      datamean = percvec(2);
      datasigma = 0.5 * (percvec(3) - percvec(1));
      if abs(thisval - datamean) > (outliersigma * datasigma)
        newdata(sidx) = NaN;
      end
end

% FIXME - Two-sided (asymmetric) percentile approach.
if true
      % One sigma is roughly 16%..84%.
      percvec = prctile(windata, [16 50 84]);
      datamean = percvec(2);
      datasigmalow = percvec(2) - percvec(1);
      datasigmahigh = percvec(3) - percvec(2);
      if ( thisval > (datamean + outliersigma * datasigmahigh) ) ...
        || ( thisval < (datamean - outliersigma * datasigmalow) )
        newdata(sidx) = NaN;
      end
end

    end

  end
end


% Done.

end


%
% This is the end of the file.
