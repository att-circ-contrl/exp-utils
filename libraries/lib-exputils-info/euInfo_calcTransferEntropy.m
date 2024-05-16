function tedata = euInfo_calcTransferEntropy( ...
  ftdata_dest, ftdata_src, win_params, flags, ...
  bin_count_dest, bin_count_src, exparams, phase_params )

% function tedata = euInfo_calcTransferEntropy( ...
%   ftdata_dest, ftdata_src, win_params, flags, ...
%   bin_count_dest, bin_count_src, exparams, phase_params )
%
% This calculates transfer entropy between pairs of channels in two Field
% Trip datasets within a series of time windows, optionally filtering by
% phase. Multiple time lags are tested for each signal pair.
%
% This uses "Chris's Entropy Library", and can optionally perform
% extrapolation to correct for small sample counts (per EXTRAPOLATION.txt
% in that library).
%
% If phase filtering is requested, then for each signal pair in each trial,
% the average of (phase dest - phase src) is computed. Pairs are
% rejected if the average phase difference is outside of the specified
% range. Pairs are also rejected if the phase-lock value is below a minimum
% threshold.
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
%   'spantrials' generates data by concatenating or otherwise aggregating
%     across trials, per TIMEWINLAGDATA.txt.
%   'parallel' indicates that the multithreaded implementation should be
%     used. This requires the Parallel Computing Toolbox.
% "bin_count_dest" is the number of histogram bins to use when processing
%   signals from the destination Field Trip data set. This can be the
%   character vector 'discrete' to auto-bin discrete-valued data.
% "bin_count_src" is the number of histogram bins to use when processing
%   signals from the source Field Trip data set. This can be the character
%   vector 'discrete' to auto-bin discrete-valued data.
% "exparams" is a structure containing extrapolation tuning parameters, per
%   EXTRAPOLATION.txt in the entropy library. If this is empty, default
%   parameters are used. This can be the character vector 'none' to disable
%   extrapolation (any non-structure argument does that).
% "phase_params" is a structure with phase acceptance information, per
%   PHASEFILTPARAMS.txt. If this is omitted or is empty, no phase filtering
%   is performed.
%
% "tedata" is a structure containing transfer entropy data, per
%   TIMEWINLAGDATA.txt. Relevant fields are:
%   "transferXXX" is a matrix containing mutual information values. These
%     are nominally in the range 0..log2(bin_count), representing bit
%     values, but extrapolation may perturb values outside of that range.


% Unpack and re-pack binning and extrapolation configuration.
% Parallel processing switch goes into this structure too.

analysis_params = struct();

analysis_params.discrete_dest = ischar(bin_count_dest);
analysis_params.discrete_src = ischar(bin_count_src);

analysis_params.bins_dest = bin_count_dest;
analysis_params.bins_src = bin_count_src;

analysis_params.want_extrap = isstruct(exparams);
analysis_params.extrap_config = exparams;

analysis_params.want_parallel = ismember('parallel', flags);


% Figure out if we're phase-filtering.

want_phase = false;

if exist('phase_params', 'var')
  if ~isempty(phase_params)
    want_phase = ~isempty(fieldnames( phase_params ));
  end
end


% Proceed with the analysis.

if want_phase
  tedata = euInfo_doTimeAndLagAnalysis( ...
    ftdata_dest, ftdata_src, win_params, flags, ...
    {}, @euInfo_helper_analyzeTransfer, analysis_params, ...
    { 'detrend', 'angle' }, @euInfo_helper_filterPhase, phase_params );
else
  tedata = euInfo_doTimeAndLagAnalysis( ...
    ftdata_dest, ftdata_src, win_params, flags, ...
    {}, @euInfo_helper_analyzeTransfer, analysis_params, ...
    {}, @euInfo_helper_filterNone, struct() );
end


% Done.
end


%
% This is the end of the file.
