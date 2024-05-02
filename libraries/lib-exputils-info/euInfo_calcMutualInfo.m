function midata = euInfo_calcMutualInfo( ...
  ftdata_first, ftdata_second, win_params, flags, ...
  bin_count_first, bin_count_second, exparams, phaseparams )

% function midata = euInfo_calcMutualInfo( ...
%   ftdata_first, ftdata_second, win_params, flags, ...
%   bin_count_first, bin_count_second, exparams, phaseparams )
%
% This calculates mututal information between pairs of channels in two
% Field Trip datasets within a series of time windows, optionally filtering
% by phase. Multiple time lags are tested for each signal pair.
%
% This uses "Chris's Entropy Library", and can optionally perform
% extrapolation to correct for small sample counts (per EXTRAPOLATION.txt
% in that library).
%
% If phase filtering is requested, then for each signal pair in each trial,
% the average of (phase second - phase first) is computed. Pairs are
% rejected if the average phase difference is outside of the specified
% range. Pairs are also rejected if the phase-lock value is below a minimum
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
% "bin_count_first" is the number of histogram bins to use when processing
%   signals from the first Field Trip data set. This can be the character
%   vector 'discrete' to auto-bin discrete-valued data.
% "bin_count_second" is the number of histogram bins to use when processing
%   signals from the second Field Trip data set. This can be the character
%   vector 'discrete' to auto-bin discrete-valued data.
% "exparams" is a structure containing extrapolation tuning parameters, per
%   EXTRAPOLATION.txt in the entropy library. If this is empty, default
%   parameters are used. This can be the character vector 'none' to disable
%   extrapolation (any non-structure argument does that).
% "phase_params" is a structure with phase acceptance information, per
%   PHASEFILTPARAMS.txt. If this is omitted or is empty, no phase filtering
%   is performed.
%
% "midata" is a structure containing time-lagged mutual information data,
%   per TIMEWINLAGDATA.txt. Relevant fields are:
%   "mutualXXX" is a matrix containing mutual information values. These are
%     nominally in the range 0..log2(bin_count), representing bit values,
%     but extrapolation may perturb values outside of that range.


% Unpack and re-pack binning and extrapolation configuration.

analysis_params = struct();

analysis_params.discrete_first = ischar(bin_count_first);
analysis_params.discrete_second = ischar(bin_count_second);

analysis_params.bins_first = bin_count_first;
analysis_params.bins_second = bin_count_second;

analysis_params.want_extrap = isstruct(exparams);
analysis_params.extrap_config = exparams;


% Figure out if we're phase-filtering.

want_phase = false;

if exist('phase_params', 'var')
  if ~isempty(phase_params)
    want_phase = ~isempty(fieldnames( phase_params ));
  end
end


% Proceed with the analysis.

if want_phase

  midata = euInfo_doTimeAndLagAnalysis( ...
    ftdata_first, ftdata_second, win_params, flags, ...
    {}, @helper_analysisfunc, analysis_params, ...
    { 'detrend', 'angle' }, @euInfo_helper_filterPhase, phase_params );

else

  midata = euInfo_doTimeAndLagAnalysis( ...
    ftdata_first, ftdata_second, win_params, flags, ...
    {}, @helper_analysisfunc, analysis_params, ...
    {}, @euInfo_helper_filterNone, struct() );

end


% Done.
end


%
% Helper Functions

function result = helper_analysisfunc( ...
  wavefirst, wavesecond, samprate, delaylist, params )

  % Package the data.

  if ~isrow(wavefirst)
    wavefirst = transpose(wavefirst);
  end
  if ~isrow(wavesecond)
    wavesecond = transpose(wavesecond);
  end

  scratchdata = [ wavefirst ; wavesecond ];


  % Get histogram bins.
  % To handle the discrete case, always generate bins here and pass them
  % via cell array.

  binlist = {};

  if params.discrete_first
    binlist{1} = cEn_getHistBinsDiscrete( wavefirst );
  else
    binlist{1} = cEn_getHistBinsEqPop( wavefirst, params.bins_first );
  end

  if params.discrete_second
    binlist{2} = cEn_getHistBinsDiscrete( wavesecond );
  else
    binlist{2} = cEn_getHistBinsEqPop( wavesecond, params.bins_second );
  end


  % Calculate time-lagged mututal information.

  if params.want_extrap
    result = cEn_calcLaggedMutualInfo( scratchdata, delaylist, binlist, ...
      params.extrap_config );
  else
    result = cEn_calcLaggedMutualInfo( scratchdata, delaylist, binlist );
  end

end


%
% This is the end of the file.
