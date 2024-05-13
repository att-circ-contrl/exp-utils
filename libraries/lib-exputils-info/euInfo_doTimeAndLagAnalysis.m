function winlagdata = euInfo_doTimeAndLagAnalysis( ...
  ftdata_dest, ftdata_src, winlagparams, flags, ...
  analysis_preproc, analysis_func, analysis_params, ...
  filter_preproc, filter_func, filter_params )

% function winlagdata = euInfo_doTimeAndLagAnalysis( ...
%   ftdata_dest, ftdata_src, winlagparams, flags, ...
%   analysis_preproc, analysis_func, analysis_params, ...
%   filter_preproc, filter_func, filter_params )
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
% "ftdata_dest" is a ft_datatype_raw structure with trial data for the
%   putative destination channels.
% "ftdata_src" is a ft_datatype_raw structure with trial data for the
%   putative source channels.
% "winlagparams" is a structure giving time window and time lag information,
%   per TIMEWINLAGSPEC.txt.
% "flags" is a cell array containing zero or more of the following character
%   vectors:
%   'avgtrials' generates data averaged across trials, per TIMEWINLAGDATA.txt.
%   'pertrial' generates per-trial data, per TIMEWINLAGDATA.txt.
%   'spantrials' generates data by concatenating or otherwise aggregating
%     across trials, per TIMEWINLAGDATA.txt.
% "analysis_preproc" is a cell array containing zero or more character vectors
%   indicating what preprocessing to perform on signals sent to the analysis
%   function. Preprocessing happens before time-windowing:
%   'zeromean' subtracts the mean of each signal.
%   'detrend' detrends each signal.
%   'hilbert' generates a complex-valued analytic signal for each signal.
%   'angle' takes the instantaneous phase (in radians) of the analytic signal.
% "analysis_func" is an analysis function handle, per TIMEWINLAGFUNCS.
% "analysis_params" is a tuning parameter structure to be passed to the
%   analysis function handle.
% "filter_preproc" is a cell array containing zero or more character vectors
%   indicating what preprocessing to perform on signals sent the filter
%   function. Switches are the same as with "analysis_preproc".
% "filter_func" is an acceptance filter function handle, per TIMEWINLAGFUNCS.
% "filter_params" is a tuning parameter structure to be passed to the
%   acceptance filter function handle.
%
% "winlagdata" is a structure containing aggregated analysis data, per
%   TIMEWINLAGDATA.txt.


% Initialize.
winlagdata = struct();


% Check for bail-out conditions.

if isempty(ftdata_dest.label) || isempty(ftdata_dest.time) ...
  || isempty(ftdata_src.label) || isempty(ftdata_src.time)
  return;
end


%
% Get metadata.

% Behavior.

want_avg = ismember('avgtrials', flags);
want_pertrial = ismember('pertrial', flags);
want_spantrials = ismember('spantrials', flags);


% Geometry.

trialcount = length(ftdata_dest.time);

chancount_dest = length(ftdata_dest.label);
chancount_src = length(ftdata_src.label);


% Sampling rate.

samprate = 1 / mean(diff( ftdata_dest.time{1} ));


% Delay values.

delaylist_samps = euInfo_helper_getDelaySamps( ...
  samprate, winlagparams.delay_range_ms, winlagparams.delay_step_ms );

delaycount = length(delaylist_samps);


% Precompute window sample ranges.

wincount = length(winlagparams.timelist_ms);

winrangesdest = euInfo_helper_getWindowSamps( samprate, ...
  winlagparams.time_window_ms, winlagparams.timelist_ms, ftdata_dest.time );
winrangessrc = euInfo_helper_getWindowSamps( samprate, ...
  winlagparams.time_window_ms, winlagparams.timelist_ms, ftdata_src.time );



%
% Store metadata.

winlagdata.destchans = ftdata_dest.label;
winlagdata.srcchans = ftdata_src.label;

winlagdata.delaylist_ms = delaylist_samps * 1000 / samprate;

winlagdata.windowlist_ms = winlagparams.timelist_ms;
winlagdata.windowsize_ms = winlagparams.time_window_ms;



%
% Perform any ahead-of-time signal processing requested.

trialdata_dest_analysis = ...
  helper_doPreProc( ftdata_dest.trial, analysis_preproc );
trialdata_src_analysis = ...
  helper_doPreProc( ftdata_src.trial, analysis_preproc );

trialdata_dest_filter = ...
  helper_doPreProc( ftdata_dest.trial, filter_preproc );
trialdata_src_filter = ...
  helper_doPreProc( ftdata_src.trial, filter_preproc );



%
% Compute per-trial analysis output and average across trials.

% Make templates for easier initialization.

if want_avg
  % Statistics in the absence of data are NaN, not zero.
  templateavg = ...
    nan([ chancount_dest chancount_src wincount delaycount ]);

  % Scratch variables for computing statistics do start at zero.
  templateonewindowavg = ...
    zeros([ chancount_dest chancount_src delaycount ]);
end

if want_pertrial
  % Data that doesn't pass the filter is NaN, not zero.
  templatepertrial = ...
    nan([ chancount_dest chancount_src trialcount wincount delaycount ]);
end

% Data that doesn't pass the filter is NaN, not zero.
templateonewindow = ...
  nan([ chancount_dest chancount_src trialcount delaycount ]);


% Iterate.

% The outer loop is window index, so that we can hold all results for a
% given window in memory (to compute the variance).

need_global_init = true;
resultfields = {};

for widx = 1:wincount

  % First pass: Store the raw results for this window.
  % Anything that doesn't pass the filter function gets left as NaN.

  need_local_init = true;
  thiswinresults = struct();

  for trialidx = 1:trialcount

    % Get raw data.
    % NOTE - Trials may have NaN regions, but those usually don't overlap
    % the test windows.

    thisdatadest_an = trialdata_dest_analysis{trialidx};
    thisdatasrc_an = trialdata_src_analysis{trialidx};

    thisdatadest_filt = trialdata_dest_filter{trialidx};
    thisdatasrc_filt = trialdata_src_filter{trialidx};


    % Extract data window contents.

    % NOTE - We may sometimes get NaN data in here. The relevant results
    % will also be NaN.

    windatadest_an = thisdatadest_an(:,winrangesdest{trialidx,widx});
    windatasrc_an = thisdatasrc_an(:,winrangessrc{trialidx,widx});

    windatadest_filt = thisdatadest_filt(:,winrangesdest{trialidx,widx});
    windatasrc_filt = thisdatasrc_filt(:,winrangessrc{trialidx,widx});


    % Iterate channels, storing results for this trial.
    % Check the filter function before performing analysis on any pair.

    for cidxdest = 1:chancount_dest
      for cidxsrc = 1:chancount_src

        wavedest = windatadest_filt(cidxdest,:);
        wavesrc = windatasrc_filt(cidxsrc,:);

        filteraccept = ...
          filter_func( wavedest, wavesrc, samprate, filter_params );

        if filteraccept

          wavedest = windatadest_an(cidxdest,:);
          wavesrc = windatasrc_an(cidxsrc,:);

          thisresult = analysis_func( ...
            wavedest, wavesrc, samprate, ...
            delaylist_samps, analysis_params );


          % Handle deferred initialization, if it hasn't been done yet.

          if need_global_init
            need_global_init = false;

            resultfields = fieldnames(thisresult);

            for fidx = 1:length(resultfields)
              thisfield = resultfields{fidx};
              if want_avg
                winlagdata.([ thisfield 'avg' ]) = templateavg;
                winlagdata.([ thisfield 'count' ]) = templateavg;
                winlagdata.([ thisfield 'var' ]) = templateavg;
              end
              if want_pertrial
                winlagdata.([ thisfield 'trials' ]) = templatepertrial;
              end
            end
          end

          if need_local_init
            need_local_init = false;

            for fidx = 1:length(resultfields)
              thisfield = resultfields{fidx};
              thiswinresults.( thisfield ) = templateonewindow;
            end
          end


          % Store this set of results.

          for fidx = 1:length(resultfields)
            thisfield = resultfields{fidx};

            scratch = thiswinresults.( thisfield );
            scratch(cidxdest,cidxsrc,trialidx,1:delaycount) = ...
              thisresult.( thisfield );
            thiswinresults.( thisfield ) = scratch;

            if want_pertrial
              scratch = winlagdata.([ thisfield 'trials' ]);
              scratch(cidxdest,cidxsrc,trialidx,widx,1:delaycount) = ...
                thisresult.( thisfield );
              winlagdata.([ thisfield 'trials' ]) = scratch;
            end
          end

        end

      end
    end

  end


  % Second pass: Compute average statistics, if desired.

  if want_avg
    for fidx = 1:length(resultfields)

      thisfield = resultfields{fidx};

      winavg = templateonewindowavg;
      wincount = templateonewindowavg;
      winvar = templateonewindowavg;

      thisresult = thiswinresults.( thisfield );
      validmask = ~isnan(thisresult);


      % Get the count and the average.
      % Ignore NaN entries.

      for trialidx = 1:trialcount
        for delayidx = 1:delaycount
          thisresultslice = thisresult(:,:,trialidx,delayidx);
          thisvalid = validmask(:,:,trialidx,delayidx);

          avgslice = winavg(:,:,delayidx);
          avgslice(thisvalid) = ...
            avgslice(thisvalid) + thisresultslice(thisvalid);
          winavg(:,:,delayidx) = avgslice;

          countslice = wincount(:,:,delayidx);
          countslice = countslice + thisvalid;
          wincount(:,:,delayidx) = countslice;
        end
      end

      winavg = winavg ./ wincount;


      % Get the variance.

      for trialidx = 1:trialcount
        for delayidx = 1:delaycount
          thisresultslice = thisresult(:,:,trialidx,delayidx);
          thisvalid = validmask(:,:,trialidx,delayidx);

          % Get (X-avg)^2.
          thisresultslice = thisresultslice - winavg(:,:,delayidx);
          thisresultslice = thisresultslice .* thisresultslice;

          varslice = winvar(:,:,delayidx);
          varslice(thisvalid) = ...
            varslice(thisvalid) + thisresultslice(thisvalid);
          winvar(:,:,delayidx) = varslice;
        end
      end

      winvar = winvar ./ wincount;


      % Update global statistics.

      scratchavg = winlagdata.([ thisfield 'avg' ]);
      scratchvar = winlagdata.([ thisfield 'var' ]);
      scratchcount = winlagdata.([ thisfield 'count' ]);

      for delayidx = 1:delaycount
        scratchavg(:,:,widx,delayidx) = winavg(:,:,delayidx);
        scratchvar(:,:,widx,delayidx) = winvar(:,:,delayidx);
        scratchcount(:,:,widx,delayidx) = wincount(:,:,delayidx);
      end

      winlagdata.([ thisfield 'avg' ]) = scratchavg;
      winlagdata.([ thisfield 'var' ]) = scratchvar;
      winlagdata.([ thisfield 'count' ]) = scratchcount;

    end
  end
end



% Done.
end



%
% Helper Functions


function newtrials = helper_doPreProc( oldtrials, preprocflags )

  want_detrend = ismember('detrend', preprocflags);
  want_zeromean = ismember('zeromean', preprocflags);
  want_hilbert = ismember('hilbert', preprocflags);
  want_angle = ismember('angle', preprocflags);


  trialcount = length(oldtrials);
  chancount = 0;
  if ~isempty(oldtrials)
    chancount = size(oldtrials{1},1);
  end


  newtrials = oldtrials;

  for tidx = 1:trialcount
    thistrial = newtrials{tidx};

    for cidx = 1:chancount
      thiswave = thistrial(cidx,:);

      % Interpolate NaNs, so that detrending and Hilbert work.
      nanmask = isnan(thiswave);
      thiswave = nlProc_fillNaN(thiswave);

      if want_detrend
        thiswave = detrend(thiswave);
      elseif want_zeromean
        thiswave = thiswave - mean(thiswave);
      end

      if want_hilbert || want_angle
        thiswave = hilbert(thiswave);
      end

      if want_angle
        thiswave = angle(thiswave);
      end

      % Restore NaNs that we interpolated.
      thiswave(nanmask) = NaN;

      thistrial(cidx,:) = thiswave;
    end

    newtrials{tidx} = thistrial;
  end

end


%
% This is the end of the file.
