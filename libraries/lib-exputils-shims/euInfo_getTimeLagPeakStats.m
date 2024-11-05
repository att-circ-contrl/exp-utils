function [ ampmean ampdev lagmean lagdev ] = ...
  euInfo_getTimeLagPeakStats( timelagdata, datafield, ...
    timerange_ms, timesmooth_ms, magthresh, magacceptrange, method )

euUtil_warnDeprecated( 'Call eiCalc_getTimeLagPeakStats().' );

% "method" is an optional argument.

if exist('method', 'var')
  [ ampmean ampdev lagmean lagdev ] = ...
    eiCalc_getTimeLagPeakStats( timelagdata, datafield, ...
      timerange_ms, timesmooth_ms, magthresh, magacceptrange, method );
else
  [ ampmean ampdev lagmean lagdev ] = ...
    eiCalc_getTimeLagPeakStats( timelagdata, datafield, ...
      timerange_ms, timesmooth_ms, magthresh, magacceptrange );
end

end

%
% This is the end of the file.
