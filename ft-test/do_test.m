% Field Trip sample script / test script.
% Written by Christopher Thomas.


%
% Configuration.

% Behavior switches.

% Native Intan.
want_intan_monolithic = false;
want_intan_pertype = false;
want_intan_perchan = true;

% Converted Intan.
want_intan_plexon = false;
want_intan_plexon_nex5 = false;

% Native Open Ephys.
want_openephys_monolithic = false;

% Converted Open Ephys.
want_openephys_plexon = false;



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


for didx = 1:length(datacases)

  thiscase = datacases(didx);

  %
  % Read the datasets using low-level I/O functions.

  % The other option is to call "ft_preprocessing" with a "dataset" filename
  % in the configuration, at which point it will read the header, data, and
  % events automatically. That doesn't accept "dataformat" or "headerformat"
  % or "eventformat" arguments, though, so it can't use the LoopUtil I/O
  % functions.

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
    clear rechdr stimhdr recdata stimdata;

    % Just the ephys channels.
    clear rechdr_rec stimhdr_rec recdata_rec stimdata_rec;

    % Just the stimulation channels.
    % We have events when there's nonzero current, or when flags change.
    clear stimhdr_current stimdata_current stimevents_current;
    clear stimhdr_flags stimdata_flags stimevents_flags;

    % Just the digital channels.
    clear rechdr_dig stimhdr_dig;
    clear recdata_dig stimdata_dig recevents_dig stimevents_dig;


    % Read this dataset.

    if thiscase.use_looputil

      % NOTE - We're reading several different types of signal separately.


      disp(sprintf('-- Reading "%s" ephys amplifier data.', thiscase.title));

      nlFT_selectChannels({}, {}, {'Amp'})

      rechdr_rec = ft_read_header( thiscase.recfile, ...
        'headerformat', 'nlFT_readHeader' );
      stimhdr_rec = ft_read_header( thiscase.stimfile, ...
        'headerformat', 'nlFT_readHeader' );

      % FIXME - Keeping ephys data in native format.
      % Double is what we eventually want, and we'll need the conversion
      % factor from the NeuroLoop header!

      recdata_rec = ft_read_data( thiscase.recfile, ...
        'headerformat', 'nlFT_readHeader', ...
        'dataformat', 'nlFT_readDataNative' );
      stimdata_rec = ft_read_data( thiscase.stimfile, ...
        'headerformat', 'nlFT_readHeader', ...
        'dataformat', 'nlFT_readDataNative' );

      % No event detection for ephys data.


      disp(sprintf('-- Reading "%s" digital data.', thiscase.title));

      nlFT_selectChannels({}, {}, {'Din', 'Dout'})

      rechdr_dig = ft_read_header( thiscase.recfile, ...
        'headerformat', 'nlFT_readHeader' );
      stimhdr_dig = ft_read_header( thiscase.stimfile, ...
        'headerformat', 'nlFT_readHeader' );

      % Native format is fine for digital I/O data.
      % We'll get uint16 per-channel or per-bank, depending on file format.

      recdata_dig = ft_read_data( thiscase.recfile, ...
        'headerformat', 'nlFT_readHeader', ...
        'dataformat', 'nlFT_readDataNative' );
      stimdata_dig = ft_read_data( thiscase.stimfile, ...
        'headerformat', 'nlFT_readHeader', ...
        'dataformat', 'nlFT_readDataNative' );

% FIXME - Digital events go here.
disp(sprintf('###  Looputil TTL events NYI (%s).', thiscase.title));


      disp(sprintf('-- Reading "%s" stimulation data.', thiscase.title));

      % Stimulation current gets converted to double-precision.

      nlFT_selectChannels({}, {}, {'Stim'})

      stimhdr_current = ft_read_header( thiscase.stimfile, ...
        'headerformat', 'nlFT_readHeader' );
      stimdata_current = ft_read_data( thiscase.stimfile, ...
        'headerformat', 'nlFT_readHeader', ...
        'dataformat', 'nlFT_readDataDouble' );

% FIXME - Current-drive events go here.
disp(sprintf('###  Looputil stim current events NYI (%s).', thiscase.title));

      % Stimulation flags get kept in native format.

      nlFT_selectChannels({}, {}, {'Flags'})

      stimhdr_flags = ft_read_header( thiscase.stimfile, ...
        'headerformat', 'nlFT_readHeader' );
      stimdata_flags = ft_read_data( thiscase.stimfile, ...
        'headerformat', 'nlFT_readHeader', ...
        'dataformat', 'nlFT_readDataNative' );

% FIXME - Stimulation flags events go here.
disp(sprintf('###  Looputil stim flag events NYI (%s).', thiscase.title));


      % NOTE - We're also separately reading in all channels, to test that.
      % Channel data all gets promoted to double, for consistent merging.

      disp(sprintf('-- Reading "%s" combined data.', thiscase.title));

      nlFT_selectChannels({}, {}, {});

      rechdr = ft_read_header( thiscase.recfile, ...
        'headerformat', 'nlFT_readHeader' );
      stimhdr = ft_read_header( thiscase.stimfile, ...
        'headerformat', 'nlFT_readHeader' );

      recdata = ft_read_data( thiscase.recfile, ...
        'headerformat', 'nlFT_readHeader', ...
        'dataformat', 'nlFT_readDataDouble' );
      stimdata = ft_read_data( thiscase.stimfile, ...
        'headerformat', 'nlFT_readHeader', ...
        'dataformat', 'nlFT_readDataDouble' );

      % No event detection for combined data.

    else

      disp(sprintf('-- Reading "%s" headers.', thiscase.title));

      rechdr = ft_read_header(thiscase.recfile);
      stimhdr = ft_read_header(thiscase.stimfile);

      disp(sprintf('-- Reading "%s" data.', thiscase.title));

      % This will re-read the header will be re-read if we don't supply it,
      % but supply it anyways.
      recdata = ft_read_data(thiscase.recfile, 'header', rechdr);
      stimdata = ft_read_data(thiscase.stimfile, 'header', stimhdr);

      disp(sprintf('-- Reading "%s" events.', thiscase.title));

      % This will re-read the header will be re-read if we don't supply it,
      % but supply it anyways.
      recevents = ft_read_event(thiscase.recfile, 'header', rechdr);
      stimevents = ft_read_event(thiscase.stimfile, 'header', stimhdr);

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


  % FIXME - Dataset inspection NYI.

end



%
% This is the end of the file.
