function xcorrdata = euInfo_calcXCorr( ...
  ftdata_first, ftdata_second, win_params, flags, ...
  detrend_method, xcorr_norm_method, phase_params )

% function xcorrdata = euInfo_calcXCorr( ...
%   ftdata_first, ftdata_second, win_params, flags, ...
%   detrend_method, xcorr_norm_method, phase_params )
%
% This calculates cross-correlations between two Field Trip datasets within
% a series of time windows, optionally filtering by phase.
%
% If phase filtering is requested, then for each signal pair in each trial,
% the average of (phase_second - phase_first) is computed. Pairs are
% rejected if the average phase difference is outside of the specified
% range. Pairs are also rejected if phase-lock value is below a minimum
% threshold.
%
% NOTE - Both datasets must have the same sampling rate and the same number
% of trials (trials are assumed to correspond).
%
% "ftdata_first" is a ft_datatype_raw structure with the first set of trials.
% "ftdata_second" is a ft_datatype_raw structure with the second set of trials.
% "win_params" is a structure giving time window and time lag range
%   information, per TIMEWINLAGSPEC.txt.
% "flags" is a cell array containing one or more of the following character
%   vectors:
%   'avgtrials' generates data averaged across trials, per TIMEWINLAGDATA.txt.
%   'pertrial' generates per-trial data, per TIMEWINLAGDATA.txt.
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


analysis_func = @( wavefirst, wavesecond, samprate, delaylist, params ) ...
  helper_analysisfunc( wavefirst, wavesecond, samprate, delaylist, params );

analysis_params = struct( 'norm_method', xcorr_norm_method );

filter_func_none = @( wavefirst, wavesecond, samprate, params ) true;

filter_func_phase = @( wavefirst, wavesecond, samprate, params ) ...
  helper_filterfunc( wavefirst, wavesecond, samprate, params );


if want_phase

  xcorrdata = euInfo_doTimeAndLagAnalysis( ...
    ftdata_first, ftdata_second, win_params, flags, ...
    preproc_config, analysis_func, analysis_params, ...
    [ preproc_config, {'angle'} ], filter_func_phase, phase_params );

else

  xcorrdata = euInfo_doTimeAndLagAnalysis( ...
    ftdata_first, ftdata_second, win_params, flags, ...
    preproc_config, analysis_func, analysis_params, ...
    {}, filter_func_none, struct() );

end


% done.
end


%
% Helper Functions


function result = helper_analysisfunc( ...
  wavefirst, wavesecond, samprate, delaylist, params )

  % NOTE - We have a list of lags to be tested, in samples.
  % The "xcorr" function takes a maximum shift, not a list of shifts.

  % This works fine with a delay of 0.
  delaymax = max(abs(delaylist));
  delaystested = (-delaymax):delaymax;

  rvals = xcorr( wavefirst, wavesecond, delaymax, params.norm_method );

  resultmask = ismember(delaystested, delaylist);
  rvals = rvals(resultmask);

  result = struct();
  result.xcorr = rvals;

end


function acceptflag = helper_filterfunc( ...
  wavefirst, wavesecond, samprate, params )

  phasetargetrad = params.phasetargetdeg * pi / 180;
  accepthalfwidthrad = 0.5 * params.acceptwidthdeg * pi / 180;
  minplv = params.minplv;

  [ cmean cvar lindev ] = nlProc_calcCircularStats( wavesecond - wavefirst );
  plv = 1 - cvar;

  phasediff = cmean - phasetargetrad;
  phasediff = mod( phasediff + pi, 2*pi ) - pi;

  acceptflag = ( abs(phasediff) <= accepthalfwidthrad ) & ( plv >= minplv );

end


%
% This is the end of the file.
