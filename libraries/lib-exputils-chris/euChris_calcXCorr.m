function xcorrdata = euChris_calcXCorr( ...
  ftdata_first, ftdata_second, xcorr_params, detrend_method )

% function xcorrdata = euChris_calcXCorr( ...
%  ftdata_first, ftdata_second, xcorr_params, detrend_method )
%
% This calculates cross-correlations between two Field Trip datasets within
% a series of time windows, averaged across trials.
%
% Data is optionally detrended or mean-subtracted before cross-correlation.
%
% NOTE - Both datasets must have the same sampling rate and the same number
% of trials (trials are assumed to correspond).
%
% "ftdata_first" is a ft_datatype_raw structure with the first set of trials.
% "ftdata_second" is a ft_datatype_raw structure with the second set of trials.
% "xcorr_params" is a structure giving time window and time lag information,
%   per CHRISMUAPARAMS.txt.
% "detrend_method" is 'detrend', 'demean', or 'none' (default).
%
% "xcorrdata" is a structure containing cross-correlation data, per
%   CHRISXCORRDATA.txt.


% Wrap the phase-binned version.
% Phase bin width of 400 degrees and magnitude >= -1 should always pass.
% Ditto PLV >= -1.


% FIXME - Translate the old parameter structure.

win_params = xcorr_params;
win_params.delay_range_ms = xcorr_params.xcorr_range_ms;

xc_norm_method = xcorr_params.xcorr_norm_method;

phaseparams = struct();
phaseparams.phasetargetdeg = 0;
phaseparams.acceptwidthdeg = 400;
phaseparams.minplv = -1;

xcorrdata = euInfo_calcXCorrPhaseBinned( ...
  ftdata_first, ftdata_second, win_params, { 'avgtrials' }, ...
  detrend_method, xc_norm_method, phaseparams );


% Done.
end


%
% This is the end of the file.
