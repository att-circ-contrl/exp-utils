function newdata = euInfo_smoothTimeLagAverages( ...
  olddata, datafields, timesmooth_ms, lagsmooth_ms, method )

euUtil_warnDeprecated( 'Call eiCalc_smoothTimeLagAverages().' );

newdata = eiCalc_smoothTimeLagAverages( ...
  olddata, datafields, timesmooth_ms, lagsmooth_ms, method );

%
% This is the end of the file.
