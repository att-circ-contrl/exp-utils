function phasedata = euInfo_calcTrialPhaseStats( ...
  ftdata_dest, ftdata_src, win_params, flags )

% function phasedata = euInfo_calcTrialPhaseStats( ...
%   ftdata_dest, ftdata_src, win_params, flags )
%
% This calculates phase difference and phase lock values between pairs of
% signals within two datasets, as a function of time.
%
% NOTE - Both datasets must have the same sampling rate and the same number
% of trials (trials are assumed to correspond).
%
% NOTE - This applies the Hilbert transform to generate analytic signals.
% This will give poor estimates of phase for wideband signals that aren't
% dominated by a clear oscillation.
%
% "ftdata_dest" is a ft_datatype_raw structure with trial data for the
%   putative destination channels.
% "ftdata_src" is a ft_datatype_raw structure with trial data for the
%   putative source channels.
% "win_params" is a structure giving time window information, per
%   TIMEWINLAGSPEC.txt. Delay information is ignored.
% "flags" is a cell array containing one or more of the following character
%   vectors:
%   'avgtrials' generates data averaged across trials, per TIMEWINLAGDATA.txt.
%   'pertrial' generates per-trial data, per TIMEWINLAGDATA.txt.
%
% "phasedata" is a structure with the phase difference and PLVs, per
%   TIMEWINLAGDATA.txt. Relevant fields are:
%   "phasediffXXX" is a matrix containing the circular means of
%     (phase2 - phase1).
%   "plvXXX" is a matrix containing the phase lock values between pairs of
%     channels. This is equal to 1 - circvar(phase2 - phase1).


% Overwrite the delay configuration.
win_params.delay_range_ms = 0;
win_params.delay_step_ms = 1;


% We want to analyze phase angles.
% Detrend to ensure that these are sane.

phasedata = euInfo_doTimeAndLagAnalysis( ...
  ftdata_dest, ftdata_src, win_params, flags, ...
  { 'detrend', 'angle' }, @helper_analysisfunc, struct(), ...
  {}, @euInfo_helper_filterNone, struct() );


% Done.
end


%
% Helper Functions


function result = helper_analysisfunc( ...
  wavedest, wavesrc, samprate, delaylist, params )

  % NOTE - We're supposed to return a vector with the same length as the
  % delay list.

  [ cmean cvar lindev ] = nlProc_calcCircularStats( wavedest - wavesrc );
  plv = 1 - cvar;

  result = struct();
  scratchvec = zeros(size(delaylist));

  scratchvec(:) = cmean;
  result.phasediff = scratchvec;
  scratchvec(:) = plv;
  result.plv = scratchvec;

end


%
% This is the end of the file.
