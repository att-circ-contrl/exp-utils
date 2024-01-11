function xcorrdata = euChris_calcXCorr( ...
  ftdata_first, ftdata_second, mua_params, detrend_method )

% function xcorrdata = euChris_calcXCorr( ...
%  ftdata_first, ftdata_second, mua_params, detrend_method )
%
% This calculates cross-correlations between two Field Trip datasets within
% a series of time windows, averaged across trials.
%
% Data is optionally detrended or mean-subtracted before cross-correlation.
%
% NOTE - Both datasets must have the same sampling rate and the same number
% of trials (trials are assumed to correspond).
%
% "ftdata_first" is a ft_datatype_raw structure with the first set of trials.
% "ftdata_second" is a ft_datatype_raw structure with the second set of trials.
% "mua_params" is a structure giving time window and time lag information,
%   per CHRISMUAPARAMS.txt.
% "detrend_method" is 'detrend', 'demean', or 'none' (default).
%
% "xcorrdata" is a structure with the following fields:
%   "firstchans" is a cell array with FT channel names for the first set of
%     channels being compared.
%   "secondchans" is a cell array with FT channel names for the second set of
%     channels being compared.
%   "delaylist_ms" is a vector containing the time lags tested in
%     milliseconds.
%   "windowlist_ms" is a vector containing timestamps in milliseconds
%     specifying where the middle of each cross-correlation window is. This
%     is a copy of mua_params.timelist_after_ms.
%   "xcorrvals" is a matrix indexed by (firstchan, secondchan, winidx, lagidx)
%     containing the cross-correlation values.


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
% Get the sampling rate, and calculate various derived values.

samprate = 1 / mean(diff( ftdata_first.time{1} ));

delaymax_samps = max(abs( mua_params.xcorr_range_ms ));
delaymax_samps = round( samprate * delaymax_samps * 0.001 );

winrad_samps = round( samprate * mua_params.time_window_ms * 0.001 * 0.5 );

wintimes_sec = mua_params.timelist_after_ms * 0.001;


%
% Compute cross-correlations and average across trials.

xcorravg = [];
xcorrcounts = [];
% FIXME - Add variance here, and store average/counts/variance?

trialcount = length(ftdata_first.time);
chancount_first = length(ftdata_first.label);
chancount_second = length(ftdata_second.label);

for trialidx = 1:trialcount
  thisxcorr = [];

  thistimefirst = ftdata_first.time{trialidx};
  thistimesecond = ftdata_second.time{trialidx};

  thisdatafirst = ftdata_first.trial{trialidx};
  thisdatasecond = ftdata_second.trial{trialidx};

  % NOTE - Trials may have NaN regions, but those usually don't overlap
  % the test windows.

  % Walk through windows.
  for widx = 1:length(wintimes_sec)

    % Figure out window position. The timestamp won't match perfectly.
    thiswintime = wintimes_sec(widx);

    winsampfirst = thistimefirst - thiswintime;
    winsampfirst = min(find( winsampfirst >= 0 ));

    winsampsecond = thistimesecond - thiswintime;
    winsampsecond = min(find( winsampsecond >= 0 ));


    % Extract data window contents.

    windatafirst = thisdatafirst(:, ...
      [ (winsampfirst-winrad_samps):(winsampfirst+winrad_samps) ]);
    windatasecond = thisdatasecond(:, ...
      [ (winsampsecond-winrad_samps):(winsampsecond+winrad_samps) ]);

    % NOTE - We may sometimes get NaN data in here. The relevant cross
    % correlations will also be NaN.
    % Detrending and mean subtraction will also make the whole thing NaN,
    % but that's fine. Using 'omitnan' would still give NaN cross-correlation.


    % Do the cross-correlations.

    for cidxfirst = 1:chancount_first
      wavefirst = windatafirst(cidxfirst,:);

      if strcmp('detrend', detrend_method)
        wavefirst = detrend(wavefirst);
      elseif strcmp('demean', detrend_method)
        wavefirst = wavefirst - mean(wavefirst);
      end

      for cidxsecond = 1:chancount_second
        wavesecond = windatasecond(cidxsecond,:);

        if strcmp('detrend', detrend_method)
          wavesecond = detrend(wavesecond);
        elseif strcmp('demean', detrend_method)
          wavesecond = wavesecond - mean(wavesecond);
        end

        rvals = xcorr( wavefirst, wavesecond, delaymax_samps, ...
          mua_params.xcorr_norm_method );
        delaycount = length(rvals);
        thisxcorr(cidxfirst,cidxsecond,widx,1:delaycount) = rvals;
      end
    end

  end


  % Tolerate NaN entries when computing the average.

  if isempty(xcorravg)
    xcorravg = zeros(size(thisxcorr));
    xcorrcounts = zeros(size(thisxcorr));
  end

  thismask = ~isnan(thisxcorr);
  xcorravg(thismask) = xcorravg(thismask) + thisxcorr(thismask);
  xcorrcounts = xcorrcounts + thismask;
end

xcorravg = xcorravg ./ xcorrcounts;


%
% Build the return structure.

xcorrdata = struct();

xcorrdata.firstchans = ftdata_first.label;
xcorrdata.secondchans = ftdata_second.label;

scratch = [ (-delaymax_samps) : delaymax_samps ];
xcorrdata.delaylist_ms = 1000 * scratch / samprate;

xcorrdata.windowlist_ms = mua_params.timelist_after_ms;

xcorrdata.xcorrvals = xcorravg;


% Done.
end


%
% This is the end of the file.
