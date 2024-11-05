function xcorrdata = euInfo_calcXCorr( ...
  ftdata_dest, ftdata_src, win_params, flags, ...
  detrend_method, xcorr_norm_method, phase_params )

euUtil_warnDeprecated( 'Call eiCalc_calcXCorr().' );

% "phase_params" is an optional argument.

if exist('phase_params', 'var')
  xcorrdata = eiCalc_calcXCorr( ...
    ftdata_dest, ftdata_src, win_params, flags, ...
    detrend_method, xcorr_norm_method, phase_params );
else
  xcorrdata = eiCalc_calcXCorr( ...
    ftdata_dest, ftdata_src, win_params, flags, ...
    detrend_method, xcorr_norm_method );
end

end

%
% This is the end of the file.
