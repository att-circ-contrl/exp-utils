function midata = euInfo_calcMutualInfo( ...
  ftdata_dest, ftdata_src, win_params, flags, ...
  bin_count_dest, bin_count_src, exparams, phaseparams )

% function midata = euInfo_calcMutualInfo( ...
%   ftdata_dest, ftdata_src, win_params, flags, ...
%   bin_count_dest, bin_count_src, exparams, phaseparams )
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
% "midata" is a structure containing time-lagged mutual information data,
%   per TIMEWINLAGDATA.txt. Relevant fields are:
%   "mutualXXX" is a matrix containing mutual information values. These are
%     nominally in the range 0..log2(bin_count), representing bit values,
%     but extrapolation may perturb values outside of that range.


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

% FIXME - Diagnostics
if false
disp(analysis_params);
disp(want_phase);
disp(win_params);
disp(sprintf( 'xx %d windows, %d trials, %d x %d chans.', ...
length(win_params.timelist_ms), length(ftdata_dest.time), ...
length(ftdata_dest.label), length(ftdata_src.label) ));
end

% Proceed with the analysis.

if want_phase

% FIXME - Diagnostics.
disp('xx Computing mutual information with phase bins.');
  midata = euInfo_doTimeAndLagAnalysis( ...
    ftdata_dest, ftdata_src, win_params, flags, ...
    {}, @euInfo_helper_analyzeMutual, analysis_params, ...
    { 'detrend', 'angle' }, @euInfo_helper_filterPhase, phase_params );

else

% FIXME - Compare with entropy library FT function.
if true
% FIXME - Diagnostics.
disp('xx Computing mutual information.');
  midata = euInfo_doTimeAndLagAnalysis( ...
    ftdata_dest, ftdata_src, win_params, flags, ...
    {}, @euInfo_helper_analyzeMutual, analysis_params, ...
    {}, @euInfo_helper_filterNone, struct() );
else
  % Entropy library kludge.
  % FIXME - No trialwise output and no variance!

  samprate = 1 / mean(diff( ftdata_dest.time{1} ));

  delaylist_samps = euInfo_helper_getDelaySamps( ...
    samprate, win_params.delay_range_ms, win_params.delay_step_ms );
  delaylist_ms = 1000 * delaylist_samps / samprate;

  delaycount = length(delaylist_samps);

  winranges_dest = euInfo_helper_getWindowSamps ( samprate, ...
    win_params.time_window_ms, win_params.timelist_ms, ftdata_dest.time );
  winranges_src = euInfo_helper_getWindowSamps ( samprate, ...
    win_params.time_window_ms, win_params.timelist_ms, ftdata_src.time );

  chancount_dest = length(ftdata_dest.label);
  chancount_src = length(ftdata_src.label);

  wincount = length(win_params.timelist_ms);

  binlist = [ analysis_params.bins_dest, analysis_params.bins_src ];

  mimatrix = nan(chancount_dest, chancount_src, wincount, delaycount);

  % FIXME - This really is just duplicating a lot of doTimeAndLag.
  for cidxdest = 1:chancount_dest
    datadest = cEn_ftHelperChannelToMatrix( ftdata_dest, cidxdest );

    for cidxsrc = 1:chancount_src

      datasrc = cEn_ftHelperChannelToMatrix( ftdata_src, cidxsrc );

      for widx = 1:wincount

        % FIXME - Blithely assume that trial 1's mask works for all trials.
        datalist = ...
          [ { datadest(:,winranges_dest{1,widx}) }, ...
            { datasrc(:,winranges_src{1,widx}) } ];

% FIXME - Diagnostics.
%tic;
        if analysis_params.want_extrap
          milist = cEn_calcLaggedMutualInfo( ...
            datalist, delaylist_samps, binlist, exparams );
        else
          milist = cEn_calcLaggedMutualInfo( ...
            datalist, delaylist_samps, binlist );
        end
% FIXME - Diagnostics.
%durstring = nlUtil_makePrettyTime(toc);
%disp([ 'xx Probe completed in ' durstring '.' ]);

        mimatrix(cidxdest, cidxsrc, widx, :) = milist;

      end

    end

  end

  midata = struct();
  midata.destchans = ftdata_dest.label;
  midata.srcchans = ftdata_src.label;
  midata.delaylist_ms = delaylist_ms;
  midata.windowlist_ms = win_params.timelist_ms;
  midata.windowsize_ms = win_params.time_window_ms;

  midata.mutualavg = mimatrix;
  midata.mutualcount = ones(size(mimatrix));
  midata.mutualvar = zeros(size(mimatrix));
  nanmask = isnan(mimatrix);
  midata.mutualcount(nanmask) = 0;
  midata.mutualvar(nanmask) = nan;
end

end


% Done.
end


%
% Helper Functions

function result = helper_analysisfunc( ...
  wavedest, wavesrc, samprate, delaylist, params )

  % Package the data.

  if ~isrow(wavedest)
    wavedest = transpose(wavedest);
  end
  if ~isrow(wavesrc)
    wavesrc = transpose(wavesrc);
  end

  scratchdata = [ wavedest ; wavesrc ];


  % Get histogram bins.
  % To handle the discrete case, always generate bins here and pass them
  % via cell array.

  binlist = {};

  if params.discrete_dest
    binlist{1} = cEn_getHistBinsDiscrete( wavedest );
  else
    binlist{1} = cEn_getHistBinsEqPop( wavedest, params.bins_dest );
  end

  if params.discrete_src
    binlist{2} = cEn_getHistBinsDiscrete( wavesrc );
  else
    binlist{2} = cEn_getHistBinsEqPop( wavesrc, params.bins_src );
  end


  % Calculate time-lagged mututal information.

% FIXME - Diagnostics.
%tic;
  if params.want_extrap
    mvals = cEn_calcLaggedMutualInfo( scratchdata, delaylist, binlist, ...
      params.extrap_config );
  else
    mvals = cEn_calcLaggedMutualInfo( scratchdata, delaylist, binlist );
  end
% FIXME - Diagnostics.
%durstring = nlUtil_makePrettyTime(toc);
%disp([ 'xx Probe completed in ' durstring '.' ]);


  % Store this in an appropriately-named field.
  result = struct();
  result.mutual = mvals;

end


%
% This is the end of the file.
