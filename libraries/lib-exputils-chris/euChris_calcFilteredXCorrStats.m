function [ ampmean ampdev lagmean lagdev ] = ...
  euChris_calcFilteredXCorrStats( xcorrdata, ...
    timerange_ms, timesmooth_ms, magthresh, magacceptrange )

% function [ ampmean ampdev lagmean lagdev ] = ...
%   euChris_calcFilteredXCorrStats( xcorrdata, ...
%     timerange_ms, timesmooth_ms, magthresh, magacceptrange )
%
% This analyzes a dataset produced by euChris_calcXCorr(), extracting the
% mean and deviation of the cross-correlation amplitude and cross-correlation
% lag by black magic, within the time window specified.
%
% This calls euChris_calcAverageXCorr() to get the mean and deviation of the
% amplitude, finds the peak closest to 0 lag, finds the extent of that peak
% (via thresholding), and then calls euChris_calcBestXCorr() to get peak
% amplitude and lag as a function of time. This is masked to reject peaks
% too far from the average peak's amplitude and lag extent, and then
% statistics are extracted.
%
% This works if and only if there _is_ a fairly clean cross-correlation peak.
%
% "xcorrdata" is a structure with raw cross-correlation data, per
%   CHRISXCORRDATA.txt.
% "timerange_ms" [ min max ] specifies a window time range in milliseconds
%   to examine. A range of [] indicates all window times.
% "timesmooth_ms" is the smoothing window size in milliseconds for smoothing
%   data along the time axis before performing time-varying peak detection.
%   Specify 0 or NaN to not smooth.
% "magthresh" is a scalar between 0 and 1 specifying the cross-correlation
%   cutoff used for finding peak extents. The extent threshold is this value
%   times the peak cross-correlation. A value of 0 is typical.
% "magacceptrange" [ min max ] is two positive scalar values that are
%   multiplied by the peak cross-correlation to get a cross-correlation
%   acceptance range for time-varying peak detection. A typical range
%   would be [ 0.5 inf ].
%
% "ampmean" is a matrix indexed by (firstidx,secondidx) containing the mean
%   cross-correlation within the specified window for each pair.
% "ampdev" is a matrix indexed by (firstidx,secondidx) containing the
%   standard deviation of the cross-correlation for each pair.
% "lagmean" is a matrix indexed by (firstidx,secondidx) containing the mean
%   time lag within the specified window for each pair.
% "lagdev" is a matrix indexed by (firstidx,secondidx) containing the
%   standard deviation of the time lag for each pair.


% Get metadata.

firstchans = xcorrdata.firstchans;
firstcount = length(firstchans);

secondchans = xcorrdata.secondchans;
secondcount = length(secondchans);

laglist = xcorrdata.delaylist_ms;
lagcount = length(laglist);

winlist = xcorrdata.windowlist_ms;
wincount = length(winlist);


% Initialize output.

ampmean = NaN(firstcount, secondcount);
ampdev = NaN(firstcount, secondcount);
lagmean = NaN(firstcount, secondcount);
lagdev = NaN(firstcount, secondcount);



%
% First pass: Do peak detection on the average XC (not time-varying).

[ xcvstime xcvslag ] = ...
  euChris_calcAverageXCorr( xcorrdata, { timerange_ms }, [] );

guessamp = NaN(firstcount, secondcount);
guesslagmin = NaN(firstcount, secondcount);
guesslagmax = NaN(firstcount, secondcount);

for firstidx = 1:firstcount
  for secondidx = 1:secondcount

    thisdata = xcvslag.xcorravg(firstidx,secondidx,:);
    thisdata = reshape(thisdata, size(laglist));

    % Find the peak in average magnitude vs lag.
    bestidx = nlProc_findPeakNearest( thisdata, laglist, 0 );

    if ~isnan(bestidx)
      % Threshold around the peak to get the accepted lag range.

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
      guessamp(firstidx,secondidx) = thisamp;
      guesslagmin(firstidx,secondidx) = thislagmin;
      guesslagmax(firstidx,secondidx) = thislagmax;
    end

  end
end



%
% Second pass: Get time-varying peak detection statistics.

timemask = (winlist >= min(timerange_ms)) & (winlist <= max(timerange_ms));

for firstidx = 1:firstcount
  for secondidx = 1:secondcount

    lagrange = ...
      [ guesslagmin(firstidx,secondidx), guesslagmax(firstidx,secondidx) ];
    amprange = magacceptrange * guessamp(firstidx,secondidx);


    % Extract just this pair and call the search function.
    % We can't call the search function globally because the lag range
    % varies by pair.

    thispairdata = struct();
    thispairdata.firstchans = xcorrdata.firstchans(firstidx);
    thispairdata.secondchans = xcorrdata.secondchans(secondidx);
    thispairdata.delaylist_ms = xcorrdata.delaylist_ms;
    thispairdata.windowlist_ms = xcorrdata.windowlist_ms;
    thispairdata.xcorravg = xcorrdata.xcorravg(firstidx,secondidx,:,:);

    peakdata = euChris_calcBestXCorr( ...
      thispairdata, timesmooth_ms, lagrange, 'largest' );


    % Mask the search data and compute statistics.

    thislagdata = reshape( peakdata.peaklags, size(winlist) );
    thisampdata = reshape( peakdata.peakamps, size(winlist) );

    ampmask = ...
      (thisampdata >= min(amprange)) & (thisampdata <= max(amprange));

    thislagdata = thislagdata(ampmask & timemask);
    thisampdata = thisampdata(ampmask & timemask);

    if ~isempty(thislagdata)
      ampmean(firstidx,secondidx) = mean(thisampdata);
      ampdev(firstidx,secondidx) = std(thisampdata);
      lagmean(firstidx,secondidx) = mean(thislagdata);
      lagdev(firstidx,secondidx) = std(thislagdata);
    end

  end
end



% Done.
end


%
% This is the end of the file.
