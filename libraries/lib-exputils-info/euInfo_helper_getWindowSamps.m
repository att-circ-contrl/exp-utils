function winranges = euInfo_helper_getWindowSamps( ...
  samprate, time_window_ms, timelist_ms, trial_timeseries )

% function winranges = euInfo_helper_getWindowSamps( ...
%   samprate, time_window_ms, timelist_ms, trial_timeseries )
%
% This converts an analysis time window specification into a list of sample
% ranges within supplied time series.
%
% This is intended to be used with Field Trip data (passing ftdata.time),
% but a time series vector can be accepted as well (converted to a single
% trial time series).
%
% Note that if this is called with a consistent sampling rate and time
% window duration, the size (in samples) of the generated time windows will
% remain consistent across calls.
%
% "samprate" is the sampling rate.
% "time_window_ms" is the duration of the time window in milliseconds.
% "timelist_ms" is a vector with time window midpoint locations in
%   milliseconds.
% "trial_timeseries" is either a vector containing monotonically increasing
%   timestamps in _seconds_, or a cell array containing several such vectors
%   (as provided by the "time" field in "ft_datatype_raw").
%
% "winranges" is a Ntrials x Nwindows cell array. Each cell contains a
%   sample index range into a trial's time series corresponding to an
%   analysis time window.


% Convert the time series list into a cell array if it isn't already one.

if ~iscell(trial_timeseries)
  trial_timeseries = { trial_timeseries };
end

trialcount = length(trial_timeseries);



% Get metadata.

winrad_samps = round( samprate * time_window_ms * 0.001 * 0.5 );

wintimes_sec = timelist_ms * 0.001;

wincount = length(wintimes_sec);



% Build sample ranges for each time series and window position.

winranges = {};

for trialidx = 1:trialcount
  thistime = trial_timeseries{trialidx};

  for widx = 1:wincount

    % Figure out window position. The timestamp won't match perfectly.
    thiswintime = wintimes_sec(widx);

    winmidsamp = thistime - thiswintime;
    winmidsamp = min(find( winmidsamp >= 0 ));

    winranges{trialidx,widx} = ...
      [ (winmidsamp-winrad_samps):(winmidsamp+winrad_samps) ];

  end
end


% Done.
end


%
% This is the end of the file.
