function oscfeatures = euChris_extractStimOscillationResponse( ...
  timeseriesbefore, trialdatabefore, timeseriesafter, trialdataafter, ...
  oscfit_params, meta_fields )

% function oscfeatures = euChris_extractStimOscillationResponse( ...
%   timeseriesbefore, trialdatabefore, timeseriesafter, trialdataafter, ...
%   oscfit_params, meta_fields )
%
% This performs feature extraction of oscillations before and after
% stimulation, for one or more trials.
%
% For each trial, this finds the dominant oscillation frequency within a
% specified time window, and then curve-fits oscillation magnitude at or
% near that frequency within one time window before stimulation and
% multiple time windows after stimulation.
%
% One set of trials is used for curve-fitting before stimulation and another
% set of trials for curve-fitting after stimulation. These may be the same
% trials (to fit before and after each event), or may be trials corresponding
% to the first and last event in a train (to fit before and after the train).
%
% The number of trials and channels must be the same for both trial sets.
% Durations (sample counts) may vary.
%
% "timeseriesbefore" is a 1xNtrials cell array containing time series for
%   trials to fit before stimulation.
% "trialdatabefore" is a 1xNtrials cell array containing Nchans x Nsamples
%   matrices of waveform data for trials to fit before stimulation.
% "timeseriesafter" is a 1xNtrials cell array containing time series for
%   trials to fit after stimulation.
% "trialdataafter" is a 1xNtrials cell array containing Nchans x Nsamples
%   matrices of waveform data for trials to fit after stimulation.
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
%   "use_line_fit" (optional) is true to subtract a line fit before doing
%     the cosine fit, and false or absent to just subtract the mean.
%   "debug_save_waves" is true to save raw signals used for curve fits.
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
%   "phasebefore" is a Nchans x 1 matrix containing the phase (in radians) of
%     the dominant oscillation before stimulation for each channel at the
%     window midpoint.
%   "meanbefore" is a Nchans x 1 matrix containing the DC offset (mean) of the
%     wave in the "before stimulation" curve fit window.
%   "rampbefore" (optional) is a Nchans x 1 matrix containing the line-fit
%     slope of the wave in the "before stimulation" curve fit window.
%   "magafter" is a Nchans x Nwindows matrix containing magnitudes of the
%     dominant oscillation after stimulation for each channel and each
%     requested window location.
%   "freqafter" is a Nchans x Nwindows matrix containing frequencies of the
%     dominant oscillation after stimulation for each channel and each
%     requested window location.
%   "phaseafter" is a Nchans x Nwindows matrix containing the phase (in
%     radians) of the dominant oscillation after stimulation for each
%     channel at each requested window midpoint.
%   "meanafter" is a Nchans x Nwindows matrix containing the DC offset (mean)
%     of the wave in each "after stimulation" curve fit window.
%   "rampafter" (optional) is a Nchans x Nwindows matrix containing the
%     line-fit slope of the wave in each "after stimulation" curve fit window.
%   "relafter" is a Nchans x Nwindows matrix containing relative magnitudes
%     of the dominant oscillation after stimulation dividied by the magnitude
%     before stimulation, for each channel and each requested window
%     location. If the oscillation before stimulation was below-threshold,
%     NaN is recorded instead of the relative magnitude.


% FIXME - Diagnostics switches.
origsavebefore = false;
origsaveafter = false;
if isfield(oscfit_params, 'debug_save_waves')
  origsavebefore = oscfit_params.debug_save_waves;
  origsaveafter = oscfit_params.debug_save_waves;
end


polyorder = 0;
if isfield(oscfit_params, 'use_line_fit')
  if oscfit_params.use_line_fit
    polyorder = 1;
  end
end


oscfeatures = {};

for tidx = 1:length(timeseriesbefore)

  thisbeforetimes = timeseriesbefore{tidx};
  thisbeforetrials = trialdatabefore{tidx};

  thisaftertimes = timeseriesafter{tidx};
  thisaftertrials = trialdataafter{tidx};


  % We _really_ should have the same sampling rate before and after, but
  % handle the case where the user did something truly strange.

  nsamples = length(thisbeforetimes);
  sampratebefore = ...
    (nsamples - 1) / (thisbeforetimes(nsamples) - thisbeforetimes(1));

  nsamples = length(thisaftertimes);
  samprateafter = ...
    (nsamples - 1) / (thisaftertimes(nsamples) - thisaftertimes(1));


  % Trial data is Nchans x Nsamples.
  % Nchans is consistent for trials before and after.
  scratch = size(thisbeforetrials);
  nchans = scratch(1);


  % NOTE - We're looking at the "before" channels to guess the dominant
  % frequency. The frequency after stimulation may be different, and the
  % artifacts from stimulation may perturb this frequency estimate.

  % NOTE - We can either use the mean across channels or the channel with
  % the largest single component. Neither is perfect.

  dominantmethod = 'largest';

  timemask = ( thisbeforetimes >= min(oscfit_params.window_search) ) ...
    & ( thisbeforetimes <= max(oscfit_params.window_search) );
  trialsubset = thisbeforetrials(:,timemask);

  [ oscfreq ~ ] = nlProc_guessDominantFrequencyAcrossChans( ...
    trialsubset, sampratebefore, oscfit_params.freq_search, dominantmethod );

  freqrange = oscfreq * oscfit_params.freq_drift;



  % Walk through the windows, getting absolute magnitudes.

  winrad = oscfit_params.window_lambda * 0.5 / oscfreq;

  [ magbefore freqbefore phasebefore meanbefore rampbefore ...
    origwavebefore origtimebefore rawphasebefore ] = ...
    helper_doOscillationFit( oscfit_params.time_before, winrad, ...
      thisbeforetimes, thisbeforetrials, freqrange, polyorder );

  magafter = [];
  freqafter = [];
  phaseafter = [];
  meanafter = [];
  rampafter = [];

  % FIXME - Diagnostics. Save the original waveform.
  if origsaveafter
    origwaveafter = {};
    origtimeafter = {};
    rawphaseafter = {};
  end

  for widx = 1:length(oscfit_params.timelist_after)

    [ thismag thisfreq thisphase thismean thisramp ...
      thisorigwave thisorigtime thisrawphase ] = ...
      helper_doOscillationFit( oscfit_params.timelist_after(widx), winrad, ...
        thisaftertimes, thisaftertrials, freqrange, polyorder );

    magafter(:,widx) = thismag(:,1);
    freqafter(:,widx) = thisfreq(:,1);
    phaseafter(:,widx) = thisphase(:,1);

    meanafter(:,widx) = thismean(:,1);
    rampafter(:,widx) = thisramp(:,1);

    origwaveafter{widx} = thisorigwave;
    origtimeafter{widx} = thisorigtime;
    rawphaseafter{widx} = thisrawphase;
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
  thisreport.phasebefore = phasebefore;
  thisreport.meanbefore = meanbefore;

  thisreport.magafter = magafter;
  thisreport.freqafter = freqafter;
  thisreport.phaseafter = phaseafter;
  thisreport.meanafter = meanafter;

  if polyorder > 0
    thisreport.rampbefore = rampbefore;
    thisreport.rampafter = rampafter;
  end

  thisreport.relafter = relafter;

  % FIXME - Diagnostics. Save the original waveform.
  if origsavebefore
    thisreport.origtimebefore = origtimebefore;
    thisreport.origwavebefore = origwavebefore;
    thisreport.rawphasebefore = rawphasebefore;
  end
  if origsaveafter
    thisreport.origtimeafter = origtimeafter;
    thisreport.origwaveafter = origwaveafter;
    thisreport.rawphaseafter = rawphaseafter;
  end


  oscfeatures = [ oscfeatures { thisreport } ];

end


% Done.
end


%
% Helper Functions


% This fits cosines in the specified window for all channels in one trial.

function [ magfit freqfit phasefit meanfit rampfit ...
  origwave origtime rawphase ] = ...
  helper_doOscillationFit( timetarget, winrad, ...
    thistimeseries, thistrialdata, freqrange, polyorder )

  % Initialize.

  magfit = [];
  freqfit = [];
  phasefit = [];
  meanfit = [];
  rampfit = [];

  origwave = [];
  origtime = [];
  rawphase = [];


  % Get metadata.

  nsamples = length(thistimeseries);
  samprate = (nsamples - 1) / (thistimeseries(nsamples) - thistimeseries(1));

  % Trial data is Nchans x Nsamples.
  scratch = size(thistrialdata);
  nchans = scratch(1);


  % Get the time region of interest.

  winfirst = timetarget - winrad;
  winlast = timetarget + winrad;
  timemask = (thistimeseries >= winfirst) & (thistimeseries <= winlast);


  % Save the original waveform's time series.
  origtime = thistimeseries(timemask);

  for cidx = 1:nchans
    thisseries = thistrialdata(cidx,timemask);
    [ thismag thisfreq thisphase thispoly ] = ...
      nlProc_fitCosine( thisseries, samprate, freqrange, polyorder );

    % Save the original waveform and fit phase.
    origwave(cidx,:) = thisseries;
    rawphase(cidx,1) = thisphase;

    % Advance the phase to get the midpoint phase.
    thisphase = thisphase + 2 * pi * thisfreq * winrad;

    magfit(cidx,1) = thismag;
    freqfit(cidx,1) = thisfreq;
    phasefit(cidx,1) = thisphase;

    thismean = thispoly(length(thispoly));
    meanfit(cidx,1) = thismean;

    if polyorder > 0
      thisramp = thispoly(length(thispoly) - 1);
      rampfit(cidx,1) = thisramp;
      meanfit(cidx,1) = thismean + winrad * thisramp;
    else
      rampfit(cidx,1) = 0;
    end
  end

end


%
% This is the end of the file.
