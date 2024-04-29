function htdata = euInfo_calcHTStats( ...
  ftdata_first, ftdata_second, win_params, flags )

% function htdata = euInfo_calcHTStats( ...
%   ftdata_first, ftdata_second, win_params, flags )
%
% This calculates the coherence, power correlation, and non-Gaussian power
% correlation between pairs of signals within two datasets using the methods
% described in Hindriks 2023. This is done for several time windows, and
% averaged across trials.
%
% NOTE - Both datasets must have the same sampling rate and the same number
% of trials (trials are assumed to correspond).
%
% NOTE - This applies the Hilbert transform to generate analytic signals;
% feeding oscillating signals into it is fine. Hindriks used it on
% narrow-band LFP signals.
%
% "ftdata_first" is a ft_datatype_raw structure with the first set of trials.
% "ftdata_second" is a ft_datatype_raw structure with the second set of trials.
% "win_params" is a structure giving time window information, per
%   TIMEWINLAGSPEC.txt. Delay information is ignored.
% "flags" is a cell array containing one or more of the following character
%   vectors:
%   'avgtrials' generates data averaged across trials, per TIMEWINLAGDATA.txt.
%   'pertrial' generates per-trial data, per TIMEWINLAGDATA.txt.
%
% "htdata" is a structure with the analysis data, per TIMEWINLAGDATA.txt.
%   Relevant fields are:
%   "coherenceXXX" is a matrix indexed by (firstchan, secondchan, winidx)
%     containing coherence values (complex, magnitude between 0 and 1).
%   "powercorrelXXX" is a matrix indexed by (firstchan, secondchan, winidx)
%     containing power correlation values (real, between -1 and +1).
%   "nongaussXXX" is a matrix indexed by (firstchan, secondchan, winidx)
%     containing non-Gaussian power correlation values (real, -1 to +1).


% Force analytic signals.
flags = [ flags { 'complexanalysis' } ];

% Overwrite the delay configuration.
win_params.delay_range_ms = 0;
win_params.delay_step_ms = 1;


analysis_func = @( wavefirst, wavesecond, samprate, delaylist, params ) ...
  helper_analysisfunc( wavefirst, wavesecond, samprate, delaylist, params );

filter_func = @( wavefirst, wavesecond, samprate, params ) true;

htdata = euInfo_doTimeAndLagAnalysis( ftdata_first, ftdata_second, ...
  win_params, flags, analysis_func, struct(), filter_func, struct() );


% Done.
end


%
% Helper Functions


function result = helper_analysisfunc( ...
  wavefirst, wavesecond, samprate, delaylist, params )

  % NOTE - We're supposed to return a vector with the same length as the
  % delay list.

  [ scratchcoherence scratchcorrel scratchnongauss ] = ...
    nlProc_compareSignalsHT( wavefirst, wavesecond );

  result = struct();
  scratchvec = zeros(size(delaylist));

  scratchvec(:) = scratchcoherence;
  result.coherence = scratchvec;
  scratchvec(:) = scratchcorrel;
  result.powercorrel = scratchvec;
  scratchvec(:) = scratchnongauss;
  result.nongauss = scratchvec;

end

%
% This is the end of the file.
