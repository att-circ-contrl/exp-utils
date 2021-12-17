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
    if thiscase.use_looputil

      disp(sprintf('-- Reading "%s" headers.', thiscase.title));

      rechdr = ft_read_header( thiscase.recfile, ...
        'headerformat', 'nlFT_readHeader' );
      stimhdr = ft_read_header( thiscase.stimfile, ...
        'headerformat', 'nlFT_readHeader' );

      % FIXME - NYI.
      disp(sprintf('###  Looputil hooks NYI (%s).', thiscase.title));

      disp(sprintf('-- Reading "%s" data.', thiscase.title));

      disp(sprintf('-- Reading "%s" events.', thiscase.title));

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
