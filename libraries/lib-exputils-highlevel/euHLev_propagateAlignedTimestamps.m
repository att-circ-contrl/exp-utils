function [ newboxevents newgameevents newttlevents newgameframedata ...
  newgamegazedata ] = euHLev_propagateAlignedTimestamps( ...
    timetables, oldboxevents, oldgameevents, oldttlevents, ...
    oldgameframedata, oldgamegazedata )

% function [ newboxevents newgameevents newttlevents newgameframedata ...
%   newgamegazedata ] = euHLev_propagateAlignedTimestamps( ...
%     timetables, oldboxevents, oldgameevents, oldttlevents, ...
%     oldgameframedata, oldgamegazedata )
%
% This uses the time correspondence lookup tables from euHLev_alignAllDevices
% to propagate timestamps from different devices between event lists returned
% by euHLev_readAllTTLEvents and the USE FrameData and GazeData tables.
%
% Supplied event structures may be struct([]) for devices that are absent.
% Supplied time lookup tables may be empty for devices that couldn't be
% aligned (or were absent).
%
% "timetables" is a structure containing several tables whose rows contain
%   corresponding timestamps from different devices (per TIMETABLES.txt):
%   "record_synchbox" associates 'synchBoxTime' and 'recTime'.
%   "record_game" associates 'unityTime' and 'recTime'.
%   "record_stim" associates 'recTime' and 'stimTime'.
%   "game_eye" associates 'unityTime' and 'eyeTime'.
% "oldboxevents" is a structure containing SynchBox event data tables.
% "oldgameevents" is a structure containing USE event data tables.
% "oldttlevents" is a structure cotnaining structures with event tables from
%   several devices:
%   "openephys" contains event tables from Open Ephys.
%   "intanrec" contains event tables from the Intan recording controller.
%   "intanstim" contains event tables from the Intan stimulation controller.
% "oldgameframedata" is a USE FrameData data table.
% "oldgamegazedata" is a USE GazeData data table.
%
% "newboxevents" is a copy of "oldboxevents" with new timestamp columns.
% "newgameevents" is a copy of "oldgameevents" with new timestamp columns.
% "newttlevents" is a copy of "oldttlevents" with new timestamp columns.
% "newgameframedata" is a copy of "oldgameframedata" with new time columns.
% "newgamegazedata" is a copy of "oldgamegazedata" with new time columns.


% Initialize.

newboxevents = oldboxevents;
newgameevents = oldgameevents;
newttlevents = oldttlevents;
newgameframedata = oldgameframedata;
newgamegazedata = oldgamegazedata;



% Add recorder timstamps to everything we aligned it with.
% We know that these tables are non-empty if we did alignment with them.

if ~isempty(timetables.record_synchbox)
  newboxevents = euAlign_addTimesToAllTables( ...
    oldboxevents, 'synchBoxTime', 'recTime', timetables.record_synchbox );
end

if ~isempty(timetables.record_game)
  newgameevents = euAlign_addTimesToAllTables( ...
    oldgameevents, 'unityTime', 'recTime', timetables.record_game );
end

if ~isempty(timetables.record_stim)
  newstimevents = euAlign_addTimesToAllTables( ...
    oldstimevents, 'stimTime', 'recTime', times_recorder_stimulator );
end



% Fiddle with the frame data table.

if ~isempty(newgameframedata)

  % Clean up gaze timestamps in framedata. The ET timestamps aren't unique
  % in the original. We can interpolate to find out what they should be.

  if ~isempty(timetables.game_eye)
    newgameframedata = euAlign_addTimesToTable( newgameframedata, ...
      'unityTime', 'eyeTime', timetables.game_eye );
  end

  % Add recorder timestamps to framedata.

  if ~isempty(timetables.record_game)
    newgameframedata = euAlign_addTimesToTable( newgameframedata, ...
      'unityTime', 'recTime', timetables.record_game );
  end

end



% Fiddle with the gaze data table.

if ~isempty(newgamegazedata)

  % Propagate unity timestamps first.

  if ~isempty(timetables.game_eye)
    newgamegazedata = euAlign_addTimesToTable( newgamegazedata, ...
      'eyeTime', 'unityTime', timetables.game_eye );

    % If we have unity timestamps, derive recorder timestamps too.
    if ~isempty(timetables.record_game)
      newgamegazedata = euAlign_addTimesToTable( newgamegazedata, ...
        'unityTime', 'recTime', timetables.record_game );
    end
  end

end




% FIXME - Not propagating stimulator timestamps anywhere.
% FIXME - We should add support for "just stimulator, no recorder" later.


% Done.
end

%
% This is the end of the file.
