function peakdata = euInfo_findTimeLagPeaks( ...
  timelagdata, datafield, timesmooth_ms, lagtarget_ms, method )

euUtil_warnDeprecated( 'Call eiCalc_findTimeLagPeaks().' );

peakdata = eiCalc_findTimeLagPeaks( ...
  timelagdata, datafield, timesmooth_ms, lagtarget_ms, method );

%
% This is the end of the file.
