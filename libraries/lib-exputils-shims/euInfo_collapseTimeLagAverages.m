function [ vstimelist vslaglist ] = euInfo_collapseTimeLagAverages( ...
  timelagdata, datafield, timeranges_ms, lagranges_ms )

euUtil_warnDeprecated( 'Call eiCalc_collapseTimeLagAverages().' );

[ vstimelist vslaglist ] = eiCalc_collapseTimeLagAverages( ...
  timelagdata, datafield, timeranges_ms, lagranges_ms );

end

%
% This is the end of the file.
