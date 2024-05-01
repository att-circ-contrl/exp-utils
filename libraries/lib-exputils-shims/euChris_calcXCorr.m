function xcorrdata = euChris_calcXCorr( ...
  ftdata_first, ftdata_second, xcorr_params, detrend_method )

% This was moved to euInfo_xx.

disp('.. Deprecated function; call euInfo_calcXCorr() with new arguments.');


% Translate the old-style arguments.

win_params = xcorr_params;
win_params.delay_range_ms = xcorr_params.xcorr_range_ms;

xc_norm_method = xcorr_params.xcorr_norm_method;

xcorrdata = euInfo_calcXCorr( ...
  ftdata_first, ftdata_second, win_params, { 'avgtrials' }, ...
  detrend_method, xc_norm_method );


% Done.
end


%
% This is the end of the file.
