function trialdefs = euFT_getTrainTrialDefs( ...
  samprate, sampcount, evtimes, trig_window_ms, train_gap_ms )

% function trialdefs = euFT_getTrainTrialDefs( ...
%   samprate, sampcount, evtimes, trig_window_ms, train_gap_ms )
%
% This builds a list of Field Trip trial definitions for events with the
% specified times. Events are grouped into trains of closely-spaced events,
% and relative position of each event within each train is recorded.
%
% The first sample in the continuous waveform is assumed to be time 0.
%
% "samprate" is the sampling rate.
% "sampcount" is the total number of samples in the continuous data.
% "evtimes" is a vector containing trigger event timestamps in seconds.
% "trig_window_ms" [ start stop ] is the window around trigger events
%   to save, in milliseconds. E.g. [ -100 300 ].
% "train_gap_ms" is a duration in milliseconds. Trigger events with this
%   separation or less are considered to be part of an event train.
%
% "trialdefs" is a "trl" matrix per ft_definetrial(). It is a Nx7 matrix.
%   The first three columns are the starting sample index, the ending sample
%   index, and the relative position of the first sample in the trial with
%   respect to the trigger (0 = on trigger, + = after trigger, - = before
%   trigger). Column 4 is the relative position of each trial's event within
%   its associated train. Columns 5, 6, and 7 are the trigger time, trial
%   starting time, and trial ending time in seconds.


trialdefs = zeros(0,7);


% Translate millisecond times into second times.
% Also unpack the window span.

max_train_gap = train_gap_ms * 0.001;

% Remember to negate "first time" to get "duration before".
time_before_trig = - min(trig_window_ms) * 0.001;
time_after_trig = max(trig_window_ms) * 0.001;

% Do the sample conversion only once, to make sure it's consistent.
samps_before_trig = round(time_before_trig * samprate);
samps_after_trig = round(time_after_trig * samprate);


% We're plotting around all events, if the event window is in the valid
% sample range.
% Iteration is needed to track position within trains.

trigtimes = [];
starttimes = [];
endtimes = [];

trigsamps = [];
startsamps = [];
endsamps = [];

trainpositions = [];

trigcount = 0;
trainpos = NaN;
prevtime = NaN;

for eidx = 1:length(evtimes)

  thistime = evtimes(eidx);


  % Figure out what the train state is.
  % Don't worry about whether we're within a valid sample range for this.

  want_new_train = false;
  end_old_train = false;

  if isnan(prevtime)
    % First event. Start a new train.
    trainpos = 1;
  elseif (thistime - prevtime) > max_train_gap
    % End this train and start a new train.
    trainpos = 1;
  else
    % Continue in the train we're in.
    trainpos = trainpos + 1;
  end

  prevtime = thistime;


  % Compute event bounds and save it if it's entirely within the valid
  % sample range. Make sure to store these as column vectors.

  % Remember that time 0 is sample 1.
  thissamp = round(thistime * samprate) + 1;
  firstsamp = thissamp - samps_before_trig;
  lastsamp = thissamp + samps_after_trig;

  if (firstsamp >= 1) && (lastsamp <= sampcount)
    trigcount = trigcount + 1;

    trigtimes(trigcount,1) = thistime;
    starttimes(trigcount,1) = thistime - time_before_trig;
    endtimes(trigcount,1) = thistime + time_after_trig;

    trigsamps(trigcount,1) = thissamp;
    startsamps(trigcount,1) = firstsamp;
    endsamps(trigcount,1) = lastsamp;

    trainpositions(trigcount,1) = trainpos;
  end

end


% Assemble the "trl" matrix, if we had any valid events.

if trigcount > 0
  trialdefs = [];
  trialdefs(:,1) = startsamps;
  trialdefs(:,2) = endsamps;
  trialdefs(:,3) = startsamps - trigsamps;
  trialdefs(:,4) = trainpositions;
  trialdefs(:,5) = trigtimes;
  trialdefs(:,6) = starttimes;
  trialdefs(:,7) = endtimes;
end


% Done.
end


%
% This is the end of the file.
