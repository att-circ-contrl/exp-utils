function euChris_plotTorteWaves( signaldata, cookedmeta, ...
  window_sizes, size_labels, max_count_per_size, want_debug_plots, ...
  titlebase, fnamebase )

% function euChris_plotTorteWaves( signaldata, cookedmeta, ...
%   window_sizes, size_labels, max_count_per_size, want_debug_plots, ...
%   titlebase, fnamebase )
%
% This generates several sets of time-series plots of TORTE's estimates of
% an ephys signal's analytic components, with detection and trigger times
% overlaid.
%
% "signaldata" is a structure returned by euChris_extractSignals_loop2302(),
%   with fields as described in CHRISSIGNALS.txt.
% "cookedmeta" is an experiment metadata structure per CHRISCOOKEDMETA.txt.
% "window_sizes" is a vector containing plot durations in seconds, stepped
%   across the time series.
% "size_labels" is a filename-safe label used when creating filenames and
%   annotating titles for plots that use a given window size.
% "max_count_per_size" is a scalar indicating the maximum number of plots
%   to emit at a given size level. Plots are spaced evenly within and are
%   centered on the full time span.
% "want_debug_plots" is true to render additional plots (against the
%   full-range LFP and against the raw wideband signal), and false otherwise.
% "titlebase" is a prefix to use when constructing human-readable titles.
% "fnamebase" is a prefix to use when constructing filenames.
%
% No return value.


cols = nlPlot_getColorPalette();


% This might be NaN.
magthreshold = cookedmeta.crossmagthresh;


% These should always exist.

wb_time = signaldata.wb_time;
wb_wave = signaldata.wb_wave;
lfp_time = signaldata.lfp_time;
lfp_wave = signaldata.lfp_wave;

canon_time = signaldata.canon_time;
canon_wave = signaldata.band_wave;
canon_mag = signaldata.canon_mag;
canon_thresh = signaldata.canon_rms * magthreshold;
canon_magflag = signaldata.canon_magflag;

delayed_time = signaldata.delayed_time;
delayed_wave = signaldata.delayband_wave;
delayed_mag = signaldata.delayed_mag;
delayed_thresh = signaldata.delayed_rms * magthreshold;
delayed_magflag = signaldata.delayed_magflag;


% These might not exist.

have_torte_time = isfield(signaldata, 'torte_time');
have_torte_mag = have_torte_time && isfield(signaldata, 'torte_mag');
have_torte_phase = have_torte_time && isfield(signaldata, 'torte_phase');
have_torte_wave = have_torte_time && isfield(signaldata, 'torte_wave');

if have_torte_time
  torte_time = signaldata.torte_time;
end
if have_torte_mag
  torte_mag = signaldata.torte_mag;
end
if have_torte_phase
  torte_phase = signaldata.torte_phase;
end
if have_torte_wave
  torte_wave = signaldata.torte_wave;
end

have_torte_magdetect = ...
  have_torte_time && isfield(signaldata, 'detectmag_wave');

have_torte_phasedetect = ...
  have_torte_time && isfield(signaldata, 'detectphase_edges');
have_torte_trigused = ...
  have_torte_time && isfield(signaldata, 'trigused_edges');
have_loopback = isfield(signaldata, 'loopback_edges');

if have_torte_magdetect
  torte_mag_detect = signaldata.detectmag_wave;
end

if have_torte_phasedetect
  torte_phase_detect = signaldata.detectphase_edges;
end
if have_torte_trigused
  torte_trig_used = signaldata.trigused_edges;
end
if have_loopback
  trig_loopback = signaldata.loopback_edges;
end



% Magnitude detection.

if have_torte_mag

  % Vs ideal.

  wave_list = ...
    { { canon_time, canon_wave, cols.yel, 'LFP' }, ...
      { canon_time, canon_mag, cols.brn, 'Magnitude' }, ...
      { torte_time, torte_mag, cols.red, 'TORTE Mag' } };
  ttl_list = {};

  if have_torte_magdetect
    ttl_list = ...
      { { torte_time, torte_mag_detect, cols.blu, 'TORTE Detect' } };
  end

  euPlot_plotZoomedWaves( wave_list, ttl_list, ...
    {}, { { [0], cols.blk, '' } }, ...
    window_sizes, size_labels, max_count_per_size, ...
    'northeast', [ titlebase 'TORTE Mag Ideal' ], ...
    [ fnamebase 'magideal' ] );


  % Vs causal.

  wave_list = ...
    { { delayed_time, delayed_wave, cols.yel, 'LFP' }, ...
      { delayed_time, delayed_mag, cols.brn, 'Magnitude' }, ...
      { torte_time, torte_mag, cols.red, 'TORTE Mag' } };
  ttl_list = {};

  if have_torte_magdetect
    ttl_list = ...
      { { torte_time, torte_mag_detect, cols.blu, 'TORTE Detect' } };
  end

  euPlot_plotZoomedWaves( wave_list, ttl_list, ...
    {}, { { [0], cols.blk, '' } }, ...
    window_sizes, size_labels, max_count_per_size, ...
    'northeast', [ titlebase 'TORTE Mag Causal' ], ...
    [ fnamebase 'magcausal' ] );

end



% Phase-aligned triggering.
% This shows the reconstructed wave, too.

% We always generate these plots; the content in them varies depending
% on what's available.


% TTL signals and flags are common to both.

ttl_list = {};
if have_torte_magdetect
  ttl_list = { { torte_time, torte_mag_detect, cols.cyn, 'TORTE Detect' } };
end

flag_list = {};
if have_torte_phasedetect
  flag_list = [ flag_list ...
    { { torte_phase_detect, cols.grn, 'Phase Detect' } } ];
end
if have_torte_trigused
  flag_list = [ flag_list ...
    { { torte_trig_used, cols.blu, 'TORTE Trig' } } ];
end
if have_loopback
  flag_list = [ flag_list ...
    { { trig_loopback, cols.mag, 'Trig Real' } } ];
end


% Vs ideal.

wave_list = { { canon_time, canon_wave, cols.yel, 'LFP Ideal' } };
if have_torte_wave
  wave_list = [ wave_list ...
    { { torte_time, torte_wave, cols.red, 'TORTE Recon' } } ];
end

euPlot_plotZoomedWaves( wave_list, ttl_list, flag_list, ...
  { { [0], cols.blk, '' } }, ...
  window_sizes, size_labels, max_count_per_size, ...
  'northeast', [ titlebase 'TORTE Trig Ideal' ], ...
  [ fnamebase 'trigideal' ] );


% Vs causal.

wave_list = { { delayed_time, delayed_wave, cols.brn, 'LFP Causal' } };
if have_torte_wave
  wave_list = [ wave_list ...
    { { torte_time, torte_wave, cols.red, 'TORTE Recon' } } ];
end

euPlot_plotZoomedWaves( wave_list, ttl_list, flag_list, ...
  { { [0], cols.blk, '' } }, ...
  window_sizes, size_labels, max_count_per_size, ...
  'northeast', [ titlebase 'TORTE Trig Causal' ], ...
  [ fnamebase 'trigcausal' ] );



% Debug plots (vs wideband and wide-cut LFP).

if want_debug_plots && have_torte_mag

  % Wide-cut LFP, ideal narrow-band.

  euPlot_plotZoomedWaves( ...
    { { lfp_time, lfp_wave, cols.cyn, 'Wide LFP' }, ...
      { canon_time, canon_wave, cols.yel, 'In-Band LFP' }, ...
      { canon_time, canon_mag, cols.brn, 'Magnitude' }, ...
      { torte_time, torte_mag, cols.red, 'TORTE Mag' } }, ...
    {}, {}, { { [0], cols.blk, '' } }, ...
    window_sizes, size_labels, max_count_per_size, ...
    'northeast', [ titlebase 'Wide LFP' ], ...
    [ fnamebase 'widelfp' ] );


  % Full wide-band, ideal narrow-band.

  euPlot_plotZoomedWaves( ...
    { { wb_time, wb_wave, cols.cyn, 'Wideband' }, ...
      { canon_time, canon_wave, cols.yel, 'In-Band LFP' }, ...
      { canon_time, canon_mag, cols.brn, 'Magnitude' }, ...
      { torte_time, torte_mag, cols.red, 'TORTE Mag' } }, ...
    {}, {}, { { [0], cols.blk, '' } }, ...
    window_sizes, size_labels, max_count_per_size, ...
    'northeast', [ titlebase 'Raw Wideband' ], ...
    [ fnamebase 'wideraw' ] );

end



% Done.
end


%
% This is the end of the file.
