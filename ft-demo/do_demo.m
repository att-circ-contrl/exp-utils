% Short Field Trip example script.
% Written by Christopher Thomas.


%
% Configuration constants.

% Change these to specify what you want to do.

plotdir = 'plots';
outdatadir = 'output';

inputfolder = 'datasets/20220504-frey-silicon';

% These are the channels that Louie flagged as particularly interesting.
% Louie says that channel 106 in particular was task-modulated.
desired_rechannels = ...
    { 'CH_020', 'CH_021', 'CH_022',   'CH_024', 'CH_026', 'CH_027', ...
      'CH_028', 'CH_030', 'CH_035',   'CH_042', 'CH_060', 'CH_019', ...
      'CH_043', ...
      'CH_071', 'CH_072', 'CH_073',   'CH_075', 'CH_100', 'CH_101', ...
      'CH_106', 'CH_107', 'CH_117',   'CH_116', 'CH_120', 'CH_125', ...
      'CH_067', 'CH_123', 'CH_109',   'CH_122' };

% These structures describe which TTL bit-lines in the recorder and
% stimulator encode which event signals for this dataset.

recbitsignals = struct();
stimbitsignals = struct('stimrwdB', 'Din_002');

% These structures describe which TTL bit-lines or word data channels
% encode event codes for the recorder and stimulator.
% Note that Open Ephys word data starts with bit 0 and Intan bit lines
% start with bit 1. So Open Ephys code words are shifted by 8 bits and
% Intan code words are shifted by 9 bits to get the same data.

reccodesignals = struct( ...
  'signameraw', 'reccodes_raw', 'signamecooked', 'reccodes', ...
  'channame', 'DigWordsA_000', 'bitshift', 8 );
stimcodesignals = struct( ...
  'signameraw', 'stimcodes_raw', 'signamecooked', 'stimcodes', ...
  'channame', 'Din_*', 'bitshift', 9 );


% Debug switches for testing.

debug_skip_gaze_and_frame = true;



%
% Paths.

% Adjust these to match your development environment.

addpath('lib-exp-utils-cjt');
addpath('lib-looputil');
addpath('lib-fieldtrip');
addpath('lib-openephys');
addpath('lib-npy-matlab');

% This automatically adds sub-folders.
addPathsExpUtilsCjt;
addPathsLoopUtil;



%
% Start Field Trip.

% Wrapping this to suppress the annoying banner.
evalc('ft_defaults');

% Suppress spammy Field Trip notifications.
ft_notice('off');
ft_info('off');
ft_warning('off');



%
% Other setup.

% Suppress Matlab warnings (the NPy library generates these).
oldwarnstate = warning('off');

% Limit the number of channels LoopUtil will load into memory at a time.
% Raw data takes up about 1 GB per channel-hour.
nlFT_setMemChans(8);



%
% Read metadata (paths, headers, and channel lists).

% Get paths to individual devices.

[ folders_openephys folders_intanrec folders_intanstim folders_unity ] = ...
  euUtil_getExperimentFolders(inputfolder);

% FIXME - For now, assume we're using Open Ephys for the recorder.
% FIXME - Assume one recorder dataset and 0 or 1 stimulator datasets.
folder_record = folders_openephys{1};
folder_stim = '';
if ~isempty(folders_intanstim)
  folder_stim = folders_intanstim{1};
end
folder_game = folders_unity{1};


% Get headers.

% NOTE - Field Trip will throw an exception if this fails.
% Add a try/catch block if you want to fail gracefully.
rechdr = ft_read_header( folder_record, 'headerformat', 'nlFT_readHeader' );
stimhdr = ft_read_header( folder_stim, 'headerformat', 'nlFT_readHeader' );


% Figure out what channels we want.

[ pat_ephys pat_digital pat_stimcurrent pat_stimflags ] = ...
  euFT_getChannelNamePatterns();

rec_channels_ephys = ft_channelselection( pat_ephys, rechdr.label, {} );
rec_channels_digital = ft_channelselection( pat_digital, rechdr.label, {} );

stim_channels_ephys = ft_channelselection( pat_ephys, stimhdr.label, {} );
stim_channels_digital = ft_channelselection( pat_digital, stimhdr.label, {} );
stim_channels_current = ...
  ft_channelselection( pat_stimcurrent, stimhdr.label, {} );
stim_channels_flags = ft_channelselection( pat_stimflags, stimhdr.label, {} );



%
% Read events.

% Use the default settings for this.

% Read USE and SynchBox events. This also fetches the code definitions.
% This returns each device's event tables as structure fields.
% This also gives its own banner, so we don't need to print one.
[ boxevents gameevents evcodedefs ] = euUSE_readAllUSEEvents(folder_game);

% Now that we have the code definitions, read events and codes from the
% recorder and stimulator.

% These each return a table of TTL events, and a structure with tables for
% each extracted signal we asked for.

[ recevents_ttl recevents ] = euUSE_readAllEphysEvents( ...
  folder_record, recbitsignals, reccodesignals, evcodedefs );

if isempty(folder_stim)
  stimevents_ttl = table();
  stimevents = struct();
else
  [ stimevents_ttl stimevents ] = euUSE_readAllEphysEvents( ...
    folder_stim, stimbitsignals, stimcodesignals, evcodedefs );
end

% Read USE gaze and framedata tables.
% These return concatenated table data from the relevant USE folders.
% These take a while, so stub them out for testing.
gamegaze_raw = table();
gameframedata_raw = table();
if ~debug_skip_gaze_and_frame
  disp('-- Reading USE gaze data.');
  gamegaze_raw = euUSE_readRawGazeData(folder_game);
  disp('-- Reading USE frame data.');
  gameframedata_raw = euUSE_readRawFrameData(folder_game);
  disp('-- Finished reading USE gaze and frame data.');
end


% Report what we found from each device.

helper_reportEvents('.. From SynchBox:', boxevents);
helper_reportEvents('.. From USE:', gameevents);
helper_reportEvents('.. From recorder:', recevents);
helper_reportEvents('.. From stimulator:', stimevents);


%
% Clean up timestamps.

% Subtract the enormous offset from the Unity timestamps.
% Unity timestamps start at 1 Jan 1970 by default.

[ unityreftime gameevents ] = ...
  euUSE_removeLargeTimeOffset( gameevents, 'unityTime' );
% We have a reference time now; use it instead of picking a new one.
[ unityreftime boxevents ] = ...
  euUSE_removeLargeTimeOffset( boxevents, 'unityTime', unityreftime );


% Add a "timestamp in seconds" column to the ephys signal tables.

recevents = ...
  euFT_addEventTimestamps( recevents, rechdr.Fs, 'sample', 'recTime' );
stimevents = ...
  euFT_addEventTimestamps( stimevents, stimhdr.Fs, 'sample', 'stimTime' );



%
% Helper functions.


% This writes event counts from a specific device to the console.
% Input is a structure containing zero or more tables of events.

function helper_reportEvents(prefix, eventstruct)
  msgtext = prefix;

  evsigs = fieldnames(eventstruct);
  for evidx = 1:length(evsigs)
    thislabel = evsigs{evidx};
    thisdata = eventstruct.(thislabel);
    msgtext = [ msgtext sprintf('  %d %s', height(thisdata), thislabel) ];
  end

  disp(msgtext);
end



%
% This is the end of the file.
