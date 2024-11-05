function acceptflag = euInfo_helper_filterNone( ...
  wavedest, wavesrc, samprate, params )

euUtil_warnDeprecated( 'Call eiCalc_helper_filterNone().' );

acceptflag = eiCalc_helper_filterNone( ...
  wavedest, wavesrc, samprate, params );

end

%
% This is the end of the file.
