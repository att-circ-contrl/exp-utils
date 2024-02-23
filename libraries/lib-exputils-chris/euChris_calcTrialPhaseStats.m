function phasedata = euChris_calcTrialPhaseStats( ...
  ftdata_first, ftdata_second, win_params, detrend_method )

% function phasedata = euChris_calcTrialPhaseStats( ...
%   ftdata_first, ftdata_second, win_params, detrend_method )
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
% "ftdata_first" is a ft_datatype_raw structure with the first set of trials.
% "ftdata_second" is a ft_datatype_raw structure with the second set of trials.
% "win_params" is a structure giving time window information, per
%   CHRISMUAPARAMS.txt.
% "detrend_method" is 'detrend', 'demean', or 'none'.
%
% "phasedata" is a structure with the following fields:
%   "firstchans" is a cell array with FT channel names for the first set of
%     channels being compared.
%   "secondchans" is a cell array with FT channel names for the second set of
%     channels being compared.
%   "windowlist_ms" is a vector containing timestamps in milliseconds
%     specifying where the middle of each analysis window is. This is a copy
%     of win_params.timelist_ms.
%   "phasediffs" is a matrix indexed by (firstchan, secondchan, trialidx,
%      winidx ) containing the circular mean of (phase2 - phase1).
%   "plvs" is a matrix indexed by (firstchan, secondchan, trialidx, winidx)
%      containing the phase lock values between pairs of channels. This is
%      equal to 1 - circvar(phase2 - phase1).


%
% Check for bail-out conditions.

phasedata = struct([]);

if isempty(ftdata_first.label) || isempty(ftdata_first.time) ...
  || isempty(ftdata_second.label) || isempty(ftdata_second.time)
  return;
end


%
% Get metadata.

trialcount = length(ftdata_first.time);

chancount_first = length(ftdata_first.label);
chancount_second = length(ftdata_second.label);

samprate = 1 / mean(diff( ftdata_first.time{1} ));
winrad_samps = round( samprate * win_params.time_window_ms * 0.001 * 0.5 );

wintimes_sec = win_params.timelist_ms * 0.001;
wincount = length(wintimes_sec);


%
% Compute phase differences and phase lock values.

phasediffs = [];
plvs = [];

for trialidx = 1:trialcount

  % Get raw data.

  thistimefirst = ftdata_first.time{trialidx};
  thistimesecond = ftdata_second.time{trialidx};

  thisdatafirst = ftdata_first.trial{trialidx};
  thisdatasecond = ftdata_second.trial{trialidx};


  % Compute instantaneous phase angles.

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


  % Walk through windows.

  for widx = 1:wincount

    % Figure out window position. The timestamp won't match perfectly.

    thiswintime = wintimes_sec(widx);

    winsampfirst = thistimefirst - thiswintime;
    winsampfirst = min(find( winsampfirst >= 0 ));

    winsampsecond = thistimesecond - thiswintime;
    winsampsecond = min(find( winsampsecond >= 0 ));

    winrangefirst = ...
      [ (winsampfirst-winrad_samps):(winsampfirst+winrad_samps) ];
    winrangesecond = ...
      [ (winsampsecond-winrad_samps):(winsampsecond+winrad_samps) ];


    % Walk through channel pairs, computing relative phase and PLV.

    for cidxfirst = 1:chancount_first
      for cidxsecond = 1:chancount_second
        thisphasefirst = ...
          thisanglefirst( cidxfirst, winrangefirst );
        thisphasesecond = ...
          thisanglesecond( cidxsecond, winrangesecond );

        thisphasediff = thisphasesecond - thisphasefirst;

        [ cmean cvar lindev ] = nlProc_calcCircularStats( thisphasediff );

        phasediffs(cidxfirst,cidxsecond,trialidx,widx) = cmean;
        plvs(cidxfirst,cidxsecond,trialidx,widx) = 1 - cvar;
      end
    end

  end

end


%
% Package the output.


phasedata = struct();

phasedata.firstchans = ftdata_first.label;
phasedata.secondchans = ftdata_second.label;

phasedata.windowlist_ms = win_params.timelist_ms;

phasedata.phasediffs = phasediffs;
phasedata.plvs = plvs;



% Done.
end


%
% This is the end of the file.
