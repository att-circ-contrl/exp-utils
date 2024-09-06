function result = euInfo_helper_analyzeXCorr( ...
  wavedest, wavesrc, samprate, delaylist, params )

euUtil_warnDeprecated( 'Call eiCalc_helper_analyzeXCorr().' );

result = eiCalc_helper_analyzeXCorr( ...
  wavedest, wavesrc, samprate, delaylist, params );

%
% This is the end of the file.
