function peakdata = euInfo_findTimeLagPeaks( ...
  timelagdata, fieldname, timesmooth_ms, lagtarget_ms, method )

% function peakdata = euInfo_findTimeLagPeaks( ...
%   timelagdata, fieldname, timesmooth_ms, lagtarget_ms, method )
%
% This examines time-and-lag analysis data and attempts to find the time lag
% with the peak data value for each window time. The intention is to be
% able to track the peak's location and amplitude for each signal pair as
% the signals evolve with time.
%
% Peaks are local maxima of magnitude (ignoring sign and complex phase angle).
%
% NOTE - Peak detection is sensitive to the structure of the data. Smoothing
% ahead of time will produce more reliable results, and the target range
% will probably need to be hand-tuned.
%
% NOTE - For now, this only works on data that has been averaged across
% trials.
%
% "timelagdata" is a data structure per TIMEWINLAGDATA.txt. This should
%   contain "avg", "var", and "count" fields for the desired data field.
% "fieldname" is a character vector with the name prefix used to define the
%   "avg" field being operated on.
% "timesmooth_ms" is the window size for smoothing data along the window
%   time axis, in milliseconds. Specify 0 or NaN to not smooth.
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
%     specifying where the middle of each analysis window is.
%   "peaklags" is a matrix indexed by (firstchan, secondchan, winidx)
%     containing the lag time (in milliseconds) of the peak.
%   "peakamps" is a matrix indexed by (firstchan, secondchan, winidx)
%     containing the (signed) data value at the peak location.


% Get metadata.

firstcount = length(timelagdata.firstchans);
secondcount = length(timelagdata.secondchans);

timelist_ms = timelagdata.windowlist_ms;
laglist_ms = timelagdata.delaylist_ms;

lagcount = length(timelagdata.delaylist_ms);
wincount = length(timelagdata.windowlist_ms);


% Initialize output and copy metadata.

peakdata = struct();
peakdata.firstchans = timelagdata.firstchans;
peakdata.secondchans = timelagdata.secondchans;
peakdata.windowlist_ms = timelagdata.windowlist_ms;
peakdata.peaklags = nan(firstcount, secondcount, wincount);
peakdata.peakamps = nan(firstcount, secondcount, wincount);


%
% Sanity-check the requested field, and extract the data.

if ~isfield( timelagdata, [ fieldname 'avg' ] )
  disp([ '### [euInfo_findTimeLagPeaks]  Can''t find field "' ...
    fieldname '".' ]);
  return;
end

avgvals = timelagdata.([ fieldname 'avg' ]);


%
% First pass: Perform smoothing if requested.

if (~isnan(timesmooth_ms)) && (timesmooth_ms > 0)
  % Assume mostly-uniform spacing.
  timestep_ms = median(diff( timelist_ms ));
  smoothsize = round(timesmooth_ms / timestep_ms);

  if smoothsize > 1

    for firstidx = 1:firstcount
      for secondidx = 1:secondcount
        for lagidx = 1:lagcount
          thisdata = avgvals(firstidx, secondidx, :, lagidx);
          thisdata = reshape(thisdata, size(timelist_ms));

          % Triangular smoothing window with about 1.5x the requested size.
          thisdata = movmean(thisdata, smoothsize);
          thisdata = movmean(thisdata, smoothsize);

          avgvals(firstidx, secondidx, :, lagidx) = thisdata;
        end
      end
    end

  end
end



%
% Second pass: Perform peak detection.

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

      thisdata = avgvals(firstidx, secondidx, winidx, :);
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
