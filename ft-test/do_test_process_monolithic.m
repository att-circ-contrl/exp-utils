% Field Trip sample script / test script - Monolithic data processing.
% Written by Christopher Thomas.

% This reads data without segmenting it, performs signal processing, and
% optionally displays it using FT's browser.
% FIXME - Doing this by reading and setting workspace variables directly.
%
% Variables that get set:
%   have_recdata_an
%   have_recdata_dig
%   recdata_an
%   recdata_dig
%   have_stimdata_an
%   have_stimdata_dig
%   have_stimdata_current
%   have_stimdata_flags
%   stimdata_an
%   stimdata_dig
%   stimdata_current
%   stimdata_flags
%   have_recevents_dig
%   have_stimevents_dig
%   recevents_dig
%   stimevents_dig
%   recdata_wideband
%   recdata_lfp
%   recdata_spike
%   recdata_rect
%   stimdata_wideband
%   stimdata_lfp
%   stimdata_spike
%   stimdata_rect


%
% Load cached results from disk, if requested.
% If we successfully load data, bail out without further processing.

fname_raw = [ datadir filesep 'monolithic_raw.mat' ];
fname_cooked = [ datadir filesep 'monolithic_filtered.mat' ];
fname_ttlevents = [ datadir filesep 'monolithic_ttl_events.mat' ];

if want_cache_monolithic ...
  && isfile(fname_raw) && isfile(fname_cooked) && isfile(fname_ttlevents)

  % Load the data we previously saved.

  disp('-- Loading raw monolithic data.');

  load(fname_raw);

  disp('-- Loading processed monolithic data.');

  load(fname_cooked);

  disp('-- Loading TTL event lists from monolithic data.');

  load(fname_ttlevents);

  recevents_dig = struct([]);
  if have_recevents_dig
    recevents_dig = ...
      nlFT_uncompressFTEvents( recevents_dig_tab, rechdr.label );
  end
  stimevents_dig = struct([]);
  if have_stimevents_dig
    stimevents_dig = ...
      nlFT_uncompressFTEvents( stimevents_dig_tab, stimhdr.label );
  end

  disp('-- Finished loading.');


  % Generate reports and plots.
% FIXME - Monolithic reports and plots NYI.


  % Pull up the data browser windows, if requested.
  if want_browser
    disp('-- Rendering waveforms.');

    % Analog data.
    if have_recdata_an
      doBrowseFiltered( 'Rec', ...
        recdata_wideband, recdata_lfp, recdata_spike, recdata_rect );
    end
    if have_stimdata_an
      doBrowseFiltered( 'Stim', ...
        stimdata_wideband, stimdata_lfp, stimdata_spike, stimdata_rect );
    end

    % Continuous digital data.
    if have_recdata_dig
      doBrowseWave( recdata_dig, 'Recorder TTL' );
    end
    if have_stimdata_dig
      doBrowseWave( stimdata_dig, 'Stimulator TTL' );
    end

    disp('-- Press any key to continue.');
    pause;

    % Clean up.
    close all;
  end


  % We've loaded cached results. Bail out of this portion of the script.
  return;
end



%
% Read the dataset using ft_preprocessing().


% Select the default (large) time window.

preproc_config_rec.trl = preproc_config_rec_span_default;
preproc_config_stim.trl = preproc_config_stim_span_default;


% Turn off the progress bar.
preproc_config_rec.feedback = 'no';
preproc_config_stim.feedback = 'no';


% Read the data.

% NOTE - Field Trip will throw an exception if this fails. Wrap this to
% catch exceptions.

have_recdata_an = false;
have_stimdata_an = false;

recdata_an = struct([]);
stimdata_an = struct([]);

have_recdata_dig = false;
have_stimdata_dig = false;

recdata_dig = struct([]);
stimdata_dig = struct([]);

have_stimdata_current = false;
have_stimdata_flags = false;

stimdata_current = struct([]);
stimdata_flags = struct([]);

have_recevents_dig = false;
have_stimevents_dig = false;

recevents_dig = struct([]);
stimevents_dig = struct([]);

try

  disp('-- Reading ephys amplifier data.');
  tic();

  % Report the window span.
  disp(sprintf( ...
    '.. Read window is:   %.1f - %.1f s (rec)   %.1f - %.1f s (stim).', ...
    preproc_config_rec_span_default(1) / rechdr.Fs, ...
    preproc_config_rec_span_default(2) / rechdr.Fs, ...
    preproc_config_stim_span_default(1) / stimhdr.Fs, ...
    preproc_config_stim_span_default(2) / stimhdr.Fs ));


  % NOTE - Reading as double. This will be big!

  if isempty(rec_channels_ephys)
    disp('.. Skipping recorder (no channels selected).');
  else
    preproc_config_rec.channel = rec_channels_ephys;
    recdata_an = ft_preprocessing(preproc_config_rec);
    have_recdata_an = true;
  end

  if isempty(stim_channels_ephys)
    disp('.. Skipping stimulator (no channels selected).');
  else
    preproc_config_stim.channel = stim_channels_ephys;
    stimdata_an = ft_preprocessing(preproc_config_stim);
    have_stimdata_an = true;
  end

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. Read in %s.', thisduration ));


  disp('-- Reading digital waveforms.');
  tic();

  if isempty(rec_channels_digital)
    disp('.. Skipping recorder (no channels selected).');
  else
    preproc_config_rec.channel = rec_channels_digital;
    recdata_dig = ft_preprocessing(preproc_config_rec);
    have_recdata_dig = true;
  end

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

  if ~want_data_events
    disp('.. Skipping events.');
  else
    disp('.. Reading from recorder.');

    recevents_dig = ft_read_event( thisdataset.recfile, ...
      'headerformat', 'nlFT_readHeader', 'eventformat', 'nlFT_readEvents' );

    % FIXME - Kludge for drivers that don't report events.
    % We actually don't need this - our Intan wrapper does this internally.
    if isempty(recevents_dig)
      disp('.. No recorder events found. Trying again using waveforms.');
      recevents_dig = ft_read_event( thisdataset.recfile, ...
        'headerformat', 'nlFT_readHeader', ...
        'eventformat', 'nlFT_readEventsContinuous' );
    end

    disp('.. Reading from stimulator.');

    stimevents_dig = ft_read_event( thisdataset.stimfile, ...
      'headerformat', 'nlFT_readHeader', 'eventformat', 'nlFT_readEvents' );

    % FIXME - Kludge for drivers that don't report events.
    % We actually don't need this - our Intan wrapper does this internally.
    if isempty(stimevents_dig)
      disp('.. No stimulator events found. Trying again using waveforms.');
      stimevents_dig = ft_read_event( thisdataset.stimfile, ...
        'headerformat', 'nlFT_readHeader', ...
        'eventformat', 'nlFT_readEventsContinuous' );
    end

    % NOTE - We have event lists, but those lists might be empty.
    have_recevents_dig = true;
    have_stimevents_dig = true;
  end

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. Read in %s.', thisduration ));


  disp('-- Reading stimulation data.');
  tic();

  if isempty(stim_channels_current)
    disp('.. Skipping stimulation current (no channels selected).');
  else
    preproc_config_stim.channel = stim_channels_current;
    stimdata_current = ft_preprocessing(preproc_config_stim);
    have_stimdata_current = true;
  end

  % NOTE - Reading flags as double. We can still perform bitwise operations
  % on them.
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
  disp('-- Finished reading data.');


catch errordetails
  disp(sprintf( ...
    '###  Exception thrown while reading "%s".', thisdataset.title));
  disp(sprintf('Message: "%s"', errordetails.message));

  % Abort the script and send the user back to the Matlab prompt.
  error('Couldn''t read signals/events; bailing out.');
end



%
% Filter the continuous ephys data.


% FIXME - We need to aggregate these, after time alignment.
% FIXME - We need to re-reference these in individual batches, not globally.
% After alignment and re-referencing, we can use ft_appenddata().
% In practice aggregating monolithic isn't necessarily useful; we can do it
% for trials once alignment is known.

recdata_wideband = struct([]);
recdata_lfp = struct([]);
recdata_spike = struct([]);
recdata_rect = struct([]);

stimdata_wideband = struct([]);
stimdata_lfp = struct([]);
stimdata_spike = struct([]);
stimdata_rect = struct([]);


if have_recdata_an

  % De-trending and power-line filtering.

  disp('.. [Rec] De-trending and removing power-line noise.');
  tic();

  extra_notches = [];
  if isfield( thisdataset, 'extra_notches' )
    extra_notches = thisdataset.extra_notches;
  end

  recdata_an = doSignalConditioning( recdata_an, ...
    power_freq, power_filter_modes, extra_notches );

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. [Rec] Power line noise removed in %s.', thisduration ));


  % Artifact removal.

  % FIXME - NYI.
  disp('###  Artifact removal NYI!');


  % Re-referencing.

  % FIXME - NYI.
  % This needs to be done in batches of channels, representing different
  % probes.
  disp('###  Rereferencing NYI!');


  %
  % Get spike and LFP and rectified waveforms.

  % Copy the wideband signals.
  recdata_wideband = recdata_an;

  disp('.. [Rec] Generating LFP, spike, and rectified activity data series.');
  tic();

  [ recdata_lfp recdata_spike recdata_rect ] = ...
    euFT_getDerivedSignals( recdata_wideband, ...
      lfp_corner, lfp_rate, spike_corner, ...
      rect_corners, rect_lowpass, rect_rate );

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. [Rec] Filtered series generated in %s.', thisduration ));


  % Done.

end


if have_stimdata_an

  % De-trending and power-line filtering.

  disp('.. [Stim] De-trending and removing power-line noise.');
  tic();

  extra_notches = [];
  if isfield( thisdataset, 'extra_notches' )
    extra_notches = thisdataset.extra_notches;
  end

  stimdata_an = doSignalConditioning( stimdata_an, ...
    power_freq, power_filter_modes, extra_notches );

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. [Stim] Power line noise removed in %s.', thisduration ));


  % Artifact removal.

  % FIXME - NYI.
  disp('###  Artifact removal NYI!');


  % Re-referencing.

  % FIXME - NYI.
  % This needs to be done in batches of channels, representing different
  % probes.
  disp('###  Rereferencing NYI!');


  %
  % Get spike and LFP and rectified waveforms.

  % Copy the wideband signals.
  stimdata_wideband = stimdata_an;

  disp('.. [Stim] Generating LFP, spike, and rectified activity data series.');
  tic();

  [ stimdata_lfp stimdata_spike stimdata_rect ] = ...
    euFT_getDerivedSignals( stimdata_wideband, ...
      lfp_corner, lfp_rate, spike_corner, ...
      rect_corners, rect_lowpass, rect_rate );

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. [Stim] Filtered series generated in %s.', thisduration ));


  % Done.

end



%
% Save the results to disk, if requested.

if want_save_data

  if isfile(fname_raw)       ; delete(fname_raw)       ; end
  if isfile(fname_cooked)    ; delete(fname_cooked)    ; end
  if isfile(fname_ttlevents) ; delete(fname_ttlevents) ; end

  disp('-- Saving raw monolithic data.');

  save( fname_raw, ...
    'have_recdata_an', 'recdata_an', ...
    'have_recdata_dig', 'recdata_dig', ...
    'have_stimdata_an', 'stimdata_an', ...
    'have_stimdata_dig', 'stimdata_dig', ...
    'have_stimdata_current', 'stimdata_current', ...
    'have_stimdata_flags', 'stimdata_flags', ...
    '-v7.3' );

  disp('-- Saving processed monolithic data.');

  save( fname_cooked, ...
    'recdata_wideband', 'recdata_lfp', 'recdata_spike', 'recdata_rect', ...
    'stimdata_wideband', 'stimdata_lfp', 'stimdata_spike', 'stimdata_rect', ...
    '-v7.3' );

  disp('-- Saving compressed TTL event lists from monolithic data.');

  % NOTE - Saving TTL events in packed tabular form, as that's far smaller
  % than structure array form.

  recevents_dig_tab = table();
  if have_recevents_dig
    [ recevents_dig_tab scratchlut ] = ...
      nlFT_compressFTEvents( recevents_dig, rechdr.label );
  end
  stimevents_dig_tab = table();
  if have_stimevents_dig
    [ stimevents_dig_tab scratchlut ] = ...
      nlFT_compressFTEvents( stimevents_dig, stimhdr.label );
  end

  save( fname_ttlevents, ...
    'have_recevents_dig', 'recevents_dig_tab', ...
    'have_stimevents_dig', 'stimevents_dig_tab', ...
    '-v7.3' );

  disp('-- Finished saving.');
end



%
% Inspect the waveform data, if requested.

if want_browser

  disp('-- Rendering waveforms.');

  % Analog data.

  if have_recdata_an
    doBrowseFiltered( 'Rec', ...
      recdata_wideband, recdata_lfp, recdata_spike, recdata_rect );
  end

  if have_stimdata_an
    doBrowseFiltered( 'Stim', ...
      stimdata_wideband, stimdata_lfp, stimdata_spike, stimdata_rect );
  end


  % Continuous digital data.

  if have_recdata_dig
    doBrowseWave( recdata_dig, 'Recorder TTL' );
  end

  if have_stimdata_dig
    doBrowseWave( stimdata_dig, 'Stimulator TTL' );
  end


  % Done.

  disp('-- Press any key to continue.');
  pause;

  % Clean up.
  close all;

end



%
% This is the end of the file.
