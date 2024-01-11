function htdata = euChris_calcHTStats( ...
  ftdata_first, ftdata_second, mua_params )

% function htdata = euChris_calcHTStats( ...
%   ftdata_first, ftdata_second, mua_params )
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
% "mua_params" is a structure giving time window information, per
%   CHRISMUAPARAMS.txt.
%
% "htdata" is a structure with the following fields:
%   "firstchans" is a cell array with FT channel names for the first set of
%     channels being compared.
%   "secondchans" is a cell array with FT channel names for the second set of
%     channels being compared.
%   "windowlist_ms" is a vector containing timestamps in milliseconds
%     specifying where the middle of each analysis window is. This is a copy
%     of mua_params.timelist_after_ms.
%   "coherencevals" is a matrix indexed by (firstchan, secondchan, winidx)
%     containing coherence values (complex, magnitude between 0 and 1).
%   "powercorrelvals" is a matrix indexed by (firstchan, secondchan, winidx)
%     containing power correlation values (real, between -1 and +1).
%   "nongaussvals" is a matrix indexed by (firstchan, secondchan, winidx)
%     containing non-Gaussian power correlation values (real, -1 to +1).


% FIXME - Break out the common bits into a helper and make this and xcorr
% call it.


% Initialize.
htdata = struct([]);


% Check for bail-out conditions.

if isempty(ftdata_first.label) || isempty(ftdata_first.time) ...
  || isempty(ftdata_second.label) || isempty(ftdata_second.time)
  return;
end



%
% Get metadata.

samprate = 1 / mean(diff( ftdata_first.time{1} ));

winrad_samps = round( samprate * mua_params.time_window_ms * 0.001 * 0.5 );
wintimes_sec = mua_params.timelist_after_ms * 0.001;

trialcount = length(ftdata_first.time);

chancount_first = length(ftdata_first.label);
chancount_second = length(ftdata_second.label);



%
% Upgrade real signals to analytic signals.

for tidx = 1:trialcount
  thistrial = ftdata_first.trial{tidx};
  for cidx = 1:chancount_first
    thistrial(cidx,:) = hilbert(thistrial(cidx,:));
  end
  ftdata_first.trial{tidx} = thistrial;

  thistrial = ftdata_second.trial{tidx};
  for cidx = 1:chancount_second
    thistrial(cidx,:) = hilbert(thistrial(cidx,:));
  end
  ftdata_second.trial{tidx} = thistrial;
end



%
% Compute HT statistics and average across trials.

% FIXME - Add variance here, and store average/counts/variance?

coherenceavg = [];
coherencecounts = [];
correlavg = [];
correlcounts = [];
nongaussavg = [];
nongausscounts = [];

for tidx = 1:trialcount

  thiscoherence = [];
  thiscorrel = [];
  thisnongauss = [];

  thistimefirst = ftdata_first.time{tidx};
  thistimesecond = ftdata_second.time{tidx};

  thisdatafirst = ftdata_first.trial{tidx};
  thisdatasecond = ftdata_second.trial{tidx};

  % NOTE - Blithely assuming that test windows don't contain NaN regions.
  % Blithely assuming that if they do, we'll just get NaN output, rather
  % than throwing an error.

  for widx = 1:length(wintimes_sec)

    % Figure out window position. The timestamp won't match perfectly.
    thiswintime = wintimes_sec(widx);

    winsampfirst = thistimefirst - thiswintime;
    winsampfirst = min(find( winsampfirst >= 0 ));

    winsampsecond = thistimesecond - thiswintime;
    winsampsecond = min(find( winsampsecond >= 0 ));


    % Get window contents.

    windatafirst = thisdatafirst(:, ...
      [ (winsampfirst - winrad_samps) : (winsampfirst + winrad_samps) ]);
    windatasecond = thisdatasecond(:, ...
      [ (winsampsecond - winrad_samps) : (winsampsecond + winrad_samps) ]);


    % Get statistics.

    for cidxfirst = 1:chancount_first
      wavefirst = windatafirst(cidxfirst,:);
      for cidxsecond = 1:chancount_second
        wavesecond = windatasecond(cidxsecond,:);

        [ scratchcoherence scratchcorrel scratchnongauss ] = ...
          nlProc_compareSignalsHT( wavefirst, wavesecond );

        thiscoherence(cidxfirst,cidxsecond,widx) = scratchcoherence;
        thiscorrel(cidxfirst,cidxsecond,widx) = scratchcorrel;
        thisnongauss(cidxfirst,cidxsecond,widx) = scratchnongauss;
      end
    end

  end


  % Compute the averages, tolerating NaN values.

  % Handle initialization.

  if isempty(coherenceavg)
    coherenceavg = zeros(size( thiscoherence ));
    coherencecounts = zeros(size( thiscoherence ));
  end

  if isempty(correlavg)
    correlavg = zeros(size( thiscorrel ));
    correlcounts = zeros(size( thiscorrel ));
  end

  if isempty(nongaussavg)
    nongaussavg = zeros(size( thisnongauss ));
    nongausscounts = zeros(size( thisnongauss ));
  end

  % Update the averages, tolerating NaNs.

  thismask = ~isnan(thiscoherence);
  coherenceavg(thismask) = coherenceavg(thismask) + thiscoherence(thismask);
  coherencecounts = coherencecounts + thismask;

  thismask = ~isnan(thiscorrel);
  correlavg(thismask) = correlavg(thismask) + thiscorrel(thismask);
  correlcounts = correlcounts + thismask;

  thismask = ~isnan(thisnongauss);
  nongaussavg(thismask) = nongaussavg(thismask) + thisnongauss(thismask);
  nongausscounts = nongausscounts + thismask;

end

% Compute the averages.
coherenceavg = coherenceavg ./ coherencecounts;
correlavg = correlavg ./ correlcounts;
nongaussavg = nongaussavg ./ nongausscounts;



%
% Build the return structure.

htdata = struct();

htdata.firstchans = ftdata_first.label;
htdata.secondchans = ftdata_second.label;

htdata.windowlist_ms = mua_params.timelist_after_ms;

htdata.coherencevals = coherenceavg;
htdata.powercorrelvals = correlavg;
htdata.nongaussvals = nongaussavg;



% Done.
end


%
% This is the end of the file.
