function result = euInfo_helper_analyzeMutual( ...
  wavedest, wavesrc, samprate, delaylist, params )

euUtil_warnDeprecated( 'Call eiCalc_helper_analyzeMutual().' );

result = eiCalc_helper_analyzeMutual( ...
  wavedest, wavesrc, samprate, delaylist, params );

%
% This is the end of the file.
