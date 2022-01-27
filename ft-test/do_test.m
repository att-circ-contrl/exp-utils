% Field Trip sample script / test script.
% Written by Christopher Thomas.


%
% Paths.

% First step: Add the library root folders.
% These should be changed to match your system's locations, or you can set
% them as part of Matlab's global configuration.

addpath('lib-exp-utils-cjt');
addpath('lib-looputil');
addpath('lib-fieldtrip');
addpath('lib-openephys');
addpath('lib-npy-matlab');

% Second step: Call various functions to add library sub-folders.

addPathsExpUtilsCjt;
addPathsLoopUtil;

% Wrap this in "evalc" to avoid the annoying banner.
evalc('ft_defaults');



%
% Load configuration parameters.

do_test_config;

% This loads dataset information, but we still have to pick a dataset.
do_test_datasets;


% Pick the dataset we want to use.

thisdataset = dataset_big_silicon;



%
% Initial setup.


% Set the number of channels we want in memory at any given time.
nlFT_setMemChans(memchans);


% Turn off FT notification messages. Otherwise they get spammy.
ft_notice('off');
ft_info('off');

% FIXME - Suppress warnings too.
% Among other things, when preprocessing the auto-generated configs have
% deprecated fields that generate lots of warnings.
ft_warning('off');



%
% Read the dataset using ft_preprocessing().


% NOTE - Field Trip will throw an exception if this fails. Wrap this to
% catch exceptions.

is_ok = true;
try

  % Read the headers. This gives us the channel lists.

  if thisdataset.use_looputil
    rechdr = ft_read_header( thisdataset.recfile, ...
      'headerformat', 'nlFT_readHeader' );
    stimhdr = ft_read_header( thisdataset.stimfile, ...
      'headerformat', 'nlFT_readHeader' );
  else
    rechdr = ft_read_header( thisdataset.recfile );
    stimhdr = ft_read_header( thisdataset.stimfile );
  end


  % Get the names of the types of channels we want.

  % FIXME - Blithely assuming that we can fit digital I/O channels in RAM.
  % FIXME - Not filtering stimulation current or flag data for now.

  rec_channels_record = ...
    ft_channelselection( name_patterns_record, rechdr.label, {} );
  if isfield( thisdataset, 'channels_rec' )
    rec_channels_record = ...
      ft_channelselection( thisdataset.channels_rec, rechdr.label, {} );
  end
  rec_channels_digital = ...
    ft_channelselection( name_patterns_digital, rechdr.label, {} );

  stim_channels_record = ...
    ft_channelselection( name_patterns_record, stimhdr.label, {} );
  if isfield( thisdataset, 'channels_stim' )
    stim_channels_record = ...
      ft_channelselection( thisdataset.channels_stim, stimhdr.label, {} );
  end
  stim_channels_digital = ...
    ft_channelselection( name_patterns_digital, stimhdr.label, {} );

  stim_channels_current = ...
    ft_channelselection( name_patterns_stim_current, stimhdr.label, {} );
  stim_channels_flags = ...
    ft_channelselection( name_patterns_stim_flags, stimhdr.label, {} );


  % Suppress data types we don't want.

  if ~want_data_ephys
    rec_channels_record = {};
    stim_channels_record = {};
  end

  if ~want_data_ttl
    rec_channels_digital = {};
    stim_channels_digital = {};
  end

  if ~want_data_stim
    stim_channels_current = {};
    stim_channels_flags = {};
  end


  % FIXME - Passing an empty channel list to ft_preprocessing results in
  % all channels being read. Modify these to contain a bogus name instead.

  % FIXME - ft_preprocessing throws an exception if it didn't read data.
  % Instead, just skip reading a given element if there are no channels.


  % Read this dataset.

  % NOTE - We're reading several different types of signal separately.
  % For each call to ft_preprocessing, we have to build a configuration
  % structure specifying what we want to read.
  % The only part that changes is "channel" (the channel name list).

  preproc_config_rec = struct( ...
    'datafile', thisdataset.recfile, 'headerfile', thisdataset.recfile );
  preproc_config_stim = struct( ...
    'datafile', thisdataset.stimfile, 'headerfile', thisdataset.stimfile );

  if thisdataset.use_looputil
    % NOTE - Promoting everything to double-precision floating-point.
    % It might be better to keep TTL signals in native format.

    preproc_config_rec.headerformat = 'nlFT_readHeader';
    preproc_config_rec.dataformat = 'nlFT_readDataDouble';

    preproc_config_stim.headerformat = 'nlFT_readHeader';
    preproc_config_stim.dataformat = 'nlFT_readDataDouble';
  end

  if isfield(thisdataset, 'timerange')

    % Define a single trial to get windowed continuous data.
    % FIXME - Not aligning the recorder and stimulator!

    disp(sprintf( '.. Windowing to %.1f - %.1f seconds.', ...
      min(thisdataset.timerange), max(thisdataset.timerange) ));


    firstsamp = round( min(thisdataset.timerange) * rechdr.Fs );
    firstsamp = min(firstsamp, rechdr.nSamples);
    firstsamp = max(firstsamp, 1);

    lastsamp = round ( max(thisdataset.timerange) * rechdr.Fs );
    lastsamp = min(lastsamp, rechdr.nSamples);
    lastsamp = max(lastsamp, 1);

    preproc_config_rec.trl = [ firstsamp lastsamp 0 ];


    firstsamp = round( min(thisdataset.timerange) * stimhdr.Fs );
    firstsamp = min(firstsamp, stimhdr.nSamples);
    firstsamp = max(firstsamp, 1);

    lastsamp = round ( max(thisdataset.timerange) * stimhdr.Fs );
    lastsamp = min(lastsamp, stimhdr.nSamples);
    lastsamp = max(lastsamp, 1);

    preproc_config_stim.trl = [ firstsamp lastsamp 0 ];

  end


  % Banner.
  disp(sprintf('== Reading "%s".', thisdataset.title));


  disp('-- Reading ephys amplifier data.');
  tic();

  % NOTE - Reading as double. This will be big!

  have_recdata_rec = false;
  if isempty(rec_channels_record)
    disp('.. Skipping recorder (no channels selected).');
  else
    preproc_config_rec.channel = rec_channels_record;
    recdata_rec = ft_preprocessing(preproc_config_rec);
    have_recdata_rec = true;
  end

  have_stimdata_rec = false;
  if isempty(stim_channels_record)
    disp('.. Skipping stimulator (no channels selected).');
  else
    preproc_config_stim.channel = stim_channels_record;
    stimdata_rec = ft_preprocessing(preproc_config_stim);
    have_stimdata_rec = true;
  end

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. Read in %s.', thisduration ));


  disp('-- Reading digital data.');
  tic();

  have_recdata_dig = false;
  if isempty(rec_channels_digital)
    disp('.. Skipping recorder (no channels selected).');
  else
    preproc_config_rec.channel = rec_channels_digital;
    recdata_dig = ft_preprocessing(preproc_config_rec);
    have_recdata_dig = true;
  end

  have_stimdata_dig = false;
  if isempty(stim_channels_digital)
    disp('.. Skipping stimulator (no channels selected).');
  else
    preproc_config_stim.channel = stim_channels_digital;
    stimdata_dig = ft_preprocessing(preproc_config_stim);
    have_stimdata_dig = true;
  end

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. Read in %s.', thisduration ));


  disp('-- Reading digital events.');
  tic();

  have_recevents_dig = false;
  have_stimevents_dig = false;
  if ~want_data_events
    disp('.. Skipping events.');
  else
    % FIXME - Glom everything using my internal hook instead of FT's hook.
    recevents_dig = nlFT_readAllEvents(thisdataset.recfile, false);
    stimevents_dig = nlFT_readAllEvents(thisdataset.stimfile, true);
    have_recevents_dig = true;
    have_stimevents_dig = true;
% FIXME - Events NYI.
  end

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. Read in %s.', thisduration ));


  disp('-- Reading stimulation data.');
  tic();

  have_stimdata_current = false;
  if isempty(stim_channels_current)
    disp('.. Skipping stimulation current (no channels selected).');
  else
    preproc_config_stim.channel = stim_channels_current;
    stimdata_current = ft_preprocessing(preproc_config_stim);
    have_stimdata_current = true;
  end

  % NOTE - Reading flags as double. We can still perform bitwise operations
  % on them.
  have_stimdata_flags = false;
  if isempty(stim_channels_flags)
    disp('.. Skipping stimulation flags (no channels selected).');
  else
    preproc_config_stim.channel = stim_channels_flags;
    stimdata_flags = ft_preprocessing(preproc_config_stim);
    have_stimdata_flags = true;
  end

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. Read in %s.', thisduration ));


  % Done.
  disp(sprintf('== Finished reading "%s".', thisdataset.title));


catch errordetails
  is_ok = false;
  disp(sprintf( ...
    '###  Exception thrown while reading "%s".', thisdataset.title));
  disp(sprintf('Message: "%s"', errordetails.message));
end



%
% Filter the continuous ephys data.


% FIXME - Just dealing with recorder channels, not stimulator channels.
% To aggregate both, we'd need to do artifact removal and notch filtering
% and re-referencing on both, then do time alignment.
% After that, we can use ft_appenddata().

have_analog = false;

if is_ok && have_recdata_rec

  have_analog = true;

  % Power-line filtering.

  filt_power = euFT_getFiltPowerLong(power_freq, power_filter_modes);
  if want_power_filter_thilo
    filt_power = euFT_getFiltPowerTW(power_freq, power_filter_modes);
  end

  disp('.. Removing power-line noise.');
  tic();
  recdata_rec = ft_preprocessing(filt_power, recdata_rec);
  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. Power line noise removed in %s.', thisduration ));


  % Artifact removal.

  % FIXME - NYI.
  disp('###  Artifact removal NYI!');


  % Re-referencing.

  % FIXME - NYI.
  disp('###  Rereferencing NYI!');


  % De-trending.

  % FIXME - NYI.
  disp('###  De-trending NYI!');


  %
  % Get spike and LFP and rectified waveforms.


  % Copy the wideband signals.

  % FIXME - We should append stimulator data to this!
  data_wideband = recdata_rec;


  % Produce LFP signals.

  filtconfig = ...
    struct( 'lpfilter', 'yes', 'lpfilttype', 'but', 'lpfreq', lfp_corner );
  resampleconfig = struct( 'resamplefs', lfp_rate, 'detrend', 'no' );

  disp('.. Generating LFP data series.');
  tic();
  data_lfp = ft_preprocessing(filtconfig, data_wideband);
  data_lfp = ft_resampledata(resampleconfig, data_lfp);
  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. LFP series generated in %s.', thisduration ));


  % Produce spike signals.

  filtconfig = struct( ...
    'hpfilter', 'yes', 'hpfilttype', 'but', 'hpfreq', spike_corner );

  disp('.. Generating spike data series.');
  tic();
  data_spike = ft_preprocessing(filtconfig, data_wideband);
  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. Spike series generated in %s.', thisduration ));


  % Produce rectified activity signal.

  filtconfigband = struct( 'bpfilter', 'yes', 'bpfilttype', 'but', ...
    'bpfreq', [ min(rect_corners), max(rect_corners) ] );
  rectconfig = struct('rectify', 'yes');
  filtconfiglow = struct( ...
    'lpfilter', 'yes', 'lpfilttype', 'but', 'lpfreq', rect_lowpass );
  resampleconfig = struct( 'resamplefs', rect_rate, 'detrend', 'no' );

  disp('.. Generating rectified activity data series.');
  tic();

  % FIXME - We can group some of these calls, but that requires detailed
  % knowledge of the order in which FT applies preprocessing operations.
  % Do them individually for safety's sake.

  data_rect = ft_preprocessing(filtconfigband, data_wideband);
  data_rect = ft_preprocessing(rectconfig, data_rect);
  data_rect = ft_preprocessing(filtconfiglow, data_rect);
  data_rect = ft_resampledata(resampleconfig, data_rect);

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. Rectified series generated in %s.', thisduration ));


  % Done.

end



%
% Inspect the data.

% FIXME - Just pulling up data browser windows as an interim measure.

if want_browser

  % Analog data.

  if have_analog
    % FIXME - The saved configuration might be re-filtering the data!
    % It _shouldn't_ be rereading, but it's doing _something_.

    ft_databrowser(data_wideband.cfg, data_wideband);
    set(gcf(), 'Name', 'Wideband', 'NumberTitle', 'off');
    ft_databrowser(data_lfp.cfg, data_lfp);
    set(gcf(), 'Name', 'LFP', 'NumberTitle', 'off');
    ft_databrowser(data_spike.cfg, data_spike);
    set(gcf(), 'Name', 'Spikes', 'NumberTitle', 'off');
    ft_databrowser(data_rect.cfg, data_rect);
    set(gcf(), 'Name', 'Rectified', 'NumberTitle', 'off');
  end


  % Continuous digital data.

  if have_recdata_dig
    ft_databrowser(recdata_dig.cfg, recdata_dig);
    set(gcf(), 'Name', 'Recorder TTL', 'NumberTitle', 'off');
  end
  if have_stimdata_dig
    ft_databrowser(stimdata_dig.cfg, stimdata_dig);
    set(gcf(), 'Name', 'Stimulator TTL', 'NumberTitle', 'off');
  end

end


%
% This is the end of the file.
