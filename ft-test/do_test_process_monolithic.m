% Field Trip sample script / test script - Monolithic data processing.
% Written by Christopher Thomas.

% This reads data without segmenting it, performs signal processing, and
% optionally displays it using FT's browser.
% FIXME - Doing this by reading and setting workspace variables directly.
%
% Variables that get set:
%   have_recdata_rec
%   have_recdata_dig
%   recdata_rec
%   recdata_dig
%   have_stimdata_rec
%   have_stimdata_dig
%   have_stimdata_current
%   have_stimdata_flags
%   stimdata_rec
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

if want_cache_monolithic
  fname = [ datadir filesep 'monolithic.mat' ];

  if isfile(fname)
    % Load the data we previously saved.

    disp('-- Loading processed monolithic data.');
    load(fname);
    disp('-- Finished loading.');


    % Generate reports and plots.
% FIXME - Monolithic reports and plots NYI.


    % Pull up the data browser windows, if requested.
    if want_browser
      disp('-- Rendering waveforms.');

      % Analog data.
      if have_recdata_rec
        doBrowseFiltered( 'Rec', ...
          recdata_wideband, recdata_lfp, recdata_spike, recdata_rect );
      end
      if have_stimdata_rec
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

have_recdata_rec = false;
have_stimdata_rec = false;

recdata_rec = struct([]);
stimdata_rec = struct([]);

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

  if isempty(rec_channels_record)
    disp('.. Skipping recorder (no channels selected).');
  else
    preproc_config_rec.channel = rec_channels_record;
    recdata_rec = ft_preprocessing(preproc_config_rec);
    have_recdata_rec = true;
  end

  if isempty(stim_channels_record)
    disp('.. Skipping stimulator (no channels selected).');
  else
    preproc_config_stim.channel = stim_channels_record;
    stimdata_rec = ft_preprocessing(preproc_config_stim);
    have_stimdata_rec = true;
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


if have_recdata_rec

  % Power-line filtering.

  disp('.. [Rec] Removing power-line noise.');
  tic();

  recdata_rec = doPowerFiltering( recdata_rec, ...
    power_freq, power_filter_modes, want_power_filter_thilo );

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. [Rec] Power line noise removed in %s.', thisduration ));


  % De-trending.

  % FIXME - NYI.
  % This would have to be done via a long moving-window average, as the
  % DC level will wander for the full-length trace.
  disp('###  De-trending NYI!');


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
  recdata_wideband = recdata_rec;

  disp('.. [Rec] Generating LFP, spike, and rectified activity data series.');
  tic();

  [ recdata_lfp recdata_spike recdata_rect ] = ...
    doFeatureFiltering( recdata_wideband, ...
      lfp_corner, lfp_rate, spike_corner, ...
      rect_corners, rect_lowpass, rect_rate );

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. [Rec] Filtered series generated in %s.', thisduration ));


  % Done.

end


if have_stimdata_rec

  % Power-line filtering.

  disp('.. [Stim] Removing power-line noise.');
  tic();

  stimdata_rec = doPowerFiltering( stimdata_rec, ...
    power_freq, power_filter_modes, want_power_filter_thilo );

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. [Stim] Power line noise removed in %s.', thisduration ));


  % De-trending.

  % FIXME - NYI.
  % This would have to be done via a long moving-window average, as the
  % DC level will wander for the full-length trace.
  disp('###  De-trending NYI!');


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
  stimdata_wideband = stimdata_rec;

  disp('.. [Stim] Generating LFP, spike, and rectified activity data series.');
  tic();

  [ stimdata_lfp stimdata_spike stimdata_rect ] = ...
    doFeatureFiltering( stimdata_wideband, ...
      lfp_corner, lfp_rate, spike_corner, ...
      rect_corners, rect_lowpass, rect_rate );

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. [Stim] Filtered series generated in %s.', thisduration ));


  % Done.

end



%
% Save the results to disk, if requested.

if want_save_data
  fname = [ datadir filesep 'monolithic.mat' ];

  if isfile(fname)
    delete(fname);
  end

  disp('-- Saving processed monolithic data.');

  save( fname, ...
    'have_recdata_rec', 'recdata_rec', ...
    'have_recdata_dig', 'recdata_dig', ...
    'have_stimdata_rec', 'stimdata_rec', ...
    'have_stimdata_dig', 'stimdata_dig', ...
    'have_stimdata_current', 'stimdata_current', ...
    'have_stimdata_flags', 'stimdata_flags', ...
    'have_recevents_dig', 'recevents_dig', ...
    'have_stimevents_dig', 'stimevents_dig', ...
    'recdata_wideband', 'recdata_lfp', 'recdata_spike', 'recdata_rect', ...
    'stimdata_wideband', 'stimdata_lfp', 'stimdata_spike', 'stimdata_rect' );

  disp('-- Finished saving.');
end



%
% Inspect the waveform data, if requested.

if want_browser

  disp('-- Rendering waveforms.');

  % Analog data.

  if have_recdata_rec
    doBrowseFiltered( 'Rec', ...
      recdata_wideband, recdata_lfp, recdata_spike, recdata_rect );
  end

  if have_stimdata_rec
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