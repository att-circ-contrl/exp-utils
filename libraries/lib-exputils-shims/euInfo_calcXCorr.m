function xcorrdata = euInfo_calcXCorr( ...
  ftdata_dest, ftdata_src, win_params, flags, ...
  detrend_method, xcorr_norm_method, phase_params )

euUtil_warnDeprecated( 'Call eiCalc_calcXCorr().' );

xcorrdata = eiCalc_calcXCorr( ...
  ftdata_dest, ftdata_src, win_params, flags, ...
  detrend_method, xcorr_norm_method, phase_params );

%
% This is the end of the file.
