% Field Trip sample script / test script - Dataset definitions.
% Written by Christopher Thomas.

% Dataset definitions are structures containing various metadata about each
% dataset we might want to process.


%
% Short datasets for format testing.


% Intan monolithic format.

srcdir = [ 'datasets-intan', filesep, 'MonolithicIntan_format' ];
dataset_intan_monolithic = struct( ...
  'title', 'Intan Monolithic', 'label', 'intanmono', ...
  'recfile', [ srcdir, filesep, 'record_211206_171502.rhd' ], ...
  'stimfile', [ srcdir, filesep, 'stim_211206_171502.rhs' ], ...
  'use_looputil', true );


% Intan one-file-per-type format.

srcdir = [ 'datasets-intan', filesep, 'OneFilePerTypeOfChannel_format' ];
dataset_intan_pertype = struct( ...
  'title', 'Intan Per-Type', 'label', 'intanpertype', ...
  'recfile', [ srcdir, filesep, 'record_211206_172518' ], ...
  'stimfile', [ srcdir, filesep, 'stim_211206_172519' ], ...
  'use_looputil', true );


% Intan one-file-per-channel format.

srcdir = [ 'datasets-intan', filesep, 'OneFilePerChannel_format' ];
dataset_intan_perchan = struct( ...
  'title', 'Intan Per-Channel', 'label', 'intanperchan', ...
  'recfile', [ srcdir, filesep, 'record_211206_172734' ], ...
  'stimfile', [ srcdir, filesep, 'stim_211206_172734' ], ...
  'use_looputil', true );

% Add "zoom" case.
if want_detail_zoom
  dataset_intan_perchan.timerange = [ 4.0 6.0 ];
end


% Intan monolithic format converted to Plexon .NEX or .NEX5.

srcdir = [ 'datasets-intan', filesep, 'MonolithicIntan_Plexon' ];
dataset_intan_plexon = struct( ...
  'title', 'Intan (converted to NEX)', 'label', 'intanplexon', ...
  'recfile', [ srcdir, filesep, 'record_211206_171502.nex' ], ...
  'stimfile', [ srcdir, filesep, 'stim_211206_171502.nex' ], ...
  'use_looputil', false );

dataset_intan_plexon_nex5 = dataset_intan_plexon;
dataset_intan_plexon_nex5.recfile = ...
  [ srcdir, filesep, 'record_211206_171502.nex5' ];


% Open Ephys monolithic format.

srcdir = [ 'datasets-openephys', filesep, ...
  'OEBinary_IntanStimOneFilePerChannel_format' ];

% NOTE - Pointing to directory, not "structure.oebin".

dataset_openephys_monolithic = struct( ...
  'title', 'Open Ephys Monolithic', 'label', 'openmono', ...
  'recfile', [ srcdir, filesep, ...
    '2021-12-17_14-47-00', filesep, 'Record Node 101', filesep, ...
    'experiment1', filesep, 'recording1' ], ...
  'stimfile', [ srcdir, filesep, 'stim_211217_144659' ], ...
  'use_looputil', true );

% Add "zoom" case.
if want_detail_zoom
  dataset_openephys_monolithic.timerange = [ 12.0 14.0 ];
end


% Open Ephys one-file-per-channel format.

srcdir = [ 'datasets-openephys', filesep, ...
  'OEOpenEphys_IntanStimOneFilePerChannel_format' ];
dataset_openephys_perchan = struct( ...
  'title', 'Open Ephys Per-Channel', 'label', 'openperchan', ...
  'recfile', [ srcdir, filesep, ...
    '2021-12-17_14-47-00', filesep, 'Record Node 101' ], ...
  'stimfile', [ srcdir, filesep, 'stim_211217_150043' ], ...
  'use_looputil', true );


% Open Ephys monolithic converted to Plexon .PLX format.

% FIXME - Open Ephys Plexon NYI.



%
% Large datasets.


% 2021 November 12 tungsten recording (has stimulation).

srcdir = [ 'datasets-big', filesep, '20211112-frey-tungsten' ];
dataset_big_tungsten = struct( ...
  'title', '2021 Nov 12 Frey Tungsten', 'label', 'freytungsten', ...
  'recfile', [ srcdir, filesep, 'record_211112_112922' ], ...
  'stimfile', [ srcdir, filesep, 'stim_211112_112924' ], ...
  'unityfile', [ srcdir, filesep, 'Session4__12_11_2021__11_29_57', ...
    filesep, 'RuntimeData' ], ...
  'synchbox', struct( 'reccodebits', 'Din_*', 'recshift', 8, ...
     'stimrwdB', 'Din_002' ), ...
  'use_looputil', true );

% FIXME - Manually adding a filter for beat frequency noise.
dataset_big_tungsten.extra_notches = [ 561.6 ];

% These are the channels that were actually used.
chansrec = { 'AmpA_045', 'AmpA_047' };
chansstim = { 'AmpC_011' };

if ~want_chan_include_unused
  dataset_big_tungsten.channels_rec = chansrec;
  dataset_big_tungsten.channels_stim = chansstim;

  % We can use common-average referencing on the recording channels, but
  % we only have a single stimulation channel.
  dataset_big_tungsten.commonrefs_rec = { chansrec };
end

% Crop the dataset if desired.

if want_crop_big
  % The full trace is about 5800 seconds long (1.6h).
%  crop_start = 1000.0;
  crop_start = 2000.0;
%  crop_start = 3000.0;
  dataset_big_tungsten.timerange = ...
    [ crop_start (crop_start + crop_window_seconds) ];
end

% Add "zoom" cases.

if want_detail_zoom
% FIXME - Detail zoom for Frey tungsten NYI.
end


% 2021 November 05 silicon recording (NOTE - has dropouts).

srcdir = [ 'datasets-big', filesep, '20211105-frey-silicon' ];

% NOTE - Pointing to directory, not "structure.oebin".

dataset_big_silicon_20211105 = struct( ...
  'title', '2021 Nov 05 Frey Silicon', 'label', 'freysilicon', ...
  'recfile', [ srcdir, filesep, ...
    '2021-11-05_11-55-08', filesep, 'Record Node 101', filesep, ...
    'experiment1', filesep, 'recording1' ], ...
  'stimfile', [ srcdir, filesep, 'stim_211105_115503' ], ...
  'unityfile', [ srcdir, filesep, 'Session17__05_11_2021__11_55_39', ...
    filesep, 'RuntimeData' ], ...
  'synchbox', struct( 'reccodes', 'DigWordsA_000', 'recshift', 8, ...
     'stimrwdB', 'Din_002' ), ...
  'use_looputil', true );

% Crop the dataset if desired.

if want_crop_big
  % The full trace is about 4300 seconds long (1.2h).
%  crop_start = 1000.0;
  crop_start = 2000.0;
%  crop_start = 3000.0;
  dataset_big_silicon_20211105.timerange = ...
    [ crop_start (crop_start + crop_window_seconds) ];
end

% Add "zoom" cases.

if want_detail_zoom
% FIXME - Detail zoom for Frey silicon NYI.
end

% Add "only a few channels" case.
% FIXME - Need to prune floating channels even without this!

if want_chan_subset
  % Filter analog channels on the recorder.
  dataset_big_silicon_20211105.channels_rec = ...
    { 'CH_001', 'CH_030', 'CH_070', 'CH_110' };
end


% 2021 November 11 silicon recording (NOTE - has dropouts).

srcdir = [ 'datasets-big', filesep, '20211111-frey-silicon' ];

% NOTE - Pointing to directory, not "structure.oebin".

dataset_big_silicon_20211111 = struct( ...
  'title', '2021 Nov 11 Frey Silicon', 'label', 'freysiliconbad', ...
  'recfile', [ srcdir, filesep, ...
    '2021-11-11_12-08-33', filesep, 'Record Node 101', filesep, ...
    'experiment2', filesep, 'recording1' ], ...
  'stimfile', [ srcdir, filesep, 'stim_211111_121220' ], ...
  'unityfile', [ srcdir, filesep, 'Session3__11_11_2021__12_12_49', ...
    filesep, 'RuntimeData' ], ...
  'synchbox', struct( 'reccodes', 'DigWordsA_000', 'recshift', 8, ...
     'stimrwdB', 'Din_002' ), ...
  'use_looputil', true );

% Crop the dataset if desired.

if want_crop_big
  % The full trace is about 4300 seconds long (1.2h).
%  crop_start = 1000.0;
  crop_start = 2000.0;
%  crop_start = 3000.0;
  dataset_big_silicon_20211111.timerange = ...
    [ crop_start (crop_start + crop_window_seconds) ];
end

% Add "zoom" cases.

if want_detail_zoom
% FIXME - Detail zoom for Frey silicon NYI.
end

% Add "only a few channels" case.
% FIXME - Need to prune floating channels even without this!

if want_chan_subset
  % Filter analog channels on the recorder.
  dataset_big_silicon_20211111.channels_rec = ...
    { 'CH_001', 'CH_030', 'CH_070', 'CH_110' };
end



%
% This is the end of the file.
