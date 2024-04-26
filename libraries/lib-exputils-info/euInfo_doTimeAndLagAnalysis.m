function winlagdata = euChris_doTimeAndLagAnalysis( ...
  ftdata_first, ftdata_second, winlagparams, trialcalcs, ...
  analysis_func, analysis_params, filter_func, filter_params )

% function winlagdata = euChris_doTimeAndLagAnalysis( ...
%   ftdata_first, ftdata_second, winlagparams, trialcalcs, ...
%   analysis_func, analysis_params, filter_func, filter_params )
%
% This compares two Field Trip datasets within a series of time windows,
% calculating some measure such as cross-correlation or transfer entropy
% that is evaluated for several time lags.
%
% Results may be stored per trial, or averaged across trials, or both.
%
% For each trial and time window, a filter function is applied to determine
% whether that window of that trial is accepted. Windows that are rejected
% have NaN stored in per-trial data and do not contribute to the average
% across trials.
%
% NOTE - Both datasets must have the same sampling rate and the same number
% of trials (trials are assumed to correspond).
%
% "ftdata_first" is a ft_datatype_raw structure with the first set of trials.
% "ftdata_second" is a ft_datatype_raw structure with the second set of trials.
% "winlagparams" is a structure giving time window and time lag information,
%   per TIMEWINLAGSPEC.txt.
% "trialcalcs" is a cell array containing zero or more of the following
%   character vectors:
%   'avgtrials' generates data averaged across trials, per TIMEWINLAGDATA.txt.
%   'pertrial' generates per-trial data, per TIMEWINLAGDATA.txt.
% "analysis_func" is an analysis function handle, per TIMEWINLAGFUNCS.
% "analysis_params" is a tuning parameter structure to be passed to the
%   analysis function handle.
% "filter_func" is an acceptance filter function handle, per TIMEWINLAGFUNCS.
% "filter_params" is a tuning parameter structure to be passed to the
%   acceptance filter function handle.
%
% "winlagdata" is a structure containing aggregated analysis data, per
%   TIMEWINLAGDATA.txt.


% Initialize.
winlagdata = struct([]);


% Check for bail-out conditions.

if isempty(ftdata_first.label) || isempty(ftdata_first.time) ...
  || isempty(ftdata_second.label) || isempty(ftdata_second.time)
  return;
end


%
% Get metadata.

% Behavior.

want_avg = ismember('avgtrials', trialcalcs);
want_pertrial = ismember('pertrial', trialcalcs);


% Geometry.

trialcount = length(ftdata_first.time);

chancount_first = length(ftdata_first.label);
chancount_second = length(ftdata_second.label);


% Sampling rate.

samprate = 1 / mean(diff( ftdata_first.time{1} ));


% Window geometry and locations.

winrad_samps = round( samprate * winlagparams.time_window_ms * 0.001 * 0.5 );

wintimes_sec = winlagparams.timelist_ms * 0.001;
wincount = length(wintimes_sec);


% Delay values.

delaymin_samps = min( winlagparams.delay_range_ms );
delaymin_samps = round( samprate * delaymin_samps * 0.001 );

delaymax_samps = max( winlagparams.delay_range_ms );
delaymax_samps = round( samprate * delaymax_samps * 0.001 );

delaystep_samps = round( samprate * winlagparams.delay_step_ms * 0.001 );
delaystep_samps = max( 1, delaystepsamps );

delaypivot = round( 0.5 * (delaymin_samps + delaymax_samps) );
% If a delay of zero is in range, make sure we use it as one of the delays.
if (delaymin_samps <= 0) & (delaymax_samps >= 0)
  delaypivot = 0;
end

delaymin_samps = delaymin_samps - delaypivot;
delaymin_samps = round(delaymin_samps / delaystep_samps);
delaymin_samps = (delaymin_samps * delaystep_samps) + delaypivot;

delaymax_samps = delaymax_samps - delaypivot;
delaymax_samps = round(delaymax_samps / delaystep_samps);
delaymax_samps = (delaymax_samps * delaystep_samps) + delaypivot;

delaylist_samps = [ delaymin_samps : delaystep_samps : delaymax_samps ];

delaycount = length(delaylist_samps);



%
% Precompute window sample ranges.

winrangesfirst = {};
winrangessecond = {};

for trialidx = 1:trialcount
  thistimefirst = ftdata_first.time{trialidx};
  thistimesecond = ftdata_second.time{trialidx};

  for widx = 1:wincount

    % Figure out window position. The timestamp won't match perfectly.
    thiswintime = wintimes_sec(widx);

    winsampfirst = thistimefirst - thiswintime;
    winsampfirst = min(find( winsampfirst >= 0 ));

    winsampsecond = thistimesecond - thiswintime;
    winsampsecond = min(find( winsampsecond >= 0 ));

    winrangesfirst{trialidx,widx} = ...
      [ (winsampfirst-winrad_samps):(winsampfirst+winrad_samps) ];
    winrangessecond{trialidx,widx} = ...
      [ (winsampsecond-winrad_samps):(winsampsecond+winrad_samps) ];

  end
end



%
% Precompute analytic signals.

% FIXME - We should have flags for whether this is needed for _either_
% function.

ftdata_first_hilbert = ftdata_first;
ftdata_second_hilbert = ftdata_second;

for tidx = 1:trialcount
  thistrial = ftdata_first_hilbert.trial{tidx};
  for cidx = 1:chancount_first
    thistrial(cidx,: = hilbert(thistrial(cidx,:));
  end
  ftdata_first_hilbert.trial{tidx} = thistrial;

  thistrial = ftdata_second_hilbert.trial{tidx};
  for cidx = 1:chancount_second
    thistrial(cidx,: = hilbert(thistrial(cidx,:));
  end
  ftdata_second_hilbert.trial{tidx} = thistrial;
end



%
% Compute cross-correlations and average across trials.

% FIXME - Stopped here.

% The outer loop is window index, so that we can hold all cross-correlations
% for a given window in memory (to compute the variance).

xcorravg = zeros([ chancount_first chancount_second wincount delaycount ]);
xcorrcount = zeros(size(xcorravg));
xcorrvar = zeros(size(xcorravg));;

for widx = 1:wincount

  % First pass: Store the raw cross-correlations for this window.
  % Anything that doesn't pass the phase test gets left as NaN.

  xcorrbytrial = ...
    nan([ chancount_first chancount_second trialcount delaycount ]);

  for trialidx = 1:trialcount

    % Get raw data.
    % NOTE - Trials may have NaN regions, but those usually don't overlap
    % the test windows.

    thisdatafirst = ftdata_first.trial{trialidx};
    thisdatasecond = ftdata_second.trial{trialidx};


    % Extract data window contents.

    % NOTE - We may sometimes get NaN data in here. The relevant cross
    % correlations will also be NaN.
    % Detrending and mean subtraction will also make the whole thing NaN,
    % but that's fine. Using 'omitnan' would still give NaN cross-correlation.

    windatafirst = thisdatafirst(:,winrangesfirst{trialidx,widx});
    windatasecond = thisdatasecond(:,winrangessecond{trialidx,widx});


    % Get a phase mask for this trial and window.

    thisphase = phasediffs(:,:,trialidx,widx);
    thisplv = phaseplvs(:,:,trialidx,widx);

    thisphase = thisphase - phasetargetrad;
    thisphase = mod( thisphase + pi, 2*pi ) - pi;
    phasemask = ( abs(thisphase) <= phaseradiusrad );

    plvmask = (thisplv >= minplv);
    phasemask = phasemask & plvmask;


    % Do the cross-correlations.
    % Apply the phase test before doing any calculations (even detrending).

    for cidxfirst = 1:chancount_first
      for cidxsecond = 1:chancount_second

        % Check the phase mask before doing anything.
        if phasemask(cidxfirst,cidxsecond)
          wavefirst = windatafirst(cidxfirst,:);

          if strcmp('detrend', detrend_method)
            wavefirst = detrend(wavefirst);
          elseif strcmp('demean', detrend_method)
            wavefirst = wavefirst - mean(wavefirst);
          end

          wavesecond = windatasecond(cidxsecond,:);

          if strcmp('detrend', detrend_method)
            wavesecond = detrend(wavesecond);
          elseif strcmp('demean', detrend_method)
            wavesecond = wavesecond - mean(wavesecond);
          end

          % Calculate cross-correlations.
          rvals = xcorr( wavefirst, wavesecond, delaymax_samps, ...
            xcorr_params.xcorr_norm_method );
          xcorrbytrial(cidxfirst,cidxsecond,trialidx,1:delaycount) = rvals;
        end

      end
    end

  end


  % Second pass: Get the count and the average.

  winxcorravg = zeros([ chancount_first chancount_second delaycount ]);
  winxcorrcount = zeros(size(winxcorravg));

  validmask = ...
    false([ chancount_first chancount_second trialcount delaycount ]);

  for trialidx = 1:trialcount
    for delayidx = 1:delaycount
      thisxcorr = xcorrbytrial(:,:,trialidx,delayidx);

      magmask = ( abs(thisxcorr) >= xcminmag );
      nanmask = ~isnan(thisxcorr);

      thismask = magmask & nanmask;

      validmask(:,:,trialidx,delayidx) = thismask;

      avgslice = winxcorravg(:,:,delayidx);
      avgslice(thismask) = avgslice(thismask) + thisxcorr(thismask);
      winxcorravg(:,:,delayidx) = avgslice;

      countslice = winxcorrcount(:,:,delayidx);
      countslice = countslice + thismask;
      winxcorrcount(:,:,delayidx) = countslice;
    end
  end

  winxcorravg = winxcorravg ./ winxcorrcount;


  % Third pass: Get the variance.

  winxcorrvar = zeros(size(winxcorravg));

  for trialidx = 1:trialcount
    for delayidx = 1:delaycount
      % Get (X-avg)^2.
      thisxcorr = xcorrbytrial(:,:,trialidx,delayidx);
      thisxcorr = thisxcorr - winxcorravg(:,:,delayidx);
      thisxcorr = thisxcorr .* thisxcorr;

      thismask = validmask(:,:,trialidx,delayidx);

      varslice = winxcorrvar(:,:,delayidx);
      varslice(thismask) = varslice(thismask) + thisxcorr(thismask);
      winxcorrvar(:,:,delayidx) = varslice;
    end
  end

  winxcorrvar = winxcorrvar ./ winxcorrcount;


  % Update global statistics.

  for delayidx = 1:delaycount
    xcorravg(:,:,widx,delayidx) = winxcorravg(:,:,delayidx);
    xcorrvar(:,:,widx,delayidx) = winxcorrvar(:,:,delayidx);
    xcorrcount(:,:,widx,delayidx) = winxcorrcount(:,:,delayidx);
  end
end



%
% Build the return structure.

winlagdata = struct();

winlagdata.firstchans = ftdata_first.label;
winlagdata.secondchans = ftdata_second.label;

winlagdata.delaylist_ms = delaylist_samps * 1000 / samprate;

xcorrdata.windowlist_ms = wintimes_sec * 1000;

% FIXME - Data copying goes here.



% Done.
end


%
% This is the end of the file.
