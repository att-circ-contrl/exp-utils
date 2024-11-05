function winranges = euInfo_helper_getWindowSamps( ...
  samprate, time_window_ms, timelist_ms, trial_timeseries )

euUtil_warnDeprecated( 'Call eiCalc_helper_getWindowSamps().' );

winranges = eiCalc_helper_getWindowSamps( ...
  samprate, time_window_ms, timelist_ms, trial_timeseries );

end

%
% This is the end of the file.
