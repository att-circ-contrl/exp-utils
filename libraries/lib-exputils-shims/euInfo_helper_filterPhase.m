function acceptflag = euInfo_helper_filterPhase( ...
  wavedest, wavesrc, samprate, params )

euUtil_warnDeprecated( 'Call eiCalc_helper_filterPhase().' );

acceptflag = eiCalc_helper_filterPhase( ...
  wavedest, wavesrc, samprate, params );

end

%
% This is the end of the file.
