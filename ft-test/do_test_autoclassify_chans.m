% Field Trip sample script / test script - Automatic channel classification.
% Written by Christopher Thomas.

% This reads a small section of the analog data, performs signal processing,
% and attempts to determine which channels contain valid data.
% FIXME - Doing this by reading and setting workspace variables directly.
%
% Variables that get set:
%
%   rec_quantized
%   stim_quantized
%
%   rec_has_dropouts
%   stim_has_dropouts
%   rec_dropout_frac
%   stim_dropout_frac
%
%   rec_has_artifacts
%   stim_has_artifacts
%   rec_artifact_frac
%   stim_artifact_frac
%
%   rec_has_peaks_raw
%   rec_peakfreqs_raw
%   rec_peakheights_raw
%   rec_peakwidths_raw
%   rec_has_peaks_filt
%   rec_peakfreqs_filt
%   rec_peakheights_filt
%   rec_peakwidths_filt
%
%   stim_has_peaks_raw
%   stim_peakfreqs_raw
%   stim_peakheights_raw
%   stim_peakwidths_raw
%   stim_has_peaks_filt
%   stim_peakfreqs_filt
%   stim_peakheights_filt
%   stim_peakwidths_filt
%
%   rec_peakspectmags_raw
%   rec_peakspectfreqs_raw
%   rec_peakspectmags_filt
%   rec_peakspectfreqs_filt
%
%   stim_peakspectmags_raw
%   stim_peakspectfreqs_raw
%   stim_peakspectmags_filt
%   stim_peakspectfreqs_filt
%
%   rec_lfpgood
%   rec_lfptype
%   rec_lfpexponent
%   rec_lfpspectpowers
%   rec_lfpspectfreqs
%   rec_lfpfitpowers
%
%   stim_lfpgood
%   stim_lfptype
%   stim_lfpexponent
%   stim_lfpspectpowers
%   stim_lfpspectfreqs
%   stim_lfpfitpowers



%
% Load cached results from disk, if requested.
% If we successfully load data, bail out without further processing.

if want_cache_autoclassify
  fname = [ datadir filesep 'autoclassify.mat' ];

  if isfile(fname)

    % Load the data we previously saved.
    disp('-- Loading channel auto-classification results.');
    load(fname);

    % Generate reports.

    thismsg = helper_reportQuantized( ...
      [ plotdir filesep 'autodetect-quantization.txt' ], ...
      rec_quantized, stim_quantized, ...
      rec_channels_ephys, stim_channels_ephys );
    disp(thismsg);

    thismsg = helper_reportDropoutArtifact( ...
      [ plotdir filesep 'autodetect-dropouts-artifacts.txt' ], ...
      rec_has_artifacts, stim_has_artifacts, ...
      rec_artifact_frac, stim_artifact_frac, ...
      rec_has_dropouts, stim_has_dropouts, ...
      rec_dropout_frac, stim_dropout_frac, ...
      rec_channels_ephys, stim_channels_ephys );
    disp(thismsg);

    % Banner.
    disp('-- Finished loading.');

    % We've loaded cached results. Bail out of this portion of the script.
    return;

  end
end



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

  % Report the window span.
  disp(sprintf( ...
    '.. Read window is:   %.1f - %.1f s (rec)   %.1f - %.1f s (stim).', ...
    preproc_config_rec_span_autotype(1) / rechdr.Fs, ...
    preproc_config_rec_span_autotype(2) / rechdr.Fs, ...
    preproc_config_stim_span_autotype(1) / stimhdr.Fs, ...
    preproc_config_stim_span_autotype(2) / stimhdr.Fs ));

  if isempty(rec_channels_ephys)
    disp('.. Skipping recorder (no channels selected).');
  else
    preproc_config_rec_auto.channel = rec_channels_ephys;
    recdata_auto = ft_preprocessing(preproc_config_rec_auto);
    have_recdata_auto = true;
  end

  if isempty(stim_channels_ephys)
    disp('.. Skipping stimulator (no channels selected).');
  else
    preproc_config_stim_auto.channel = stim_channels_ephys;
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

nchans_rec = length(rec_channels_ephys);
nchans_stim = length(stim_channels_ephys);

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

  thismsg = helper_reportQuantized( ...
    [ plotdir filesep 'autodetect-quantization.txt' ], ...
    rec_quantized, stim_quantized, ...
    rec_channels_ephys, stim_channels_ephys );

  disp(thismsg);


  % Done.
  disp('-- Finished checking for quantization.');

end



%
% Filter the continuous ephys data.
% This will have edge effects, but that should be tolerable.

% NOTE - Handling recorder and stimulator data separately, for simplicity.

% NOTE - We're assuming that the window is short enough for de-trending to
% be appropriate (i.e. that it's ramped, not randomly wandering).


% NOTE - We're keeping the unfiltered signal as "auto" and the power filtered
% signal as "wideband", to measure how well the power filter is working.


% Banner.
disp('-- Filtering windowed ephys data.');


if have_recdata_auto

  %
  % De-trending and power-line filtering.

  disp('.. [Rec] De-trending and removing power-line noise.');
  tic();

  % Save the filtered signal as "wideband". Keep the unfiltered around too.

  extra_notches = [];
  if isfield( thisdataset, 'extra_notches' )
    extra_notches = thisdataset.extra_notches;
  end

  recdata_wideband = doSignalConditioning( recdata_auto, ...
    power_freq, power_filter_modes, filter_type_long, ...
    extra_notches );

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. [Rec] Power line noise removed in %s.', thisduration ));


  %
  % NOTE - Not removing artifacts; we're _looking_ for artifacts.


  %
  % Get spike and LFP and rectified waveforms.

  % We already have the wideband signal.

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

  %
  % De-trending and power-line filtering.

  disp('.. [Stim] De-trending and removing power-line noise.');
  tic();

  % Save the filtered signal as "wideband". Keep the unfiltered around too.

  extra_notches = [];
  if isfield( thisdataset, 'extra_notches' )
    extra_notches = thisdataset.extra_notches;
  end

  stimdata_wideband = doSignalConditioning( stimdata_auto, ...
    power_freq, power_filter_modes, filter_type_long, ...
    extra_notches );

  thisduration = euUtil_makePrettyTime(toc());
  disp(sprintf( '.. [Stim] Power line noise removed in %s.', thisduration ));


  %
  % NOTE - Not removing artifacts; we're _looking_ for artifacts.


  %
  % Get spike and LFP and rectified waveforms.

  % We already have the wideband signal.

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
rec_channels_ephys{cidx}, min(thisrelative), max(thisrelative) ));
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
stim_channels_ephys{cidx}, min(thisrelative), max(thisrelative) ));
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

thismsg = helper_reportDropoutArtifact( ...
  [ plotdir filesep 'autodetect-dropouts-artifacts.txt' ], ...
  rec_has_artifacts, stim_has_artifacts, ...
  rec_artifact_frac, stim_artifact_frac, ...
  rec_has_dropouts, stim_has_dropouts, ...
  rec_dropout_frac, stim_dropout_frac, ...
  rec_channels_ephys, stim_channels_ephys );

disp(thismsg);


disp('-- Finished checking for dropouts and artifacts.');



%
% Check power spectra.


% Power spectrum peaks.

disp('-- Checking for narrow-band noise.');


rec_peakfreqs_raw = {};
rec_peakheights_raw = {};
rec_peakwidths_raw = {};

rec_peakfreqs_filt = {};
rec_peakheights_filt = {};
rec_peakwidths_filt = {};

rec_has_peaks_raw = logical([]);
rec_has_peaks_filt = logical([]);

rec_peakspectmags_raw = {};
rec_peakspectfreqs_raw = {};
rec_peakspectmags_filt = {};
rec_peakspectfreqs_filt = {};


if have_recdata_auto

  for cidx = 1:nchans_rec
    thisdata_raw = recdata_auto.trial{1}(cidx,:);
    rawrate = recdata_auto.fsample;

    thisdata_filt = recdata_wideband.trial{1}(cidx,:);
    filtrate = recdata_wideband.fsample;


    [ peakfreqs peakheights peakwidths spectmags spectfreqs ] = ...
      nlProc_findSpectrumPeaks( thisdata_raw, rawrate, ...
        noisepeakwidth, noisebackgroundwidth, noisepeakthreshold );

    rec_peakfreqs_raw{cidx} = peakfreqs;
    rec_peakheights_raw{cidx} = peakheights;
    rec_peakwidths_raw{cidx} = peakwidths;

    rec_peakspectmags_raw{cidx} = spectmags;
    rec_peakspectfreqs_raw{cidx} = spectfreqs;

    rec_has_peaks_raw(cidx) = ~isempty(peakfreqs);


    [ peakfreqs peakheights peakwidths spectmags spectfreqs ] = ...
      nlProc_findSpectrumPeaks( thisdata_filt, filtrate, ...
        noisepeakwidth, noisebackgroundwidth, noisepeakthreshold );

    rec_peakfreqs_filt{cidx} = peakfreqs;
    rec_peakheights_filt{cidx} = peakheights;
    rec_peakwidths_filt{cidx} = peakwidths;

    rec_peakspectmags_filt{cidx} = spectmags;
    rec_peakspectfreqs_filt{cidx} = spectfreqs;

    rec_has_peaks_filt(cidx) = ~isempty(peakfreqs);
  end

end


stim_peakfreqs_raw = {};
stim_peakheights_raw = {};
stim_peakwidths_raw = {};

stim_peakfreqs_filt = {};
stim_peakheights_filt = {};
stim_peakwidths_filt = {};

stim_has_peaks_raw = logical([]);
stim_has_peaks_filt = logical([]);

stim_peakspectmags_raw = {};
stim_peakspectfreqs_raw = {};
stim_peakspectmags_filt = {};
stim_peakspectfreqs_filt = {};


if have_stimdata_auto

  for cidx = 1:nchans_stim
    thisdata_raw = stimdata_auto.trial{1}(cidx,:);
    rawrate = stimdata_auto.fsample;

    thisdata_filt = stimdata_wideband.trial{1}(cidx,:);
    filtrate = stimdata_wideband.fsample;


    [ peakfreqs peakheights peakwidths spectmags spectfreqs ] = ...
      nlProc_findSpectrumPeaks( thisdata_raw, rawrate, ...
        noisepeakwidth, noisebackgroundwidth, noisepeakthreshold );

    stim_peakfreqs_raw{cidx} = peakfreqs;
    stim_peakheights_raw{cidx} = peakheights;
    stim_peakwidths_raw{cidx} = peakwidths;

    stim_peakspectmags_raw{cidx} = spectmags;
    stim_peakspectfreqs_raw{cidx} = spectfreqs;

    stim_has_peaks_raw(cidx) = ~isempty(peakfreqs);


    [ peakfreqs peakheights peakwidths spectmags spectfreqs ] = ...
      nlProc_findSpectrumPeaks( thisdata_filt, filtrate, ...
        noisepeakwidth, noisebackgroundwidth, noisepeakthreshold );

    stim_peakfreqs_filt{cidx} = peakfreqs;
    stim_peakheights_filt{cidx} = peakheights;
    stim_peakwidths_filt{cidx} = peakwidths;

    stim_peakspectmags_filt{cidx} = spectmags;
    stim_peakspectfreqs_filt{cidx} = spectfreqs;

    stim_has_peaks_filt(cidx) = ~isempty(peakfreqs);
  end

end


% Narrow-band noise report.

thismsg = helper_reportNarrowBandNoise( ...
  [ plotdir filesep 'autodetect-narrownoise-raw.txt' ], ...
  rec_has_peaks_raw, stim_has_peaks_raw, ...
  rec_peakfreqs_raw, stim_peakfreqs_raw, ...
  rec_peakheights_raw, stim_peakheights_raw, ...
  rec_peakwidths_raw, stim_peakwidths_raw, ...
  rec_channels_ephys, stim_channels_ephys );

% FIXME - Diagnostics.
if true
  disp('.. Before notch filtering:');
  disp(thismsg);
end

disp('.. After notch filtering:');
thismsg = helper_reportNarrowBandNoise( ...
  [ plotdir filesep 'autodetect-narrownoise.txt' ], ...
  rec_has_peaks_filt, stim_has_peaks_filt, ...
  rec_peakfreqs_filt, stim_peakfreqs_filt, ...
  rec_peakheights_filt, stim_peakheights_filt, ...
  rec_peakwidths_filt, stim_peakwidths_filt, ...
  rec_channels_ephys, stim_channels_ephys );

disp(thismsg);


if want_plots
  doPlotStackedSpectra( [ plotdir filesep 'noise-narrow-rec-raw.png' ], ...
    rec_peakspectmags_raw, rec_peakspectfreqs_raw, ...
    'magnitude', rec_peakfreqs_raw, {}, {}, ...
    rec_channels_ephys, 'Recorder Narrow-Band Noise (raw)' );

  doPlotStackedSpectra( [ plotdir filesep 'noise-narrow-rec-filt.png' ], ...
    rec_peakspectmags_filt, rec_peakspectfreqs_filt, ...
    'magnitude', rec_peakfreqs_filt, {}, {}, ...
    rec_channels_ephys, 'Recorder Narrow-Band Noise (filtered)' );

  doPlotStackedSpectra( [ plotdir filesep 'noise-narrow-stim-raw.png' ], ...
    stim_peakspectmags_raw, stim_peakspectfreqs_raw, ...
    'mangitude', stim_peakfreqs_raw, {}, {}, ...
    stim_channels_ephys, 'Stimulator Narrow-Band Noise (raw)' );

  doPlotStackedSpectra( [ plotdir filesep 'noise-narrow-stim-filt.png' ], ...
    stim_peakspectmags_filt, stim_peakspectfreqs_filt, ...
    'magnitude', stim_peakfreqs_filt, {}, {}, ...
    stim_channels_ephys, 'Stimulator Narrow-Band Noise (filtered)' );
end


disp('-- Finished checking for narrow-band noise.');


% Power spectrum low-frequency shape.

disp('-- Checking LFP noise spectrum shape.');


rec_lfpgood = logical([]);
rec_lfptype = {};
rec_lfpexponent = [];
rec_lfpspectpowers = {};
rec_lfpspectfreqs = {};
rec_lfpfitpowers = {};

if have_recdata_auto
  for cidx = 1:nchans_rec
    thisdata_lfp = recdata_lfp.trial{1}(cidx,:);
    samprate = recdata_lfp.fsample;

    [ is_lfp typelabel fitexponent spectpowers spectfreqs fitpowers] = ...
      nlProc_examineLFPSpectrum( thisdata_lfp, samprate, ...
        lfpspectrange, lfpbinwidth );

    rec_lfpgood(cidx) = is_lfp;
    rec_lfptype{cidx} = typelabel;
    rec_lfpexponent(cidx) = fitexponent;

    rec_lfpspectpowers{cidx} = spectpowers;
    rec_lfpspectfreqs{cidx} = spectfreqs;
    rec_lfpfitpowers{cidx} = fitpowers;
  end
end

stim_lfpgood = logical([]);
stim_lfptype = {};
stim_lfpexponent = [];
stim_lfpspectpowers = {};
stim_lfpspectfreqs = {};
stim_lfpfitpowers = {};

if have_stimdata_auto
  for cidx = 1:nchans_stim
    thisdata_lfp = stimdata_lfp.trial{1}(cidx,:);
    samprate = stimdata_lfp.fsample;

    [ is_lfp typelabel fitexponent spectpowers spectfreqs fitpowers] = ...
      nlProc_examineLFPSpectrum( thisdata_lfp, samprate, ...
        lfpspectrange, lfpbinwidth );

    stim_lfpgood(cidx) = is_lfp;
    stim_lfptype{cidx} = typelabel;
    stim_lfpexponent(cidx) = fitexponent;

    stim_lfpspectpowers{cidx} = spectpowers;
    stim_lfpspectfreqs{cidx} = spectfreqs;
    stim_lfpfitpowers{cidx} = fitpowers;
  end
end


% LFP spectrum report.

thismsg = helper_reportLFPShape( ...
  [ plotdir filesep 'autodetect-lfp.txt' ], ...
  rec_lfpgood, rec_lfptype, rec_lfpexponent, ...
  stim_lfpgood, stim_lfptype, stim_lfpexponent, ...
  rec_channels_ephys, stim_channels_ephys );

disp(thismsg);


if want_plots
  doPlotStackedSpectra( [ plotdir filesep 'lfp-background-rec.png' ], ...
    rec_lfpspectpowers, rec_lfpspectfreqs, ...
    'power', {}, rec_lfpfitpowers, rec_lfpspectfreqs, ...
    rec_channels_ephys, 'Recorder LFP Power Spectrum' );

  doPlotStackedSpectra( [ plotdir filesep 'lfp-background-stim.png' ], ...
    stim_lfpspectpowers, stim_lfpspectfreqs, ...
    'power', {}, stim_lfpfitpowers, stim_lfpspectfreqs, ...
    stim_channels_ephys, 'Stimulator LFP Power Spectrum' );
end


disp('-- Finished checking LFP noise spectrum shape.');



%
% Save results to disk, if requested.

if want_save_data
  fname = [ datadir filesep 'autoclassify.mat' ];

  if isfile(fname)
    delete(fname);
  end

  disp('-- Saving channel auto-classification results.');

  save( fname, ...
    'rec_channels_ephys', 'stim_channels_ephys', ...
    'rec_quantized', 'stim_quantized', ...
    'rec_has_dropouts', 'stim_has_dropouts', ...
    'rec_dropout_frac', 'stim_dropout_frac', ...
    'rec_has_artifacts', 'stim_has_artifacts', ...
    'rec_artifact_frac', 'stim_artifact_frac', ...
    'rec_has_peaks_raw', 'rec_has_peaks_filt', ...
    'rec_peakfreqs_raw', 'rec_peakfreqs_filt', ...
    'rec_peakheights_raw', 'rec_peakheights_filt', ...
    'rec_peakwidths_raw', 'rec_peakwidths_filt', ...
    'stim_has_peaks_raw', 'stim_has_peaks_filt', ...
    'stim_peakfreqs_raw', 'stim_peakfreqs_filt', ...
    'stim_peakheights_raw', 'stim_peakheights_filt', ...
    'stim_peakwidths_raw', 'stim_peakwidths_filt', ...
    'rec_peakspectmags_raw', 'rec_peakspectfreqs_raw', ...
    'rec_peakspectmags_filt', 'rec_peakspectfreqs_filt', ...
    'stim_peakspectmags_raw', 'stim_peakspectfreqs_raw', ...
    'stim_peakspectmags_filt', 'stim_peakspectfreqs_filt', ...
    'rec_lfpgood', 'rec_lfptype', 'rec_lfpexponent', ...
    'rec_lfpspectpowers', 'rec_lfpspectfreqs', 'rec_lfpfitpowers', ...
    'stim_lfpgood', 'stim_lfptype', 'stim_lfpexponent', ...
    'stim_lfpspectpowers', 'stim_lfpspectfreqs', 'stim_lfpfitpowers', ...
    '-v7.3' );

  disp('-- Finished saving.');
end



%
% Inspect the waveform data, if requested.

if want_browser

  disp('-- Rendering waveforms.');

  if have_recdata_auto
    doBrowseFiltered( 'Rec', ...
      recdata_wideband, recdata_lfp, recdata_spike, recdata_rect );
  end

  if have_stimdata_auto
    doBrowseFiltered( 'Stim', ...
      stimdata_wideband, stimdata_lfp, stimdata_spike, stimdata_rect );
  end

  disp('-- Press any key to continue.');
  pause;

  % Clean up.
  close all;

end



%
% Clean up intermediate data.

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
% Helper functions.


% Quantization report.
% If fname is non-empty, the report is also written to a file.

function reporttext = helper_reportQuantized( ...
  fname, ...
  rec_quantized, stim_quantized, ...
  rec_channels_ephys, stim_channels_ephys )

  nchans_rec = length(rec_channels_ephys);
  nchans_stim = length(stim_channels_ephys);

  reporttext = sprintf( ...
    '.. %d of %d recording channels were quantized.\n', ...
    sum(rec_quantized), nchans_rec );

  for cidx = 1:nchans_rec
    if rec_quantized(cidx)
      reporttext = [ reporttext ...
        '  ' rec_channels_ephys{cidx} '\n' ];
    end
  end

  reporttext = [ reporttext ...
    sprintf( '.. %d of %d stimulation channels were quantized.\n', ...
      sum(stim_quantized), nchans_stim ) ];

  for cidx = 1:nchans_stim
    if stim_quantized(cidx)
      reporttext = [ reporttext ...
        '  ' stim_channels_ephys{cidx} '\n' ];
    end
  end

  if ~isempty(fname)
    thisfid = fopen(fname, 'w');
    fwrite(thisfid, reporttext);
    fclose(thisfid);
  end

end



% Dropout and artifact report.
% If fname is non-empty, the report is also written to a file.

function reporttext = helper_reportDropoutArtifact( ...
  fname, ...
  rec_has_artifacts, stim_has_artifacts, ...
  rec_artifact_frac, stim_artifact_frac, ...
  rec_has_dropouts, stim_has_dropouts, ...
  rec_dropout_frac, stim_dropout_frac, ...
  rec_channels_ephys, stim_channels_ephys )

  nchans_rec = length(rec_channels_ephys);
  nchans_stim = length(stim_channels_ephys);

  reporttext = sprintf( ...
    '.. %d of %d recording channels had artifacts.\n', ...
    sum(rec_has_artifacts), nchans_rec );

  for cidx = 1:nchans_rec
    if rec_has_artifacts(cidx)
      reporttext = [ reporttext ...
        sprintf( '  %s  (%.1f %%)\n', ...
          rec_channels_ephys{cidx}, 100 * rec_artifact_frac(cidx) ) ];
    end
  end

  reporttext = [ reporttext ...
    sprintf( '.. %d of %d stimulation channels had artifacts.\n', ...
      sum(stim_has_artifacts), nchans_stim ) ];

  for cidx = 1:nchans_stim
    if stim_has_artifacts(cidx)
      reporttext = [ reporttext ...
        sprintf( '  %s  (%.1f %%)\n', ...
          stim_channels_ephys{cidx}, 100 * stim_artifact_frac(cidx) ) ];
    end
  end

  reporttext = [ reporttext ...
    sprintf( '.. %d of %d recording channels had drop-outs.\n', ...
      sum(rec_has_dropouts), nchans_rec ) ];

  for cidx = 1:nchans_rec
    if rec_has_dropouts(cidx)
      reporttext = [ reporttext ...
        sprintf( '  %s  (%.1f %%)\n', ...
          rec_channels_ephys{cidx}, 100 * rec_dropout_frac(cidx) ) ];
    end
  end

  reporttext = [ reporttext ...
    sprintf( '.. %d of %d stimulation channels had drop-outs.\n', ...
      sum(stim_has_dropouts), nchans_stim ) ];

  for cidx = 1:nchans_stim
    if stim_has_dropouts(cidx)
      reporttext = [ reporttext ...
        sprintf( '  %s  (%.1f %%)\n', ...
          stim_channels_ephys{cidx}, 100 * stim_dropout_frac(cidx) ) ];
    end
  end

  if ~isempty(fname)
    thisfid = fopen(fname, 'w');
    fwrite(thisfid, reporttext);
    fclose(thisfid);
  end

end



% Narrow-band noise peaks report.
% If fname is non-empty, the report is also written to a file.

function reporttext = helper_reportNarrowBandNoise( ...
  fname, ...
  rec_has_peaks, stim_has_peaks, ...
  rec_peakfreqs, stim_peakfreqs, ...
  rec_peakheights, stim_peakheights, ...
  rec_peakwidths, stim_peakwidths, ...
  rec_channels_ephys, stim_channels_ephys )

  nchans_rec = length(rec_channels_ephys);
  nchans_stim = length(stim_channels_ephys);


  reporttext = sprintf( ...
    '.. %d of %d recording channels had narrow-band noise.\n', ...
    sum(rec_has_peaks), nchans_rec );

  if ~isempty(rec_has_peaks)
    for cidx = 1:nchans_rec
      if rec_has_peaks(cidx)
        freqlist = rec_peakfreqs{cidx};
        heightlist = rec_peakheights{cidx};
        widthlist = rec_peakwidths{cidx};

        reporttext = [ reporttext ...
          '  ' rec_channels_ephys{cidx} ':' ...
          helper_makePrettyPeakList( freqlist, heightlist, widthlist ) ...
          sprintf('\n') ];
      end
    end
  end


  reporttext = [ reporttext sprintf( ...
    '.. %d of %d stimulation channels had narrow-band noise.\n', ...
    sum(stim_has_peaks), nchans_stim ) ];

  if ~isempty(stim_has_peaks)
    for cidx = 1:nchans_stim
      if stim_has_peaks(cidx)
        freqlist = stim_peakfreqs{cidx};
        heightlist = stim_peakheights{cidx};
        widthlist = stim_peakwidths{cidx};

        reporttext = [ reporttext ...
          '  ' stim_channels_ephys{cidx} ':' ...
          helper_makePrettyPeakList( freqlist, heightlist, widthlist ) ...
          sprintf('\n') ];
      end
    end
  end


  if ~isempty(fname)
    thisfid = fopen(fname, 'w');
    fwrite(thisfid, reporttext);
    fclose(thisfid);
  end

end



% Format a pretty string containing a list of spectrum peaks.

function prettytext = ...
  helper_makePrettyPeakList( freqlist, heightlist, widthlist )

  prettytext = '';

  for pidx = 1:length(freqlist)
    thisfreq = freqlist(pidx);
    thisheight = heightlist(pidx);
    thiswidth = widthlist(pidx);

    prettytext = [ prettytext ...
      sprintf( '  %.1f  (%.1fx avg %.2f Hz)', ...
        thisfreq, thisheight, thiswidth * thisfreq ) ];
  end

end



% LFP spectrum shape report.
% If fname is non-empty, the report is also written to a file.

function reporttext = helper_reportLFPShape( ...
  fname, ...
  rec_lfpgood, rec_lfptype, rec_lfpexponent, ...
  stim_lfpgood, stim_lfptype, stim_lfpexponent, ...
  rec_channels_ephys, stim_channels_ephys )


  nchans_rec = length(rec_channels_ephys);
  nchans_stim = length(stim_channels_ephys);


  reporttext = sprintf('.. Recording channels by type:\n');

  if ~isempty(rec_lfptype)
    typetally = struct();

    for cidx = 1:nchans_rec
      thistype = rec_lfptype{cidx};

      if isfield(typetally, thistype)
        typetally.(thistype) = typetally.(thistype) + 1;
      else
        typetally.(thistype) = 1;
      end
    end

    typelist = sort(fieldnames(typetally));
    for tidx = 1:length(typelist)
      thistype = typelist{tidx};
      reporttext = [ reporttext sprintf( '  %4d - "%s"\n', ...
        typetally.(thistype), thistype ) ];
    end
  end

  if ~isempty(rec_lfpgood)
    reporttext = [ reporttext sprintf( ...
      '.. %d of %d recorder LFPs good.', ...
      sum(rec_lfpgood), nchans_rec ) ];
  end

  % FIXME - Not reporting the exponent list.


  reporttext = [ reporttext sprintf('.. Stimulation channels by type:\n') ];

  if ~isempty(stim_lfptype)
    typetally = struct();

    for cidx = 1:nchans_stim
      thistype = stim_lfptype{cidx};

      if isfield(typetally, thistype)
        typetally.(thistype) = typetally.(thistype) + 1;
      else
        typetally.(thistype) = 1;
      end
    end

    typelist = sort(fieldnames(typetally));
    for tidx = 1:length(typelist)
      thistype = typelist{tidx};
      reporttext = [ reporttext sprintf( '  %4d - "%s"\n', ...
        typetally.(thistype), thistype ) ];
    end
  end

  if ~isempty(stim_lfpgood)
    reporttext = [ reporttext sprintf( ...
      '.. %d of %d stimulator LFPs good.', ...
      sum(stim_lfpgood), nchans_stim ) ];
  end

  % FIXME - Not reporting the exponent list.


  if ~isempty(fname)
    thisfid = fopen(fname, 'w');
    fwrite(thisfid, reporttext);
    fclose(thisfid);
  end

end



%
% This is the end of the file.
