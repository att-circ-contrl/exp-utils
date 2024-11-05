function result = euInfo_helper_analyzeTransfer( ...
  wavedest, wavesrc, samprate, delaylist, params )

euUtil_warnDeprecated( 'Call eiCalc_helper_analyzeTransfer().' );

result = eiCalc_helper_analyzeTransfer( ...
  wavedest, wavesrc, samprate, delaylist, params );

end

%
% This is the end of the file.
