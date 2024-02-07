function timetables = euHLev_alignAllDevices( ...
  boxevents, gameevents, ttlevents, gameframedata )

% function timetables = euHLev_alignAllDevices( ...
%   boxevents, gameevents, ttlevents, gameframedata )
%
% This makes several calls to euUSE_AlignTwoDevices() to build tables of
% corresponding timestamps for SyncBox, USE, ephys, and eye-tracker devices.
%
% This is intended to work with the output of euHLev_readAllTTLEvents() and
% euUSE_readRawFrameData().
%
% NOTE - This assumes that _either_ Open Ephys _or_ Intan recorder output
% is supplied, not both at once.
%
% Supplied event structures may be struct([]) for devices that are absent.
%
% "boxevents" is a structure containing SynchBox event data tables.
% "gameevents" is a structure containing USE event data tables.
% "ttlevents" is a structure containing structures with event tables from
%   several devices:
%   "openephys" contains event tables from Open Ephys.
%   "intanrec" contains event tables from the Intan recording controller.
%   "intanstim" contains event tables from the Intan stimulation controller.
% "gameframedata" is a FrameData data table.
%
% "timetables" is a structure containing several tables with corresponding
%   time tuples (empty tables if alignment couldn't be performed):
%   "record_synchbox" associates 'synchBoxTime' and 'recTime'.
%   "record_game" associates 'unityTime' and 'recTime'.
%   "record_stim" associates 'recTime' and 'stimTime'.
%   "game_eye" associates 'unityTime' and 'eyeTime'.


timetables = struct();
timetables.record_synchbox = table();
timetables.record_game = table();
timetables.record_stim = table();
timetables.game_eye = table();


% Defaults are fine for most of this.
alignconfig = struct();
alignconfig.verbosity = 'quiet';


% Figure out which recording device we're using.

recevents = ttlevents.openephys;
if isempty(recevents)
  recevents = ttlevents.intanrec;
end

% Copy the stimulator for convenience.
stimevents = ttlevents.intanstim;


% NOTE - We're only aligning on event codes.
% Using reward pulses takes too long.


% For SynchBox alignment, use raw code bytes rather than cooked codes.
% Otherwise we get glitching from missing codes in the serial reply stream.

if isfield(recevents, 'rawcodes') && isfield(boxevents, 'rawcodes')
  disp('.. Aligning recorder and SynchBox timestamps.');

  [ scratch timelut ] = euUSE_alignTwoDevices( ...
    { recevents.rawcodes, boxevents.rawcodes }, ...
    'recTime', 'synchBoxTime', alignconfig );

  timetables.record_synchbox = timelut;

  disp('.. Finished aligning recorder and SynchBox timestamps.');
end


if isfield(recevents, 'cookedcodes') && isfield(gameevents, 'cookedcodes')
  disp('.. Aligning recorder and game timestamps.');

  [ scratch timelut ] = euUSE_alignTwoDevices( ...
    { recevents.cookedcodes, gameevents.cookedcodes }, ...
    'recTime', 'unityTime', alignconfig );

  timetables.record_game = timelut;

  disp('.. Finished aligning recorder and game timestamps.');
end


if isfield(recevents, 'cookedcodes') && isfield(stimevents, 'cookedcodes')
  disp('.. Aligning recorder and stimulator timestamps.');

  [ scratch timelut ] = euUSE_alignTwoDevices( ...
    { recevents.cookedcodes, stimevents.cookedcodes }, ...
    'recTime', 'stimTime', alignconfig );

  timetables.record_stim = timelut;

  disp('.. Finished aligning recorder and stimulator timestamps.');
end


if ~isempty(gameframedata)
  disp('.. Aligning game and eye-tracker timestamps.');

  % We're given tuples explicitly here.
  timetables.game_eye = euAlign_getUniqueTimestampTuples( ...
    gameframedata, {'unityTime', 'eyeTime'} );

  disp('.. Finished aligning game and eye-tracker timestamps.');
end


% Done.
end


%
% This is the end of the file.
