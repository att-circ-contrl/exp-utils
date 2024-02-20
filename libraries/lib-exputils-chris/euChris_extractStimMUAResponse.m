function muafeatures = euChris_extractStimMUAResponse( ...
  timeseriesbefore, trialdatabefore, timeseriesafter, trialdataafter, ...
  mua_params, meta_fields )

% function muafeatures = euChris_extractStimMUAResponse( ...
%   timeseriesbefore, trialdatabefore, timeseriesafter, trialdataafter, ...
%   mua_params, meta_fields )
%
% This performs feature extraction of multi-unit activity before and after
% stimulation, for one or more trials.
%
% For each trial, this finds the magnitude and standard deviation of the
% MUA in user-specified time windows before and after stimulation. Several
% derived statistics are computed, per CHRISSTIMFEATURES.txt.
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
% "mua_params" is a structure containing the following fields,
%   per CHRISMUAPARAMS.txt:
%   "time_window_ms" is the duration in milliseconds of the time windows
%     used for extracting average statistics.
%   "timelist_ms" is a vector containing timestamps in milliseconds
%     specifying where the middle of the "after stimulation" time windows
%     should be.
%   "time_before_ms" is a timestamp in milliseconds specifying where the
%     middle of the "before stimulation" time window should be.
% "meta_fields" is a structure with arbitrary fields. Each output structure
%   in "muafeatures" is initialized with a copy of "meta_fields".
%
% "muafeatures" is a 1xNtrials cell array. Each cell contains a copy of the
%   "meta_fields" structure with the following fields added, per
%   CHRISSTIMFEATURES.txt:
%   "trialnum" is the trial number.
%   "winbefore" is a scalar containing the timestamp in seconds of the
%     midpoint of the before-stimulation time window.
%   "winafter" is a 1 x Nwindows vector containing the timestamps in seconds
%     of the midpoints of the after-stimulation time windows.
%   "meanbefore" is a Nchans x 1 vector holding the mean of the MUA before
%     stimulation.
%   "meanafter_list" is a Nchans x Nwindows matrix containing means of the
%     MUA after stimulation.
%   "devbefore" is a Nchans x 1 vector holding the standard deviation of
%     the MUA before stimulation.
%   "devafter_list" is a Nchans x Nwindows matrix containing standard
%     deviations of the MUA after stimulation.
%   "basemult_list" is a Nchans x Nwindows matrix containing
%     meanafter / meanbefore. This is the relative increase in background
%     activity.
%   "devmult_list" is a Nchans x Nwindows matrix containing
%     devafter / devbefore. This is the relative increase in activity
%     _variability_.
%   "zbaseshift_list" is a Nchans x Nwindows matrix containing
%     (meanafter - meanbefore) / devbefore. This is the z-scored
%     _displacement_ in background activity.
%   "zdevmean_list" is a Nchans x Nwindows matrix containing
%     devafter / meanbefore. This is normalized _variability_ in the
%     background activity.
%
% If noise is negligible and activity dominates the background, "basemult"
% is a z-scored measure of activity change.
%
% If noise dominates the background and real activity is intermittent,
% "devmult" is a z-scored measure of activity change.
%
% If noise is the same before and after stimulation and real activity is a
% significant part of the background, then "zbaseshift" is a z-scored measure
% of activity change.
%
% If spiking activity is highly variable but the background level is
% consistent, then "zdevmean" is a normalized measurement of variability
% (variation in before-stimulation activity prevents true z-scoring).


% Initialize output.
muafeatures = {};


% Convert times to seconds and window midpoints to window ranges.

winsize = mua_params.time_window_ms / 1000;
winrad = 0.5 * winsize;

beforewindow = mua_params.time_before_ms / 1000;
beforewindow = [ beforewindow - winrad, beforewindow + winrad ];

afterwindows = {};
aftercount = length(mua_params.timelist_ms);
for widx = 1:aftercount
  thisafter = mua_params.timelist_ms(widx) / 1000;
  afterwindows{widx} = [ thisafter - winrad, thisafter + winrad ];
end



% Iterate trials.

for tidx = 1:length(timeseriesbefore)

  thisbeforetime = timeseriesbefore{tidx};
  thisbeforetrial = trialdatabefore{tidx};

  thisaftertime = timeseriesafter{tidx};
  thisaftertrial = trialdataafter{tidx};


  % We _really_ should have the same sampling rate before and after, but
  % handle the case where the user did something truly strange.

  nsamples = length(thisbeforetime);
  sampratebefore = ...
    (nsamples - 1) / (thisbeforetime(nsamples) - thisbeforetime(1));

  nsamples = length(thisaftertime);
  samprateafter = ...
    (nsamples - 1) / (thisaftertime(nsamples) - thisaftertime(1));


  % Trial data is Nchans x Nsamples.
  % Nchans is consistent for trials before and after.
  scratch = size(thisbeforetrial);
  nchans = scratch(1);


  % Get before-stimulation statistics.

  timemask = (thisbeforetime >= min(beforewindow)) ...
    & (thisbeforetime <= max(beforewindow));
  trialsubset = thisbeforetrial(:,timemask);

  thismeanbefore = mean(trialsubset, 2);
  thisdevbefore = std(trialsubset, 0, 2);


  % Walk through the windows, getting after-stimulation statistics.
  % Compute derived statistics here too.

  thismeanafterlist = [];
  thisdevafterlist = [];

  thisbasemultlist = [];
  thisdevmultlist = [];
  thisbaseshiftlist = [];

  for widx = 1:aftercount

    thisafterwindow = afterwindows{widx};

    timemask = (thisaftertime >= min(thisafterwindow)) ...
      & (thisaftertime <= max(thisafterwindow));
    trialsubset = thisaftertrial(:,timemask);

    % Calculate statistics.

    thiswinmeanafter = mean(trialsubset, 2);
    thiswindevafter = std(trialsubset, 0, 2);

    thiswinbasemult = thiswinmeanafter ./ thismeanbefore;
    thiswindevmult = thiswindevafter ./ thisdevbefore;
    thiswinbaseshift = (thiswinmeanafter - thismeanbefore) ./ thisdevbefore;
    thiswindevmean = thiswindevafter ./ thismeanbefore;

    % Store statistics.

    thismeanafterlist(1:nchans,widx) = thiswinmeanafter;
    thisdevafterlist(1:nchans,widx) = thiswindevafter;

    thisbasemultlist(1:nchans,widx) = thiswinbasemult;
    thisdevmultlist(1:nchans,widx) = thiswindevmult;
    thisbaseshiftlist(1:nchans,widx) = thiswinbaseshift;
    thisdevmeanlist(1:nchans,widx) = thiswindevmean;

  end


  % Create this trial's output structure.

  thisreport = meta_fields;
  thisreport.trialnum = tidx;

  thisreport.winbefore = mua_params.time_before_ms / 1000;
  thisreport.winafter = mua_params.timelist_ms / 1000;
  if ~isrow(thisreport.winafter)
    thisreport.winafter = transpose(thisreport.winafter);
  end

  thisreport.meanbefore = thismeanbefore;
  thisreport.meanafter_list = thismeanafterlist;
  thisreport.devbefore = thisdevbefore;
  thisreport.devafter_list = thisdevafterlist;

  thisreport.basemult_list = thisbasemultlist;
  thisreport.devmult_list = thisdevmultlist;
  thisreport.zbaseshift_list = thisbaseshiftlist;
  thisreport.zdevmean_list = thisdevmeanlist;


  % Store this trial's output structure.

  muafeatures = [ muafeatures { thisreport } ];

end


% Done.
end


%
% This is the end of the file.
