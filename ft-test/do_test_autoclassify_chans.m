% Field Trip sample script / test script - Automatic channel classification.
% Written by Christopher Thomas.

% This reads a small section of the analog data, performs signal processing,
% and attempts to determine which channels contain valid data.
% FIXME - Doing this by reading and setting workspace variables directly.
%
% Variables that get set:
%   rec_quantized
%   stim_quantized
%   rec_has_dropouts
%   stim_has_dropouts
%   rec_dropout_frac
%   stim_dropout_frac
%   rec_has_artifacts
%   stim_has_artifacts
%   rec_artifact_frac
%   stim_artifact_frac



%
% Banner.

disp('-- Attempting to auto-classify channels.');



%
% Read the analog signals using ft_preprocessing().


% Select the auto-classification time window (short).
% Also read in native format, not double; this lets us catch quantization.

have_native = false;

preproc_config_rec_auto = preproc_config_rec;
preproc_config_stim_auto = preproc_config_stim;
preproc_config_rec_auto.trl = preproc_config_rec_span_autotype;
preproc_config_stim_auto.trl = preproc_config_stim_span_autotype;
if thisdataset.use_looputil
  have_native = true;
  preproc_config_rec_auto.dataformat = 'nlFT_readDataNative';
  preproc_config_stim_auto.dataformat = 'nlFT_readDataNative';
end

preproc_config_rec_auto.feedback = 'no';
preproc_config_stim_auto.feedback = 'no';


% Read the data.

% NOTE - Field Trip will throw an exception if this fails. Wrap this to
% catch exceptions.

have_recdata_auto = false;
have_stimdata_auto = false;

try

  disp('-- Reading windowed ephys amplifier data.');
  tic();

  if isempty(rec_channels_record)
    disp('.. Skipping recorder (no channels selected).');
  else
    preproc_config_rec_auto.channel = rec_channels_record;
    recdata_auto = ft_preprocessing(preproc_config_rec_auto);
    have_recdata_auto = true;
  end

  if isempty(stim_channels_record)
    disp('.. Skipping stimulator (no channels selected).');
  else
    preproc_config_stim_auto.channel = stim_channels_record;
    stimdata_auto = ft_preprocessing(preproc_config_stim_auto);
    have_stimdata_auto = true;
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
  error('Couldn''t read ephys waveform data; bailing out.');
end



%
% Check for quantization.

% We have to do this before filtering.

nchans_rec = length(rec_channels_record);
nchans_stim = length(stim_channels_record);

rec_quantized = zeros(nchans_rec, 1, 'logical');
stim_quantized = zeros(nchans_stim, 1, 'logical');

if ~have_native
  disp('-- Don''t have native data; skipping quantization check.');
else

  disp('-- Checking for quantization.');

  % foo.trial{1} is Nchans x Nsamps and contains sample values (A.U.).
  % foo.time{1} is 1 x Nsamps and is time in seconds.

  for cidx = 1:nchans_rec
    thisdata = recdata_auto.trial{1}(cidx,:);
    thismax = max(thisdata);
    thismin = min(thisdata);
    thisbits = log(thismax - thismin) / log(2);

    if thisbits <= quantization_bits
      rec_quantized(cidx) = true;
    end
  end

  for cidx = 1:nchans_stim
    thisdata = stimdata_auto.trial{1}(cidx,:);
    thismax = max(thisdata);
    thismin = min(thisdata);
    thisbits = log(thismax - thismin) / log(2);

    if thisbits <= quantization_bits
      stim_quantized(cidx) = true;
    end
  end

  clear thisdata;


  % Quantization report.

  disp(sprintf( '.. %d of %d recording channels were quantized.', ...
    sum(rec_quantized), nchans_rec ));

  for cidx = 1:nchans_rec
    if rec_quantized(cidx)
      disp([ '  ' rec_channels_record{cidx} ]);
    end
  end

  disp(sprintf( '.. %d of %d stimulation channels were quantized.', ...
    sum(stim_quantized), nchans_stim ));

  for cidx = 1:nchans_stim
    if stim_quantized(cidx)
      disp([ '  ' stim_channels_record{cidx} ]);
    end
  end


  % Done.
  disp('-- Finished checking for quantization.');

end



%
% Filter the continuous ephys data.
% This will have edge effects, but that should be tolerable.

% NOTE - Handling recorder and stimulator data separately, for simplicity.

% NOTE - We're assuming that the window is short enough for de-trending to
% be appropriate (i.e. that it's ramped, not randomly wandering).


% Banner.
disp('-- Filtering windowed ephys data.');


if have_recdata_auto

  % Power-line filtering.

  disp('.. [Rec] Removing power-line noise.');
  tic();

  recdata_auto = doPowerFiltering( ...
    recdata_auto, power_freq, power_filter_modes, want_power_filter_thilo );

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. [Rec] Power line noise removed in %s.', thisduration ));


  %
  % De-trend, removing any ramping in the data.

  trendconfig = struct( 'detrend', 'yes' );
  trendconfig.feedback = 'no';
  recdata_auto = ft_preprocessing(trendconfig, recdata_auto);


  %
  % NOTE - Not removing artifacts; we're _looking_ for artifacts.


  %
  % Get spike and LFP and rectified waveforms.

  % Copy the wideband signals.
  recdata_wideband = recdata_auto;

  disp('.. [Rec] Generating LFP, spike, and rectified activity data series.');
  tic();

  [ recdata_lfp recdata_spike recdata_rect ] = ...
    doFeatureFiltering( recdata_wideband, ...
      lfp_corner, lfp_rate, spike_corner, ...
      rect_corners, rect_lowpass, rect_rate );

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. [Rec] Filtered series generated in %s.', thisduration ));


  %
  % NOTE - Not rereferencing. We don't know which channels are good yet.
  % We also don't know which channels should and shouldn't be averaged, here.


  % Done.

end


if have_stimdata_auto

  % Power-line filtering.

  disp('.. [Stim] Removing power-line noise.');
  tic();

  stimdata_auto = doPowerFiltering( ...
    stimdata_auto, power_freq, power_filter_modes, want_power_filter_thilo );

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. [Stim] Power line noise removed in %s.', thisduration ));


  %
  % De-trend, removing any ramping in the data.

  trendconfig = struct( 'detrend', 'yes' );
  trendconfig.feedback = 'no';
  stimdata_auto = ft_preprocessing(trendconfig, stimdata_auto);


  %
  % NOTE - Not removing artifacts; we're _looking_ for artifacts.


  %
  % Get spike and LFP and rectified waveforms.

  % Copy the wideband signals.
  stimdata_wideband = stimdata_auto;

  disp('.. [Stim] Generating LFP, spike, and rectified activity data series.');
  tic();

  [ stimdata_lfp stimdata_spike stimdata_rect ] = ...
    doFeatureFiltering( stimdata_wideband, ...
      lfp_corner, lfp_rate, spike_corner, ...
      rect_corners, rect_lowpass, rect_rate );

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. [Stim] Filtered series generated in %s.', thisduration ));


  %
  % NOTE - Not rereferencing. We don't know which channels are good yet.
  % We also don't know which channels should and shouldn't be averaged, here.


  % Done.

end


% Done.
disp('-- Finished filtering windowed ephys data.');



%
% Check for artifacts and dropouts.

rec_has_artifacts = zeros(nchans_rec, 1, 'logical');
rec_has_dropouts = zeros(nchans_rec, 1, 'logical');
stim_has_artifacts = zeros(nchans_stim, 1, 'logical');
stim_has_dropouts = zeros(nchans_stim, 1, 'logical');

rec_artifact_frac = zeros(nchans_rec, 1, 'double');
rec_dropout_frac = zeros(nchans_rec, 1, 'double');
stim_artifact_frac = zeros(nchans_stim, 1, 'double');
stim_dropout_frac = zeros(nchans_stim, 1, 'double');


disp('-- Checking for dropouts and artifacts.');


smoothfreq = 1.0 / artifact_dropout_time;
filtconfig_smooth = ...
  struct( 'lpfilter', 'yes', 'lpfilttype', 'but', 'lpfreq', smoothfreq );
filtconfig_smooth.feedback = 'no';

if have_recdata_auto
  datasmoothed = ft_preprocessing(filtconfig_smooth, recdata_rect);

  % foo.trial{1} is Nchans x Nsamps and contains sample values.
  for cidx = 1:nchans_rec

    thisrelative = datasmoothed.trial{1}(cidx,:) / ...
      median( recdata_rect.trial{1}(cidx,:) );

% FIXME - Diagnostics.
if false
disp(sprintf( '.. Rec "%s" rect ratio:  %.2f - %.2f', ...
rec_channels_record{cidx}, min(thisrelative), max(thisrelative) ));
end

    thismask = (thisrelative >= artifact_rect_threshold);
    thisfrac = sum(thismask) / length(thismask);
    if ~isfinite(thisfrac)
      thisfrac = 0;
    end
    rec_artifact_frac(cidx) = thisfrac;

    thismask = (thisrelative <= dropout_rect_threshold);
    thisfrac = sum(thismask) / length(thismask);
    if ~isfinite(thisfrac)
      thisfrac = 0;
    end
    rec_dropout_frac(cidx) = thisfrac;
  end

  rec_has_artifacts = (rec_artifact_frac >= artifact_bad_frac);
  rec_has_dropouts = (rec_dropout_frac >= dropout_bad_frac);
end

if have_stimdata_auto
  datasmoothed = ft_preprocessing(filtconfig_smooth, stimdata_rect);

  % foo.trial{1} is Nchans x Nsamps and contains sample values.
  for cidx = 1:nchans_stim

    thisrelative = datasmoothed.trial{1}(cidx,:) / ...
      median( stimdata_rect.trial{1}(cidx,:) );

% FIXME - Diagnostics.
if false
disp(sprintf( '.. Stim "%s" rect ratio:  %.2f - %.2f', ...
stim_channels_record{cidx}, min(thisrelative), max(thisrelative) ));
end

    thismask = (thisrelative >= artifact_rect_threshold);
    thisfrac = sum(thismask) / length(thismask);
    if ~isfinite(thisfrac)
      thisfrac = 0;
    end
    stim_artifact_frac(cidx) = thisfrac;

    thismask = (thisrelative <= dropout_rect_threshold);
    thisfrac = sum(thismask) / length(thismask);
    if ~isfinite(thisfrac)
      thisfrac = 0;
    end
    stim_dropout_frac(cidx) = thisfrac;
  end

  stim_has_artifacts = (stim_artifact_frac >= artifact_bad_frac);
  stim_has_dropouts = (stim_dropout_frac >= dropout_bad_frac);
end


% Dropout and artifact report.

disp(sprintf( '.. %d of %d recording channels had artifacts.', ...
  sum(rec_has_artifacts), nchans_rec ));

for cidx = 1:nchans_rec
  if rec_has_artifacts(cidx)
    disp(sprintf( '  %s  (%.1f %%)', ...
      rec_channels_record{cidx}, 100 * rec_artifact_frac(cidx) ));
  end
end

disp(sprintf( '.. %d of %d stimulation channels had artifacts.', ...
  sum(stim_has_artifacts), nchans_stim ));

for cidx = 1:nchans_stim
  if stim_has_artifacts(cidx)
    disp(sprintf( '  %s  (%.1f %%)', ...
      stim_channels_record{cidx}, 100 * stim_artifact_frac(cidx) ));
  end
end

disp(sprintf( '.. %d of %d recording channels had drop-outs.', ...
  sum(rec_has_dropouts), nchans_rec ));

for cidx = 1:nchans_rec
  if rec_has_dropouts(cidx)
    disp(sprintf( '  %s  (%.1f %%)', ...
      rec_channels_record{cidx}, 100 * rec_dropout_frac(cidx) ));
  end
end

disp(sprintf( '.. %d of %d stimulation channels had drop-outs.', ...
  sum(stim_has_dropouts), nchans_stim ));

for cidx = 1:nchans_stim
  if stim_has_dropouts(cidx)
    disp(sprintf( '  %s  (%.1f %%)', ...
      stim_channels_record{cidx}, 100 * stim_dropout_frac(cidx) ));
  end
end


disp('-- Finished checking for dropouts and artifacts.');


%
% Inspect the waveform data.

% FIXME - Just pulling up data browser windows as an interim measure.

if want_browser

  disp('-- Rendering waveforms.');

  if have_recdata_auto
    % FIXME - The saved configuration might be re-filtering the data!
    % It _shouldn't_ be rereading, but it's doing _something_.

    ft_databrowser(recdata_wideband.cfg, recdata_wideband);
    set(gcf(), 'Name', 'Rec Wideband', 'NumberTitle', 'off');
    ft_databrowser(recdata_lfp.cfg, recdata_lfp);
    set(gcf(), 'Name', 'Rec LFP', 'NumberTitle', 'off');
    ft_databrowser(recdata_spike.cfg, recdata_spike);
    set(gcf(), 'Name', 'Rec Spikes', 'NumberTitle', 'off');
    ft_databrowser(recdata_rect.cfg, recdata_rect);
    set(gcf(), 'Name', 'Rec Rectified', 'NumberTitle', 'off');
  end

  if have_recdata_auto
    % FIXME - The saved configuration might be re-filtering the data!
    % It _shouldn't_ be rereading, but it's doing _something_.

    ft_databrowser(stimdata_wideband.cfg, stimdata_wideband);
    set(gcf(), 'Name', 'Stim Wideband', 'NumberTitle', 'off');
    ft_databrowser(stimdata_lfp.cfg, stimdata_lfp);
    set(gcf(), 'Name', 'Stim LFP', 'NumberTitle', 'off');
    ft_databrowser(stimdata_spike.cfg, stimdata_spike);
    set(gcf(), 'Name', 'Stim Spikes', 'NumberTitle', 'off');
    ft_databrowser(stimdata_rect.cfg, stimdata_rect);
    set(gcf(), 'Name', 'Stim Rectified', 'NumberTitle', 'off');
  end

  disp('-- Press any key to continue.');
  pause;

  % Clean up.
  close all;

end



%
% Check power spectra.

% FIXME - Power spectrum check NYI!



%
% Clean up.

if have_recdata_auto
  clear recdata_auto;
  clear recdata_wideband recdata_lfp recdata_spike recdata_rect;
end

if have_stimdata_auto
  clear stimdata_auto;
  clear stimdata_wideband stimdata_lfp stimdata_spike stimdata_rect;
end



%
% Banner.

disp('-- Finished auto-classifying channels.');



%
% This is the end of the file.
