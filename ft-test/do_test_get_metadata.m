% Field Trip sample script / test script - Headers and metadata.
% Written by Christopher Thomas.

% This reads headers and selects the timespans and channels we want.
% FIXME - Doing this by reading and setting workspace variables directly.
%
% Variables that get set:
%   rechdr
%   stimhdr
%   rec_channels_ephys
%   rec_channels_digital
%   stim_channels_ephys
%   stim_channels_digital
%   stim_channels_current
%   stim_channels_flags
%   preproc_config_rec
%   preproc_config_stim
%   preproc_config_rec_span_default
%   preproc_config_stim_span_default
%   preproc_config_rec_span_autotype
%   preproc_config_stim_span_autotype


%
% Read the headers.


disp('-- Reading headers.');

% NOTE - Field Trip will throw an exception if this fails. Wrap this to
% catch exceptions.

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

catch errordetails
  disp(sprintf( ...
    '###  Exception thrown while reading "%s".', thisdataset.title));
  disp(sprintf('Message: "%s"', errordetails.message));

  % Abort the script and send the user back to the Matlab prompt.
  error('Couldn''t read headers; bailing out.');
end



%
% Select channels.


% FIXME - Not filtering digial I/O channels.
% Blithely assuming these channels fit in RAM.

% FIXME - Not filtering stimulation current or flag data for now.
% This only fits in RAM if the user saved the channels used rather than
% saving all channels.
% We really should filter this the same way we filter analog data from
% the stimulation channels.


% Analog ephys channels.

rec_channels_ephys = ...
  ft_channelselection( name_patterns_ephys, rechdr.label, {} );
if isfield( thisdataset, 'channels_rec' )
  rec_channels_ephys = ...
    ft_channelselection( thisdataset.channels_rec, rechdr.label, {} );
end

stim_channels_ephys = ...
  ft_channelselection( name_patterns_ephys, stimhdr.label, {} );
if isfield( thisdataset, 'channels_stim' )
  stim_channels_ephys = ...
    ft_channelselection( thisdataset.channels_stim, stimhdr.label, {} );
end


% Digital I/O channels.

rec_channels_digital = ...
  ft_channelselection( name_patterns_digital, rechdr.label, {} );

stim_channels_digital = ...
  ft_channelselection( name_patterns_digital, stimhdr.label, {} );


% Stimulation current and other stimulation metadata.

stim_channels_current = ...
  ft_channelselection( name_patterns_stim_current, stimhdr.label, {} );
stim_channels_flags = ...
  ft_channelselection( name_patterns_stim_flags, stimhdr.label, {} );


% Suppress data types we don't want.

if ~want_data_ephys
  rec_channels_ephys = {};
  stim_channels_ephys = {};
end

if ~want_data_ttl
  rec_channels_digital = {};
  stim_channels_digital = {};
end

if ~want_data_stim
  stim_channels_current = {};
  stim_channels_flags = {};
end



% NOTE - Passing an empty channel list to ft_preprocessing() results in all
% channels being read. Passing a bogus placeholder name to guarantee no
% channels being read causes ft_preprocessing() to throw an exception (it
% does this if it can't find any data).

% Long story short, before calling ft_preprocessing() explicitly check for
% empty channel lists.



%
% Select timespans and build preprocessing configuration structures.


% NOTE - We'll be reading several different types of signal separately.
% For each call to ft_preprocessing, we have to build a configuration
% structure specifying what we want to read.
% The only part that changes for these calls is "channel" (the channel
% name list), which is different for different signal types.


% Basic configuration.

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


% Build time ranges.
% These get stored as "preproc_config_XX.trl".
% Defining a single trial gets us windowed continuous data.

% Monolithic data time range.

% FIXME - Windowing is done before time alignment, so we'd better be sure
% that the time difference between the recorder and stimulator is much
% shorter than the window size.

preproc_config_rec_span_default = [ 1 rechdr.nSamples 0 ];
preproc_config_stim_span_default = [ 1 stimhdr.nSamples 0 ];

if isfield(thisdataset, 'timerange')

  firstsamp = round( min(thisdataset.timerange) * rechdr.Fs );
  firstsamp = min(firstsamp, rechdr.nSamples);
  firstsamp = max(firstsamp, 1);

  lastsamp = round ( max(thisdataset.timerange) * rechdr.Fs );
  lastsamp = min(lastsamp, rechdr.nSamples);
  lastsamp = max(lastsamp, 1);

  preproc_config_rec_span_default = [ firstsamp lastsamp 0 ];


  firstsamp = round( min(thisdataset.timerange) * stimhdr.Fs );
  firstsamp = min(firstsamp, stimhdr.nSamples);
  firstsamp = max(firstsamp, 1);

  lastsamp = round ( max(thisdataset.timerange) * stimhdr.Fs );
  lastsamp = min(lastsamp, stimhdr.nSamples);
  lastsamp = max(lastsamp, 1);

  preproc_config_stim_span_default = [ firstsamp lastsamp 0 ];

end

% Auto-configuration time range.
% Put this in the middle of the dataset.

autosamp_first_frac = 0.5;
if want_auto_channel_early
  % FIXME - Force this to the start, for testing before stimulation.
  autosamp_first_frac = 0.05;
end

firstsamp = round(autosamp_first_frac * rechdr.nSamples);
lastsamp = firstsamp + round( classify_window_seconds * rechdr.Fs );
lastsamp = min( lastsamp, rechdr.nSamples );

preproc_config_rec_span_autotype = [ firstsamp lastsamp 0 ];

firstsamp = round(autosamp_first_frac * stimhdr.nSamples);
lastsamp = firstsamp + round( classify_window_seconds * stimhdr.Fs );
lastsamp = min( lastsamp, stimhdr.nSamples );

preproc_config_stim_span_autotype = [ firstsamp lastsamp 0 ];



%
% This is the end of the file.
