function xcorrdata = euInfo_calcXCorr( ...
  ftdata_dest, ftdata_src, win_params, flags, ...
  detrend_method, xcorr_norm_method, phase_params )

% function xcorrdata = euInfo_calcXCorr( ...
%   ftdata_dest, ftdata_src, win_params, flags, ...
%   detrend_method, xcorr_norm_method, phase_params )
%
% This calculates cross-correlations between two Field Trip datasets within
% a series of time windows, optionally filtering by phase.
%
% If phase filtering is requested, then for each signal pair in each trial,
% the average of (phase_dest - phase_src) is computed. Pairs are rejected if
% the average phase difference is outside of the specified range. Pairs are
% also rejected if the phase-lock value is below a minimum threshold.
%
% NOTE - Both datasets must have the same sampling rate and the same number
% of trials (trials are assumed to correspond).
%
% "ftdata_dest" is a ft_datatype_raw structure with trial data for the
%   putative destination channels.
% "ftdata_src" is a ft_datatype_raw structure with trial data for the
%   putative source channels.
% "win_params" is a structure giving time window and time lag range
%   information, per TIMEWINLAGSPEC.txt.
% "flags" is a cell array containing one or more of the following character
%   vectors:
%   'avgtrials' generates data averaged across trials, per TIMEWINLAGDATA.txt.
%   'pertrial' generates per-trial data, per TIMEWINLAGDATA.txt.
%   'spantrials' generates data by contatenating or otherwise aggregating
%     across trials, per TIMEWINLAGDATA.txt.
% "detrend_method" is 'detrend', 'zeromean', or 'none'.
% "xcorr_norm_method" is the normalization method to pass to "xcorr". This
%   is typically 'unbiased' (to normalize by sample count) or 'coeff' (to
%   normalize so that self-correlation is 1).
% "phase_params" is a structure with phase acceptance information, per
%   PHASEFILTPARAMS.txt. If this is omitted or is empty, no phase filtering
%   is performed.
%
% "xcorrdata" is a structure containing cross-correlation data, per
%   TIMEWINLAGDATA.txt. Relevant fields are:
%   "xcorrXXX" is a matrix containing cross-correlation values. These are
%     real, ranging from -1 to +1.


% Unpack preprocessing configuration.
% Support the old "demean" syntax.

preproc_config = {};

if strcmp('detrend', detrend_method)
  preproc_config = { 'detrend' };
elseif strcmp('zeromean', detrend_method) || strcmp('demean', detrend_method)
  preproc_config = { 'zeromean' };
end


% Figure out if we're phase-filtering.

want_phase = false;

if exist('phase_params', 'var')
  if ~isempty(phase_params)
    want_phase = ~isempty(fieldnames( phase_params ));
  end
end


% Package analysis configuration.

analysis_params = struct( 'norm_method', xcorr_norm_method );


if want_phase

  xcorrdata = euInfo_doTimeAndLagAnalysis( ...
    ftdata_dest, ftdata_src, win_params, flags, ...
    preproc_config, @euInfo_helper_analyzeXCorr, analysis_params, ...
    [ preproc_config, {'angle'} ], @euInfo_helper_filterPhase, phase_params );

else

  xcorrdata = euInfo_doTimeAndLagAnalysis( ...
    ftdata_dest, ftdata_src, win_params, flags, ...
    preproc_config, @euInfo_helper_analyzeXCorr, analysis_params, ...
    {}, @euInfo_helper_filterNone, struct() );

end


% done.
end



%
% This is the end of the file.
