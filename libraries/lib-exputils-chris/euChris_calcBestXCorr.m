function peakdata = euChris_calcBestXCorr( ...
  xcorrdata, timesmooth_ms, lagtarget_ms, method )

% function peakdata = euChris_calcBestXCorr( ...
%   xcorrdata, timesmooth_ms, lagtarget_ms, method )
%
% This attempts to find the location and amplitude of the largest
% cross-correlation peak for each pair of signals as the signals evolve with
% time.
%
% NOTE - This is sensitive to the structure of the cross-correlation data.
%
% "xcorrdata" is a structure produced by euChris_calcXCorr().
% "timesmooth_ms" is the window size for smoothing data along the time axis,
%   in milliseconds. Specify 0 or NaN to not smooth.
% "lagtarget_ms" is a [ min max ] range for accepted time lags if using the
%   'largest' search method, or a scalar specifying the search starting point
%   if using the 'nearest' method.
% "method" is 'largest' to find the highest-magnitude peak in range (use
%   [] for the full range), or 'nearest' to find the peak closest to the
%   specified starting point.
%
% "peakdata" is a structure with the following fields:
%   "firstchans" is a cell array with FT channel names for the first set of
%     channels being compared.
%   "secondchans" is a cell array with FT channel names for the second set
%     of channels being compared.
%   "windowlist_ms" is a vector containing timestamps in millseconds
%     specifying where the middle of each cross-correlation window is.
%   "peaklags" is a matrix indexed by (firstchan, secondchan, winidx)
%     containing the lag time (in milliseconds) of the peak.
%   "peakamps" is a matrix indexed by (firstchan, secondchan, winidx)
%     containing the amplitude of the peak (a cross-correlation value).


% Get geometry.

firstcount = length(xcorrdata.firstchans);
secondcount = length(xcorrdata.secondchans);
lagcount = length(xcorrdata.delaylist_ms);
wincount = length(xcorrdata.windowlist_ms);


% Initialize output and copy metadata.

peakdata = struct();
peakdata.firstchans = xcorrdata.firstchans;
peakdata.secondchans = xcorrdata.secondchans;
peakdata.windowlist_ms = xcorrdata.windowlist_ms;
peakdata.peaklags = nan(firstcount, secondcount, wincount);
peakdata.peakamps = nan(firstcount, secondcount, wincount);


%
% First pass: Perform smoothing if requested.

xcvals = xcorrdata.xcorrvals;

if (~isnan(timesmooth_ms)) && (timesmooth_ms > 0)
  timelist_ms = xcorrdata.windowlist_ms;

  % Assume mostly-uniform spacing.
  timestep_ms = median(diff( timelist_ms ));
  smoothsize = round(timesmooth_ms / timestep_ms);

  if smoothsize > 1

    for firstidx = 1:firstcount
      for secondidx = 1:secondcount
        for lagidx = 1:lagcount
          thisdata = xcvals(firstidx, secondidx, :, lagidx);
          thisdata = reshape(thisdata, size(timelist_ms));

          % Triangular smoothing window with about 1.5x the requested size.
          thisdata = movmean(thisdata, smoothsize);
          thisdata = movmean(thisdata, smoothsize);

          xcvals(firstidx, secondidx, :, lagidx) = thisdata;
        end
      end
    end

  end
end



%
% Second pass: Perform peak detection.

laglist_ms = xcorrdata.delaylist_ms;
lagmask = true(size(laglist_ms));
startidx = NaN;

if strcmp('largest', method) && (~isempty(lagtarget_ms))
  minlag = min(lagtarget_ms);
  maxlag = max(lagtarget_ms);
  lagmask = (laglist_ms >= minlag) & (laglist_ms <= maxlag);
elseif strcmp('nearest', method')
  % Tolerate poorly formed input.
  if isnan(lagtarget_ms) || isempty(lagtarget_ms)
    lagtarget_ms = 0;
  end
  lagtarget_ms = median(lagtarget_ms);
end

for firstidx = 1:firstcount
  for secondidx = 1:secondcount
    for winidx = 1:wincount

      thisdata = xcvals(firstidx, secondidx, winidx, :);
      thisdata = reshape(thisdata, size(laglist_ms));

      thispeaklag = NaN;
      thispeakamp = NaN;

      if strcmp('largest', method)
        [ thispeaklag thispeakamp ] = ...
          helper_findPeakLargest( thisdata(lagmask), laglist_ms(lagmask) );
      elseif strcmp('nearest', method)
        [ thispeaklag thispeakamp ] = ...
          helper_findPeakNearest( thisdata, laglist_ms, lagtarget_ms );
      end

      peakdata.peaklags(firstidx, secondidx, winidx) = thispeaklag;
      peakdata.peakamps(firstidx, secondidx, winidx) = thispeakamp;

    end
  end
end



% Done.
end


%
% Helper Functions


function [ peaklag peakamp ] = helper_findPeakLargest( ampvals, lagvals )

  peaklag = NaN;
  peakamp = NaN;

  bestidx = nlProc_findPeakLargest( ampvals );

  if ~isnan(bestidx)
    peaklag = lagvals(bestidx);
    peakamp = ampvals(bestidx);
  end

end


function [ peaklag peakamp ] = ...
  helper_findPeakNearest( ampvals, lagvals, startlag )

  peaklag = NaN;
  peakamp = NaN;

  bestidx = nlProc_findPeakNearest( ampvals, lagvals, startlag );

  if ~isnan(bestidx)
    peaklag = lagvals(bestidx);
    peakamp = ampvals(bestidx);
  end

end


%
% This is the end of the file.
