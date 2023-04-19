function trialdefs = euFT_getTrainTrialDefs( ...
  samprate, sampcount, trigtimes, trig_window_ms, train_gap_ms )

% function trialdefs = euFT_getTrainTrialDefs( ...
%   samprate, sampcount, trigtimes, trig_window_ms, train_gap_ms )
%
% This builds a list of Field Trip trial definitions for events with the
% specified times. Events are grouped into trains of closely-spaced events,
% and relative position of each event within each train is recorded.
%
% The first sample in the continuous waveform is assumed to be time 0.
%
% "samprate" is the sampling rate.
% "sampcount" is the total number of samples in the continuous data.
% "trigtimes" is a vector containing trigger timestamps in seconds.
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

trialdefs = zeros(7,0);

% Done.
end


%
% This is the end of the file.
