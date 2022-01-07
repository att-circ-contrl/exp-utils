% Field Trip sample script / test script.
% Written by Christopher Thomas.


%
% Configuration.

% Behavior switches.

% Use Thilo's comb-style DFT power filter instead of the time-domain one.
% This might introduce numerical noise in very long continuous data, but it's
% much faster than time-domain FIR filtering.
want_power_filter_thilo = true;


% Various magic values.

% The power frequency filter filters the fundamental mode and some of the
% harmonics of the power line frequency. Mode count should be 2-3 typically.
power_freq = 60.0;
power_filter_modes = 2;

% The LFP signal is low-pass-filtered and downsampled. Typical features are
% in the range of 2 Hz to 200 Hz.
% The DC component should have been removed in an earlier step.
lfp_corner = 300;
lfp_rate = 2000;

% The spike signal is high-pass-filtered. Typical features have a time scale
% of 1 ms or less, but there's often a broad tail lasting several ms.
spike_corner = 100;

% The rectified signal is a measure of spiking activity. The signal is
% band-pass filtered, then rectified (absolute value), then low-pass filtered
% at a frequency well below the lower corner, then downsampled.
rect_corners = [ 1000 3000 ];
rect_lowpass = 500;
rect_rate = 2000;


% Which datasets to use.

% Native Intan.
want_intan_monolithic = false;
want_intan_pertype = false;
want_intan_perchan = true;

% Native Open Ephys.
want_openephys_monolithic = false;

% Converted Intan.
want_intan_plexon = false;
want_intan_plexon_nex5 = false;

% Converted Open Ephys.
want_openephys_plexon = false;


% Various debugging tests.

% Test low-level reading functions.
want_test_read_lowlevel = false;

% Read all types of signal at once.
want_test_read_all = false;



%
% Paths.

% First step: Add the library root folders.
% These should be changed to match your system's locations, or you can set
% them as part of Matlab's global configuration.

addpath('lib-exp-utils-cjt');
addpath('lib-looputil');
addpath('lib-fieldtrip');

% Second step: Call various functions to add library sub-folders.

addPathsExpUtilsCjt;
addPathsLoopUtil;

% Wrap this in "evalc" to avoid the annoying banner.
evalc('ft_defaults');



%
% Set up our data processing cases so that we don't keep duplicating code.

datacases = struct([]);

if want_intan_monolithic
  srcdir = [ 'datasets', filesep, 'MonolithicIntan_format' ];
  thiscase = struct( ...
    'title', 'Intan Monolithic', 'label', 'intanmono', ...
    'recfile', [ srcdir, filesep, 'record_211206_171502.rhd' ], ...
    'stimfile', [ srcdir, filesep, 'stim_211206_171502.rhs' ], ...
    'use_looputil', true );

  if isempty(datacases)
    datacases = thiscase;
  else
    datacases(1 + length(datacases)) = thiscase;
  end
end

if want_intan_pertype
  srcdir = [ 'datasets', filesep, 'OneFilePerTypeOfChannel_format' ];
  thiscase = struct( ...
    'title', 'Intan Per-Type', 'label', 'intanpertype', ...
    'recfile', [ srcdir, filesep, 'record_211206_172518' ], ...
    'stimfile', [ srcdir, filesep, 'stim_211206_172519' ], ...
    'use_looputil', true );

  if isempty(datacases)
    datacases = thiscase;
  else
    datacases(1 + length(datacases)) = thiscase;
  end
end

if want_intan_perchan
  srcdir = [ 'datasets', filesep, 'OneFilePerChannel_format' ];
  thiscase = struct( ...
    'title', 'Intan Per-Channel', 'label', 'intanperchan', ...
    'recfile', [ srcdir, filesep, 'record_211206_172734' ], ...
    'stimfile', [ srcdir, filesep, 'stim_211206_172734' ], ...
    'use_looputil', true );

  if isempty(datacases)
    datacases = thiscase;
  else
    datacases(1 + length(datacases)) = thiscase;
  end
end

if want_intan_plexon
  srcdir = [ 'datasets', filesep, 'MonolithicIntan_Plexon' ];
  thiscase = struct( ...
    'title', 'Intan (converted to NEX)', 'label', 'intanplexon', ...
    'recfile', [ srcdir, filesep, 'record_211206_171502.nex' ], ...
    'stimfile', [ srcdir, filesep, 'stim_211206_171502.nex' ], ...
    'use_looputil', false );
  if want_intan_plexon_nex5
    thiscase.recfile = [ srcdir, filesep, 'record_211206_171502.nex5' ];
  end

  if isempty(datacases)
    datacases = thiscase;
  else
    datacases(1 + length(datacases)) = thiscase;
  end
end

if want_openephys_monolithic
  % FIXME - NYI.
  disp('###  FIXME - Open Ephys monolithic NYI.');
end

if want_openephys_plexon
  % FIXME - NYI.
  disp('###  FIXME - Open Ephys Plexon NYI.');
end



%
% Iterate through the datasets we're dealing with.


% NOTE - Turn off FT notification messages. Otherwise they get spammy.
ft_notice('off');
ft_info('off');


for didx = 1:length(datacases)

  thiscase = datacases(didx);


  %
  % Read the datasets using ft_preprocessing().
  % We'll need to read events separately.


  % NOTE - Field Trip will throw an exception if this fails. Wrap this to
  % catch exceptions.

  % Also temporarily suppress warnings.
  ft_warning('off');

  is_ok = true;
  try

    % Get rid of figures that are still open.
    close all;


    % Clear any data that's still in memory from the previous dataset.

    % Aggregated data. TTL and bit-vector data is converted to double.
    clear recdata stimdata;
    % Low-level data:
    clear rechdr stimhdr recdataraw stimdataraw;

    % Just the ephys channels.
    clear recdata_rec stimdata_rec;
    % Low-level data:
    clear rechdr_rec stimhdr_rec recdataraw_rec stimdataraw_rec;

    % Just the stimulation channels.
    % We have events when there's nonzero current, or when flags change.
    clear stimdata_current stimdata_flags;
    clear stimevents_current stimevents_flags;
    % Low-level data:
    clear stimhdr_current stimdataraw_current;
    clear stimhdr_flags stimdataraw_flags;

    % Just the digital channels.
    clear recdata_dig stimdata_dig;
    clear recevents_dig stimevents_dig;
    % Low-level data:
    clear rechdr_dig stimhdr_dig recdataraw_dig stimdataraw_dig;


    % Read this dataset.

    if thiscase.use_looputil

      % NOTE - We're reading several different types of signal separately.

      disp(sprintf( ...
        '== Reading "%s" using LoopUtil''s Field Trip functions.', ...
        thiscase.title ));


      % Build configuration for reading this dataset.
      % NOTE - We'll want to use the "channel" field to specify a subset of
      % channels for full-sized recording data.
      % NOTE - Promoting everything to double.

      preproc_config_rec = struct( ...
        'datafile', thiscase.recfile, 'headerfile', thiscase.recfile, ...
        'headerformat', 'nlFT_readHeader', ...
        'dataformat', 'nlFT_readDataDouble', ...
        'channel', 'all' );

      preproc_config_stim = struct( ...
        'datafile', thiscase.stimfile, 'headerfile', thiscase.stimfile, ...
        'headerformat', 'nlFT_readHeader', ...
        'dataformat', 'nlFT_readDataDouble', ...
        'channel', 'all' );


      disp('-- Reading ephys amplifier data.');

      nlFT_selectChannels({}, {}, {'Amp'})

      if want_test_read_lowlevel
        rechdr_rec = ft_read_header( thiscase.recfile, ...
          'headerformat', 'nlFT_readHeader' );
        stimhdr_rec = ft_read_header( thiscase.stimfile, ...
          'headerformat', 'nlFT_readHeader' );

        % FIXME - Keeping ephys data in native format.
        % Double is what we eventually want, and we'll need the conversion
        % factor from the NeuroLoop header!

        recdataraw_rec = ft_read_data( thiscase.recfile, ...
          'headerformat', 'nlFT_readHeader', ...
          'dataformat', 'nlFT_readDataNative' );
        stimdataraw_rec = ft_read_data( thiscase.stimfile, ...
          'headerformat', 'nlFT_readHeader', ...
          'dataformat', 'nlFT_readDataNative' );

        % FIXME - Not assembling cooked ft_datatype_raw structure!
      else
        % NOTE - Reading as double. This will be big!
        recdata_rec = ft_preprocessing(preproc_config_rec);
        stimdata_rec = ft_preprocessing(preproc_config_stim);
      end

      % No event detection for ephys data.


      disp('-- Reading digital data.');

      nlFT_selectChannels({}, {}, {'Din', 'Dout'})

      if want_test_read_lowlevel
        rechdr_dig = ft_read_header( thiscase.recfile, ...
          'headerformat', 'nlFT_readHeader' );
        stimhdr_dig = ft_read_header( thiscase.stimfile, ...
          'headerformat', 'nlFT_readHeader' );

        % Native format is fine for digital I/O data.
        % We'll get uint16 per-channel or per-bank, depending on file format.

        recdataraw_dig = ft_read_data( thiscase.recfile, ...
          'headerformat', 'nlFT_readHeader', ...
          'dataformat', 'nlFT_readDataNative' );
        stimdataraw_dig = ft_read_data( thiscase.stimfile, ...
          'headerformat', 'nlFT_readHeader', ...
          'dataformat', 'nlFT_readDataNative' );

        % FIXME - Not assembling cooked ft_datatype_raw structure!
      else
        % NOTE - Reading as double.
        recdata_dig = ft_preprocessing(preproc_config_rec);
        stimdata_dig = ft_preprocessing(preproc_config_stim);
      end

% FIXME - Digital events go here.
disp(sprintf('###  Looputil TTL events NYI (%s).', thiscase.title));


      disp('-- Reading stimulation data.');

      nlFT_selectChannels({}, {}, {'Stim'})

      if want_test_read_lowlevel
        % Stimulation current gets converted to double-precision.

        stimhdr_current = ft_read_header( thiscase.stimfile, ...
          'headerformat', 'nlFT_readHeader' );
        stimdataraw_current = ft_read_data( thiscase.stimfile, ...
          'headerformat', 'nlFT_readHeader', ...
          'dataformat', 'nlFT_readDataDouble' );

        % FIXME - Not assembling cooked ft_datatype_raw structure!
      else
        % NOTE - Reading as double.
        stimdata_current = ft_preprocessing(preproc_config_stim);
      end

% FIXME - Current-drive events go here.
disp(sprintf('###  Looputil stim current events NYI (%s).', thiscase.title));

      nlFT_selectChannels({}, {}, {'Flags'})

      if want_test_read_lowlevel
        % Stimulation flags get kept in native format.

        stimhdr_flags = ft_read_header( thiscase.stimfile, ...
          'headerformat', 'nlFT_readHeader' );
        stimdataraw_flags = ft_read_data( thiscase.stimfile, ...
          'headerformat', 'nlFT_readHeader', ...
          'dataformat', 'nlFT_readDataNative' );

        % FIXME - Not assembling cooked ft_datatype_raw structure!
      else
        % NOTE - Reading as double.
        stimdata_flags = ft_preprocessing(preproc_config_stim);
      end

% FIXME - Stimulation flags events go here.
disp(sprintf('###  Looputil stim flag events NYI (%s).', thiscase.title));


      % NOTE - We're also separately reading in all channels, to test that.
      % Channel data all gets promoted to double, for consistent merging.

      if want_test_read_all
        disp('-- Reading combined data.');

        nlFT_selectChannels({}, {}, {});

        if want_test_read_lowlevel
          rechdr = ft_read_header( thiscase.recfile, ...
            'headerformat', 'nlFT_readHeader' );
          stimhdr = ft_read_header( thiscase.stimfile, ...
            'headerformat', 'nlFT_readHeader' );

          recdataraw = ft_read_data( thiscase.recfile, ...
            'headerformat', 'nlFT_readHeader', ...
            'dataformat', 'nlFT_readDataDouble' );
          stimdataraw = ft_read_data( thiscase.stimfile, ...
            'headerformat', 'nlFT_readHeader', ...
            'dataformat', 'nlFT_readDataDouble' );

          % FIXME - Not assembling cooked ft_datatype_raw structure!
        else
          % NOTE - Reading as double. This will be big!
          recdata_dig = ft_preprocessing(preproc_config_rec);
          stimdata_dig = ft_preprocessing(preproc_config_stim);
        end

        % No event detection for combined data.
      end

      disp(sprintf('-- Finished reading "%s".', thiscase.title));

    else

      disp(sprintf( ...
        '== Reading "%s" using Field Trip''s native functions.', ...
        thiscase.title ));

      if want_test_read_lowlevel
        disp(sprintf('-- Reading headers.', thiscase.title));

        rechdr = ft_read_header(thiscase.recfile);
        stimhdr = ft_read_header(thiscase.stimfile);

        disp(sprintf('-- Reading data.', thiscase.title));

        % This will re-read the header will be re-read if we don't supply it,
        % but supply it anyways.
        recdataraw = ft_read_data(thiscase.recfile, 'header', rechdr);
        stimdataraw = ft_read_data(thiscase.stimfile, 'header', stimhdr);

        % FIXME - Not assembling cooked ft_datatype_raw structure!
      else
        % NOTE - Reading as double. This will be big!
        recdata_dig = ft_preprocessing(preproc_config_rec);
        stimdata_dig = ft_preprocessing(preproc_config_stim);
      end

      disp(sprintf('-- Reading events.', thiscase.title));

      % This will re-read the header, so we don't need to supply it.
      recevents = ft_read_event(thiscase.recfile);
      stimevents = ft_read_event(thiscase.stimfile);

      disp(sprintf('-- Finished reading "%s".', thiscase.title));

    end
  catch errordetails
    isok = false;
    disp(sprintf( ...
      '###  Exception thrown while reading "%s".', thiscase.title));
    disp(sprintf('Message: "%s"', errordetails.message));
  end

  % Re-enable warnings.
  ft_warning('on');

  % If we had an error, bail out and move to the next dataset.
  if ~is_ok
    continue;
  end



  %
  % Filter the continuous ephys data.


  % FIXME - Just dealing with recorder channels, not stimulator channels.
  % To aggregate both, we'd need to do artifact removal and notch filtering
  % and re-referencing on both, then do time alignment.
  % After that, we can use ft_appenddata().

  if exist('recdata_rec', 'var')

    % Power-line filtering.

    filt_power = euFT_getFiltPowerLong(power_freq, power_filter_modes);
    if want_power_filter_thilo
      filt_power = euFT_getFiltPowerTW(power_freq, power_filter_modes);
    end

    disp('.. Removing power-line noise.');
    tic();
    recdata_rec = ft_preprocessing(filt_power, recdata_rec);
    thisduration = helper_makePrettyTime(toc());
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
    thisduration = helper_makePrettyTime(toc());
    disp(sprintf( '.. LFP series generated in %s.', thisduration ));


    % Produce spike signals.

    filtconfig = struct( ...
      'hpfilter', 'yes', 'hpfilttype', 'but', 'hpfreq', spike_corner );

    disp('.. Generating spike data series.');
    tic();
    data_spike = ft_preprocessing(filtconfig, data_wideband);
    thisduration = helper_makePrettyTime(toc());
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
    % FIXME - We can group some of these, but that requires detailed
    % knowledge of the order in which FT applies preprocessing operations.
    data_rect = ft_preprocessing(filtconfigband, data_wideband);
    data_rect = ft_preprocessing(rectconfig, data_rect);
    data_rect = ft_preprocessing(filtconfiglow, data_rect);
    data_rect = ft_resampledata(resampleconfig, data_rect);
    thisduration = helper_makePrettyTime(toc());
    disp(sprintf( '.. Rectified series generated in %s.', thisduration ));


    % Done.

  end

  % FIXME - Dataset inspection NYI.

end



%
% Helper functions.

% This formats a duration (in seconds) in a meaningful human-readable way.

function durstring = helper_makePrettyTime(dursecs)

  durstring = '-bogus-';

  if dursecs < 1e-3
    durstring = sprintf('%.1e s', dursecs);
  elseif dursecs < 2e-2
    durstring = sprintf('%.1f ms', dursecs * 1e3);
  elseif dursecs < 2e-1
    durstring = sprintf('%d ms', round(dursecs * 1e3));
  elseif dursecs < 2
    durstring = sprintf('%.2f s', dursecs);
  elseif dursecs < 20
    durstring = sprintf('%.1f s', dursecs);
  else
    % We're in days/hours/minutes/seconds territory.

    dursecs = round(dursecs);
    scratch = dursecs;
    dursecs = mod(scratch, 60);
    scratch = round((scratch - dursecs) / 60);
    durmins = mod(scratch, 60);
    scratch = round((scratch - durmins) / 60);
    durhours = mod(scratch, 24);
    durdays = round((scratch - durhours) / 24);

    if durdays > 0
      durstring = ...
        sprintf('%dd%dh%dm%ds', durdays, durhours, durmins, dursecs);
    elseif durhours > 0
      durstring = sprintf('%dh%dm%ds', durhours, durmins, dursecs);
    elseif durmins > 0
      durstring = sprintf('%dm%ds', durmins, dursecs);
    else
      durstring = sprintf('%d s', dursecs);
    end
  end

end


%
% This is the end of the file.
