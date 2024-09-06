function delaylist_samps = ...
  euInfo_helper_getDelaySamps( samprate, delay_range_ms, delay_step_ms )

euUtil_warnDeprecated( 'Call eiCalc_helper_getDelaySamps().' );

delaylist_samps = ...
  eiCalc_helper_getDelaySamps( samprate, delay_range_ms, delay_step_ms );

%
% This is the end of the file.
