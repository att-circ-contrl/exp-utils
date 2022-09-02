% Short Field Trip example script.
% Written by Christopher Thomas.


%
% Configuration constants.

% Change these to specify what you want to do.


% Folders.

plotdir = 'plots';
outdatadir = 'output';

inputfolder = 'datasets/20220504-frey-silicon';


% Channels we care about.

% These are the channels that Louie flagged as particularly interesting.
% Louie says that channel 106 in particular was task-modulated.
desired_recchannels = ...
  { 'CH_020', 'CH_021', 'CH_022',   'CH_024', 'CH_026', 'CH_027', ...
    'CH_028', 'CH_030', 'CH_035',   'CH_042', 'CH_060', 'CH_019', ...
    'CH_043', ...
    'CH_071', 'CH_072', 'CH_073',   'CH_075', 'CH_100', 'CH_101', ...
    'CH_106', 'CH_107', 'CH_117',   'CH_116', 'CH_120', 'CH_125', ...
    'CH_067', 'CH_123', 'CH_109',   'CH_122' };

desired_stimchannels = {};


% Where to look for event codes and TTL signals in the ephys data.

% These structures describe which TTL bit-lines in the recorder and
% stimulator encode which event signals for this dataset.

recbitsignals = struct();
stimbitsignals = struct('rwdB', 'Din_002');

% These structures describe which TTL bit-lines or word data channels
% encode event codes for the recorder and stimulator.
% Note that Open Ephys word data starts with bit 0 and Intan bit lines
% start with bit 1. So Open Ephys code words are shifted by 8 bits and
% Intan code words are shifted by 9 bits to get the same data.

reccodesignals = struct( ...
  'signameraw', 'rawcodes', 'signamecooked', 'cookedcodes', ...
  'channame', 'DigWordsA_000', 'bitshift', 8 );
stimcodesignals = struct( ...
  'signameraw', 'rawcodes', 'signamecooked', 'cookedcodes', ...
  'channame', 'Din_*', 'bitshift', 9 );


% How to define trials.

% This is the code we want to be at time zero.
trial_align_evcode = 'StimOn';

% These are codes that carry extra metadata that we want to save; they'll
% show up in "trialinfo" after processing (and in "trl" before that).
trial_metadata_events = ...
  struct( 'trialnum', 'TrialNumber', 'trialindex', 'TrialIndex' );

% This is how much padding we want before 'TrlStart' and after 'TrlEnd'.
padtime = 3.0;


% Narrow-band frequencies to filter out.

% We have power line peaks at 60 Hz and its harmonics, and also often
% have a peak at around 600 Hz and its harmonics.

notch_filter_freqs = [ 60, 120, 180 ];
notch_filter_bandwidth = 2.0;


% Frequency cutoffs for getting the LFP, spike, and rectified signals.

% The LFP signal is low-pass filtered and downsampled. Typical features are
% in the range of 2 Hz to 200 Hz.

lfp_maxfreq = 300;
lfp_samprate = 2000;

% The spike signal is high-pass filtered. Typical features have a time scale
% of 1 ms or less, but there's often a broad tail lasting several ms.

spike_minfreq = 100;

% The rectified signal is a measure of spiking activity. The signal is
% band-pass filtered, then rectified (absolute value), then low-pass filtered
% at a frequency well below the lower corner, then downsampled.

rect_bandfreqs = [ 1000 3000 ];
rect_lowpassfreq = 500;
rect_samprate = lfp_samprate;


% Nominal frequency for reading gaze data.

% As long as this is higher than the device's sampling rate (300-600 Hz),
% it doesn't really matter what it is.
% The gaze data itself is non-uniformly sampled.

gaze_samprate = lfp_samprate;


% Debug switches for testing.

debug_skip_gaze_and_frame = true;

debug_use_fewer_trials = true;
debug_trials_to_use = 30;



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
% 30 ksps double-precision data takes up about 1 GB per channel-hour.
nlFT_setMemChans(8);



%
% Read metadata (paths, headers, and channel lists).

% Get paths to individual devices.

[ folders_openephys folders_intanrec folders_intanstim folders_unity ] = ...
  euUtil_getExperimentFolders(inputfolder);

% FIXME - For now, assume we're using Open Ephys for the recorder.
% FIXME - Assume one recorder dataset and 0 or 1 stimulator datasets.
folder_record = folders_openephys{1};
have_stim = false;
if ~isempty(folders_intanstim)
  folder_stim = folders_intanstim{1};
  have_stim = true;
end
folder_game = folders_unity{1};


% Get headers.

% NOTE - Field Trip will throw an exception if this fails.
% Add a try/catch block if you want to fail gracefully.
rechdr = ft_read_header( folder_record, 'headerformat', 'nlFT_readHeader' );
if have_stim
  stimhdr = ft_read_header( folder_stim, 'headerformat', 'nlFT_readHeader' );
end


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

% Keep desired channels that match actual channels.
% FIXME - Ignoring stimulation current and flags!
desired_recchannels = ...
  desired_recchannels( ismember(desired_recchannels, rec_channels_ephys) );
desired_stimchannels = ...
  desired_stimchannels( ismember(desired_stimchannels, stim_channels_ephys) );



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

if have_stim
  [ stimevents_ttl stimevents ] = euUSE_readAllEphysEvents( ...
    folder_stim, stimbitsignals, stimcodesignals, evcodedefs );
end

% Read USE gaze and framedata tables.
% These return concatenated table data from the relevant USE folders.
% These take a while, so stub them out for testing.
gamegazedata = table();
gameframedata = table();
if ~debug_skip_gaze_and_frame
  disp('-- Reading USE gaze data.');
  gamegazedata = euUSE_readRawGazeData(folder_game);
  disp('-- Reading USE frame data.');
  gameframedata = euUSE_readRawFrameData(folder_game);
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
% Do time alignment.

% Default alignment config is fine.
alignconfig = struct();

% Just align using event codes. Falling back to reward pulses takes too long.


disp('.. Propagating recorder timestamps to SynchBox.');

% Use raw code bytes for this, to avoid glitching from missing box codes.
eventtables = { recevents.rawcodes, boxevents.rawcodes };
[ newtables times_recorder_synchbox ] = euUSE_alignTwoDevices( ...
  eventtables, 'recTime', 'synchBoxTime', alignconfig );

boxevents = euAlign_addTimesToAllTables( ...
  boxevents, 'synchBoxTime', 'recTime', times_recorder_synchbox );


disp('.. Propagating recorder timestamps to USE.');

% Use cooked codes for this, since both sides have a complete event list.
eventtables = { recevents.cookedcodes, gameevents.cookedcodes };
[ newtables times_recorder_game ] = euUSE_alignTwoDevices( ...
  eventtables, 'recTime', 'unityTime', alignconfig );

gameevents = euAlign_addTimesToAllTables( ...
  gameevents, 'unityTime', 'recTime', times_recorder_game );


if have_stim
  disp('.. Propagating recorder timestamps to stimulator.');

  % The old test script aligned using SynchBox TTL signals as a fallback.
  % Since we're only using codes here, we don't have a fallback option. Use
  % event codes or fail.

  eventtables = { recevents.cookedcodes, stimevents.cookedcodes };
  [ newtables times_recorder_stimulator ] = euUSE_alignTwoDevices( ...
    eventtables, 'recTime', 'stimTime', alignconfig );

  stimevents = euAlign_addTimesToAllTables( ...
    stimevents, 'stimTime', 'recTime', times_recorder_stimulator );
end


if ~debug_skip_gaze_and_frame

  % First, make "eyeTime" and "unityTime" columns.
  % Remember to subtract the offset from Unity timestamps.

  gameframedata.eyeTime = gameframedata.EyetrackerTimeSeconds;
  gameframedata.unityTime = ...
    gameframedata.SystemTimeSeconds - unityreftime;

  gamegazedata.eyeTime = gamegazedata.time_seconds;


  % Get alignment information for Unity and eye-tracker timestamps.
  % This information is already in gameframedata; we just have to extract
  % it.

  % Timestamps are not guaranteed to be unique, so filter them.
  times_game_eyetracker = euAlign_getUniqueTimestampTuples( ...
    gameframedata, {'unityTime', 'eyeTime'} );


  % Unity timestamps are unique but ET timestamps aren't.
  % Interpolate new ET timestamps from the Unity timestamps.

  disp('.. Cleaning up eye tracker timestamps in frame data.');

  gameframedata = euAlign_addTimesToTable( gameframedata, ...
    'unityTime', 'eyeTime', times_game_eyetracker );


  % Add recorder timestamps to game and frame data tables.
  % To do this, we'll also have to augment gaze data with unity timestamps.

  disp('.. Propagating recorder timestamps to frame data table.');

  gameframedata = euAlign_addTimesToTable( gameframedata, ...
    'unityTime', 'recTime', times_recorder_game );

  disp('.. Propagating Unity and recorder timestamps to gaze data table.');

  gamegazedata = euAlign_addTimesToTable( gamegazedata, ...
    'eyeTime', 'unityTime', times_game_eyetracker );
  gamegazedata = euAlign_addTimesToTable( gamegazedata, ...
    'unityTime', 'recTime', times_recorder_game );

end


disp('.. Finished time alignment.');



%
% Get trial definitions.

% Get event code sequences for "valid" trials (ones where "TrialNumber"
% increased afterwards).

[ trialcodes_each trialcodes_concat ] = euUSE_segmentTrialsByCodes( ...
  gameevents.cookedcodes, 'codeLabel', 'codeData', true );


% FIXME - For debugging (faster and less memory), keep only a few trials.

if debug_use_fewer_trials
  trialcount = length(trialcodes_each);
  if trialcount > debug_trials_to_use
    firsttrial = round(0.5 * (trialcount - debug_trials_to_use));
    lasttrial = firsttrial + debug_trials_to_use - 1;
    firsttrial = max(firsttrial, 1);
    lasttrial = min(lasttrial, trialcount);

    trialcodes_each = trialcodes_each(firsttrial:lasttrial);
    trialcodes_concat = vertcat(trialcodes_each{:});
  end
end


% Get trial definitions.
% This replaces ft_definetrial().

[ rectrialdefs rectrialdeftable ] = euFT_defineTrialsUsingCodes( ...
  trialcodes_concat, 'codeLabel', 'recTime', rechdr.Fs, ...
  padtime, padtime, 'TrlStart', 'TrlEnd', trial_align_evcode, ...
  trial_metadata_events, 'codeData' );

if have_stim
  trialcodes_concat = euAlign_addTimesToTable( trialcodes_concat, ...
    'recTime', 'stimTime', times_recorder_stimulator );

  [ stimtrialdefs stimtrialdeftable ] = euFT_defineTrialsUsingCodes( ...
    trialcodes_concat, 'codeLabel', 'stimTime', stimhdr.Fs, ...
    padtime, padtime, 'TrlStart', 'TrlEnd', trial_align_evcode, ...
    trial_metadata_events, 'codeData' );
end


% NOTE - You'd normally discard known artifact trials here.



%
% Read the ephys data.

% NOTE - We're reading everything into memory at once. This will only work
% if we have few enough channels to fit in memory. To process more data,
% either read it a few trials at a time or a few channels at a time or at
% a lower sampling rate.

% NOTE - For demonstration purposes, I'm just processing recorder series
% here. For stimulator series, use "stimtrialdefs" and "desired_stimchannels".


% First step: Get wideband data into memory and remove any global ramp.

preproc_config = ...
{ 'headerfile', folder_record, 'datafile', folder_record, ...
  'headerformat', 'nlFT_readHeader', 'dataformat', 'nlFT_readDataDouble', ...
  'trl', rectrialdefs, 'channel', desired_recchannels, ...
  'detrend', 'yes', 'feedback', 'text' };

disp('.. Reading wideband recorder data.');
recdata_wideband = ft_preprocessing( preproc_config );


% NOTE - You'd normally do re-referencing here.


% Second step: Do notch filtering using our own filter, as FT's brick wall
% filter acts up as of 2021.

disp('.. Performing notch filtering (recorder).');
recdata_wideband = euFT_doBrickNotchRemoval( ...
  recdata_wideband, notch_filter_freqs, notch_filter_bandwidth );


% Third step: Get derived signals (LFP, spike, and rectified activity).

disp('.. Getting LFP, spike, and rectified activity signals.');

[ recdata_lfp, recdata_spike, recdata_activity ] = euFT_getDerivedSignals( ...
  recdata_wideband, lfp_maxfreq, lfp_samprate, spike_minfreq, ...
  rect_bandfreqs, rect_lowpassfreq, rect_samprate, false);


% Fourth step: Pull in gaze data as well.

if ~debug_skip_gaze_and_frame
  disp('.. Reading and resampling gaze data.');
end

% FIXME - Stopped here.



%
% Done.


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
