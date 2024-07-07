function [ ampmean ampdev lagmean lagdev ] = ...
  euInfo_getTimeLagPeakStats( timelagdata, datafield, ...
    timerange_ms, timesmooth_ms, magthresh, magacceptrange, method )

% function [ ampmean ampdev lagmean lagdev ] = ...
%   euInfo_getTimeLagPeakStats( timelagdata, datafield, ...
%     timerange_ms, timesmooth_ms, magthresh, magacceptrange, method )
%
% This analyzes a time-and-lag analysis dataset, extracting the mean and
% deviation of the data peak's amplitude and time lag by black magic,
% within the analysis window time range specified.
%
% This calls euInfo_collapseTimeLagAverages() to get the mean and deviation
% of the amplitude, finds the peak closest to 0 lag, finds the extent of
% that peak (via thresholding), and then calls euInfo_findTimeLagPeaks() to
% get peak amplitude and lag as a function of time. This is masked to reject
% peaks too far from the average peak's amplitude and lag extent, and then
% statistics are extracted.
%
% This works if and only if there _is_ a fairly clean data peak.
% Smoothing ahead of time might be necessary, and the target ranges will
% probably need to be hand-tuned.
%
% NOTE - For now, this only works on data that has been averaged across
% trials.
%
% "timelagdata" is a data structure per TIMEWINLAGDATA.txt. This should
%   contain "avg", "var", and "count" fields for the desired data field.
% "datafield" is a character vector with the name of the field being
%   operated on.
% "timerange_ms" [ min max ] specifies a window time range in milliseconds
%   to examine. A range of [] indicates all window times.
% "timesmooth_ms" is the smoothing window size in milliseconds for smoothing
%   data along the time axis before performing time-varying peak detection.
%   Specify 0 or NaN to not smooth.
% "magthresh" is a scalar between 0 and 1 specifying the data magnitude
%   cutoff used for finding peak extents. The extent threshold is this value
%   times the peak magnitude. A value of 0 is typical.
% "magacceptrange" [ min max ] is two positive scalar values that are
%   multiplied by the peak data magnitude to get a data magnitude acceptance
%   range for time-varying peak detection. A typical range would be
%   [ 0.5 inf ].
% "method" is an optional argument. If present, it should be 'largest' or
%   'weighted', specifying an euInfo_findTimeLagPeaks search method. The
%   default is 'largest'.
%
% "ampmean" is a matrix indexed by (destidx,srcidx) containing the mean
%   (signed) peak data value within the specified window for each pair.
% "ampdev" is a matrix indexed by (destidx,srcidx) containing the
%   standard deviation of the peak data value for each pair.
% "lagmean" is a matrix indexed by (destidx,srcidx) containing the mean
%   time lag within the specified window for each pair.
% "lagdev" is a matrix indexed by (destidx,srcidx) containing the
%   standard deviation of the time lag for each pair.


% Get metadata.

destchans = timelagdata.destchans;
destcount = length(destchans);

srcchans = timelagdata.srcchans;
srccount = length(srcchans);

laglist = timelagdata.delaylist_ms;
lagcount = length(laglist);

winlist = timelagdata.windowlist_ms;
wincount = length(winlist);

if isempty(timerange_ms)
  timerange_ms = [ -inf, inf ];
end

if ~exist('method', 'var')
  method = 'largest';
end


% Initialize output.

ampmean = NaN(destcount, srccount);
ampdev = NaN(destcount, srccount);
lagmean = NaN(destcount, srccount);
lagdev = NaN(destcount, srccount);


% Sanity-check the requested field, and extract it.

if ~isfield( timelagdata, datafield )
  disp([ '### [euInfo_getTimeLagPeakStats]  Can''t find field "' ...
    datafield '".' ]);
  return;
end

avgdata = timelagdata.(datafield);


%
% First pass: Do peak detection on the average (not time-varying).

[ avgvstime avgvslag ] = euInfo_collapseTimeLagAverages( ...
  timelagdata, datafield, { timerange_ms }, [] );

guessamp = NaN(destcount, srccount);
guesslagmin = NaN(destcount, srccount);
guesslagmax = NaN(destcount, srccount);

for destidx = 1:destcount
  for srcidx = 1:srccount

    thisdata = avgvslag.avg(destidx,srcidx,:);
    thisdata = reshape(thisdata, size(laglist));

    % Find the peak in average magnitude vs lag.
    bestidx = nlProc_findPeakNearest( thisdata, laglist, 0 );

    if ~isnan(bestidx)
      % Threshold around the peak to get the accepted lag range.
      % Note that "thisdata" and "thisamp" are both signed; the division
      % makes "normamp" positive no matter what the peak's sign was.

      thisamp = thisdata(bestidx);
      normamp = thisdata / thisamp;
      ampmask = normamp >= magthresh;

      thislagmin = laglist(bestidx);
      thislagmax = laglist(bestidx);

      % There's probably a Matlab way to do this, but do it by hand.

      inpeak = true;
      for lidx = bestidx:lagcount
        inpeak = inpeak & ampmask(lidx);
        if inpeak
          thislagmin = min(thislagmin, laglist(lidx));
          thislagmax = max(thislagmax, laglist(lidx));
        end
      end

      inpeak = true;
      for lidx = bestidx:-1:1
        inpeak = inpeak & ampmask(lidx);
        if inpeak
          thislagmin = min(thislagmin, laglist(lidx));
          thislagmax = max(thislagmax, laglist(lidx));
        end
      end

      % Save these.
      guessamp(destidx,srcidx) = thisamp;
      guesslagmin(destidx,srcidx) = thislagmin;
      guesslagmax(destidx,srcidx) = thislagmax;
    end

  end
end



%
% Second pass: Get time-varying peak detection statistics.

timemask = (winlist >= min(timerange_ms)) & (winlist <= max(timerange_ms));

for destidx = 1:destcount
  for srcidx = 1:srccount

    lagrange = ...
      [ guesslagmin(destidx,srcidx), guesslagmax(destidx,srcidx) ];
    amprange = magacceptrange * guessamp(destidx,srcidx);


    % Extract just this pair and call the search function.
    % We can't call the search function globally because the lag range
    % varies by pair.

    thispairdata = struct();
    thispairdata.destchans = destchans(destidx);
    thispairdata.srcchans = srcchans(srcidx);
    thispairdata.delaylist_ms = laglist;
    thispairdata.windowlist_ms = winlist;

    thispairdata.(datafield) = avgdata(destidx,srcidx,:,:);

    peakdata = euInfo_findTimeLagPeaks( ...
      thispairdata, datafield, timesmooth_ms, lagrange, method );


    % Mask the search data and compute statistics.

    thislagdata = reshape( peakdata.peaklags, size(winlist) );
    thisampdata = reshape( peakdata.peakamps, size(winlist) );

    ampmask = ...
      (thisampdata >= min(amprange)) & (thisampdata <= max(amprange));

    thislagdata = thislagdata(ampmask & timemask);
    thisampdata = thisampdata(ampmask & timemask);

    if ~isempty(thislagdata)
      ampmean(destidx,srcidx) = mean(thisampdata);
      ampdev(destidx,srcidx) = std(thisampdata);
      lagmean(destidx,srcidx) = mean(thislagdata);
      lagdev(destidx,srcidx) = std(thislagdata);
    end

  end
end



% Done.
end


%
% This is the end of the file.
