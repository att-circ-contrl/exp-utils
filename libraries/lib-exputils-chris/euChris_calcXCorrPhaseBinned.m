function xcorrdata = euChris_calcXCorrPhaseBinned( ...
  ftdata_first, ftdata_second, xcorr_params, detrend_method, ...
  phasebintarget, phasebinwidth, xcminmag )

% function xcorrdata = euChris_calcXCorrPhaseBinned( ...
%   ftdata_first, ftdata_second, xcorr_params, detrend_method, ...
%   phasebintarget, phasebinwidth, xcminmag )
%
% This calculates cross-correlations between two Field Trip datasets within
% a series of time windows, averaged across trials.
%
% For each trial, the average of (phase_first - phase_second) is computed,
% and trials are rejected if the phase is outside of the specified range.
% Cross-correlation values are also rejected if they are below the specified
% magnitude.
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
% "phasebintarget" is the phase at the middle of the desired bin, in degrees.
% "phasebinwidth" is the width of the desired phase bin, in degrees.
% "xcminmag" is the minimum absolute value of the cross-correlation required
%   for that cross-correlation measurement to contribute to an average.
%
% "xcorrdata" is a structure containing cross-correlation data, per
%   CHRISXCORRDATA.txt.


% FIXME - Break out the common bits into a helper and make this and htstats
% call it.


% Initialize.
xcorrdata = struct([]);


% Check for bail-out conditions.

if isempty(ftdata_first.label) || isempty(ftdata_first.time) ...
  || isempty(ftdata_second.label) || isempty(ftdata_second.time)
  return;
end


%
% Get metadata.

% Geometry.

trialcount = length(ftdata_first.time);

chancount_first = length(ftdata_first.label);
chancount_second = length(ftdata_second.label);


% Phase targets.
phasetargetrad = phasebintarget * pi / 180;
phaseradiusrad = 0.5 * phasebinwidth * pi / 180;


% Sampling rate and various derived values.

samprate = 1 / mean(diff( ftdata_first.time{1} ));

delaymax_samps = max(abs( xcorr_params.xcorr_range_ms ));
delaymax_samps = round( samprate * delaymax_samps * 0.001 );

delaycount = 1 + delaymax_samps + delaymax_samps;

winrad_samps = round( samprate * xcorr_params.time_window_ms * 0.001 * 0.5 );

wintimes_sec = xcorr_params.timelist_ms * 0.001;
wincount = length(wintimes_sec);


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
% Precompute phase differences.

% We want to use the entire trial time span to do this, to avoid windowing
% artifacts with the Hilbert transform.

phasediffs = [];

for trialidx = 1:trialcount

  % Get raw data.

  thisdatafirst = ftdata_first.trial{trialidx};
  thisdatasecond = ftdata_second.trial{trialidx};

  thisanglefirst = NaN(size(thisdatafirst));
  thisanglesecond = NaN(size(thisdatasecond));

  for cidx = 1:chancount_first
    thiswave = thisdatafirst(cidx,:);

    % Interpolate NaNs, so that we can use the Hilbert transform.
    thiswave = nlProc_fillNaN( thiswave );
    % Make this zero-mean and give it sane endpoints.
    thiswave = detrend(thiswave);

    thisanglefirst(cidx,:) = angle(hilbert( thiswave ));
  end

  for cidx = 1:chancount_second
    thiswave = thisanglesecond(cidx,:);

    % Interpolate NaNs, so that we can use the Hilbert transform.
    thiswave = nlProc_fillNaN( thiswave );
    % Make this zero-mean and give it sane endpoints.
    thiswave = detrend(thiswave);

    thisanglesecond(cidx,:) = angle(hilbert( thiswave ));
  end

  % Walk through windows, computing relative phase.
  % NOTE - Remember that we're in circular coordinates.

  for widx = 1:wincount
    for cidxfirst = 1:chancount_first
      for cidxsecond = 1:chancount_second
        thisphasefirst = ...
          thisanglefirst( cidxfirst, winrangesfirst{trialidx,widx} );
        thisphasesecond = ...
          thisanglesecond( cidxsecond, winrangessecond{trialidx,widx} );

        thisphasediff = thisphasesecond - thisphasefirst;

        % Use the circular mean.
        % The linear mean will be contaminated by outliers if there isn't a
        % strong phase relationship, even with wrapping to +/- pi.

        [ cmean cvar lindev ] = nlProc_calcCircularStats( thisphasediff );

        phasediffs(cidxfirst,cidxsecond,trialidx,widx) = cmean;
      end
    end
  end

end


%
% Compute cross-correlations and average across trials.

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

    thisphase = thisphase - phasetargetrad;
    thisphase = mod( thisphase + pi, 2*pi ) - pi;
    phasemask = ( abs(thisphase) <= phaseradiusrad );


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

xcorrdata = struct();

xcorrdata.firstchans = ftdata_first.label;
xcorrdata.secondchans = ftdata_second.label;

scratch = [ (-delaymax_samps) : delaymax_samps ];
xcorrdata.delaylist_ms = 1000 * scratch / samprate;

xcorrdata.windowlist_ms = xcorr_params.timelist_ms;

xcorrdata.xcorravg = xcorravg;
xcorrdata.xcorrcount = xcorrcount;
xcorrdata.xcorrvar = xcorrvar;


% Done.
end


%
% This is the end of the file.
