function oscfeatures = doEval_doStimOscillationAnalysis( ...
  timeseries, trialdata, oscfit_params, meta_fields )

% function oscfeatures = doEval_doStimOscillationAnalysis( ...
%   timeseries, trialdata, oscfit_params, meta_fields )
%
% This performs feature extraction of oscillations before and after
% stimulation, for one or more trials.
%
% For each trial, this finds the dominant oscillation frequency within a
% specified time window, and then curve-fits oscillation magnitude at or
% near that frequency within one time window before stimulation and
% multiple time windows after stimulation.
%
% "timeseries" is a 1xNtrials cell array containing time series for trials.
% "trialdata" is a 1xNtrials cell array containing Nchans x Nsamples
%   matrices of waveform data.
% "oscfit_params" is a structure containing the following fields,
%   per CHRISOSCPARAMS.txt:
%   "window_search" [ min max ] is a time range to look at when measuring
%     the dominant oscillation frequency.
%   "freq_search" [ min max ] is the frequency range to search for the
%     dominant oscillation frequency.
%   "freq_drift" [ min max ] is the minimum and maximum multiple of the
%     dominant frequency to accept when curve-fitting in time windows.
%     E.g. [ 0.5 1.5 ] accepts from 0.5 * fdominant to 1.5 * fdominant.
%   "min_before_strength" is the minimum oscillation magnitude a channel
%     has to have, as a fraction of the strongest channel's magnitude, to
%     be considered to be oscillating before stimulation.
%   "window_lambda" is the width of the curve-fitting time window, as a
%     multiple of the dominant oscillation wavelength.
%   "time_before" is the desired time of the middle of the before-stimulation
%     curve-fitting window.
%   "timelist_after" is a vector containing desired times of the middle of
%     after-stimulation curve fitting windows.
% "meta_fields" is a structure with arbitrary fields. Each output structure
%   in "oscfeatures" is initialized with a copy of "meta_fields".
%
% "oscfeatures" is a 1xNtrials cell array. Each cell contains a copy of the
%   "meta_fields" structure with the following fields added, per
%   CHRISOSCFEATURES.txt:
%   "trialnum" is the trial number.
%   "oscfreq" is the dominant frequency detected in the trial.
%   "magbefore" is a Nchans x 1 matrix containing magnitudes of the dominant
%     oscillation before stimulation for each channel.
%   "freqbefore" is a Nchans x 1 matrix containing frequencies of the dominant
%     oscillation before stimulation for each channel.
%   "magafter" is a Nchans x Nwindows matrix containing magnitudes of the
%     dominant oscillation after stimulation for each channel and each
%     requested window location.
%   "freqafter" is a Nchans x Nwindows matrix containing frequencies of the
%     dominant oscillation after stimulation for each channel and each
%     requested window location.
%   "relafter" is a Nchans x Nwindows matrix containing relative magnitudes
%     of the dominant oscillation after stimulation dividied by the magnitude
%     before stimulation, for each channel and each requested window
%     location. If the oscillation before stimulation was below-threshold,
%     NaN is recorded instead of the relative magnitude.


oscfeatures = {};

for tidx = 1:length(timeseries)

  thistimeseries = timeseries{tidx};
  thistrialdata = trialdata{tidx};

  nsamples = length(thistimeseries);
  samprate = (nsamples - 1) / (thistimeseries(nsamples) - thistimeseries(1));

  % Trial data is Nchans x Nsamples.
  scratch = size(thistrialdata);
  nchans = scratch(1);


  % NOTE - We can either use the mean across channels or the channel with
  % the largest single component. Neither is perfect.

  timemask = ( thistimeseries >= min(oscfit_params.window_search) ) ...
    & ( thistimeseries <= max(oscfit_params.window_search) );
  trialsubset = thistrialdata(:,timemask);

  [ oscfreq ~ ] = nlProc_guessDominantFrequencyAcrossChans( ...
    trialsubset, samprate, oscfit_params.freq_search, 'largest' );

  freqrange = oscfreq * oscfit_params.freq_drift;



  % Walk through the windows, getting absolute magnitudes.

  winrad = oscfit_params.window_lambda * 0.5 / oscfreq;
  winfirst = oscfit_params.time_before - winrad;
  winlast = oscfit_params.time_before + winrad;

  timemask = (thistimeseries >= winfirst) & (thistimeseries <= winlast);

  magbefore = [];
  freqbefore = [];
  for cidx = 1:nchans
    thisseries = thistrialdata(cidx,timemask);
    [ thismag thisfreq ~ ] = ...
      nlProc_fitCosine( thisseries, samprate, freqrange );
    magbefore(cidx,1) = thismag;
    freqbefore(cidx,1) = thisfreq;
  end

  magafter = [];
  freqafter = [];

  for widx = 1:length(oscfit_params.timelist_after)
    winrad = oscfit_params.window_lambda * 0.5 / oscfreq;
    winfirst = oscfit_params.timelist_after(widx) - winrad;
    winlast = oscfit_params.timelist_after(widx) + winrad;

    timemask = (thistimeseries >= winfirst) & (thistimeseries <= winlast);

    for cidx = 1:nchans
      thisseries = thistrialdata(cidx,timemask);
      [ thismag thisfreq ~ ] = ...
        nlProc_fitCosine( thisseries, samprate, freqrange );
      magafter(cidx,widx) = thismag;
      freqafter(cidx,widx) = thisfreq;
    end
  end


  % Get relative magnitudes, where applicable.

  relafter = magafter;
  threshmag = oscfit_params.min_before_strength * max(magbefore);

  for cidx = 1:nchans
    thismag = magbefore(cidx,1);
    thisrow = relafter(cidx,:);

    if thismag >= threshmag
      thisrow = thisrow / thismag;
    else
      thisrow = NaN(size(thisrow));
    end

    relafter(cidx,:) = thisrow;
  end



  % Create this trial's output structure.

  thisreport = meta_fields;
  thisreport.trialnum = tidx;
  thisreport.oscfreq = oscfreq;
  thisreport.magbefore = magbefore;
  thisreport.freqbefore = freqbefore;
  thisreport.magafter = magafter;
  thisreport.freqafter = freqafter;
  thisreport.relafter = relafter;

  oscfeatures = [ oscfeatures { thisreport } ];

end


% Done.
end


%
% This is the end of the file.
