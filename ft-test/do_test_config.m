% Field Trip sample script / test script - Configuration.
% Written by Christopher Thomas.


%
% Behavior switches.
% These are what you'll usually want to edit.


% Trimming control for monolithic data processing.
% The idea is to trim big datasets to be small enough to fit in memory.
% 100 seconds is okay with 128ch, 1000 seconds is okay with 4ch.

want_crop_big = true;
crop_window_seconds = 100;
%crop_window_seconds = 1000;
want_detail_zoom = false;


% Ephys channel subset control.
% The idea is to read a small number of channels for debugging, for datasets
% that take a while to read.
% Alternatively we can force it to read all channels even when some of those
% are known to be floating.

want_chan_subset = true;
want_chan_include_unused = false;

% Set this to true to re-reference where metadata is available for that.
want_reref = true;


% Number of trials to batch-process at once.
% Memory footprint is on the order of 1 GB per trial for 128ch.
% Set this to "inf" to process all trials in a single batch.

%trials_per_batch = inf;
trials_per_batch = 10;

% Debugging switch - process only one batch (in the middle of the data).
want_one_batch = true;


% Turn on and off various processing steps.

% Try to automatically label ephys channels as good/bad/floating/etc.
% We identify dropouts and quantization in the time domain, and narrow-band
% noise in the frequency domain. We guess at good/bad by doing a power-law
% fit to the LFP in the frequency domain.
want_auto_channel_types = true;

% This debugging switch forces auto-typing to happen near the beginning of
% the data instead of in the middle.
want_auto_channel_early = false;

% Process continuous data before aligning and segmenting.
% This is mostly for debugging.
want_process_monolithic = false;

% Compare and align Unity and TTL data.
want_align = true;
% Pretend to align data even if we don't have enough information.
want_force_align = true;

% Build trial definitions.
want_define_trials = true;

% Process segmented data.
want_process_trials = true;

% Bring up the GUI data browser after processing (for debugging).
want_browser = false;

% Generate plots (for debugging).
want_plots = true;


% Optionally save data from various steps to disk.
% Optionally load previously-saved data instead of processing raw data.

want_save_data = true;

want_cache_autoclassify = true;
want_cache_monolithic = true;
want_cache_align_raw = true;
want_cache_align_done = true;
% Trial _definitions_ aren't cached; it's faster to rebuild them.
% Trial _data_ can be cached.
want_cache_epoched = true;


% Debugging switch - skip dealing with USE gaze and frame data, as they're
% enormous and take a while to save/load.

debug_skip_gaze = false;
debug_skip_frame = false;



%
% Various magic values.
% You usually won't want to edit these.


% Output directories.

plotdir = 'plots';
datadir = 'output';


% Automatic channel classification.

% Analysis window duration in seconds for automatically testing for good/bad
% channels.
classify_window_seconds = 30;

% Anything with a range of this many bits or lower is flagged as quantized.
quantization_bits = 8;

% Anything with a smoothed rectified signal amplitude this far above or
% below the median is flagged as an artifact or drop-out, respectively, for
% classification purposes.
artifact_rect_threshold = 5;
dropout_rect_threshold = 0.3;

% Approximate duration of artifacts and dropouts, in seconds.
% This should be at least 5x longer than spike durations.
% Anything within a factor of 2-3 of this will get recognized, at minimum.
artifact_dropout_time = 0.02;

% Channels with more than this fraction of artifacts or dropouts are flagged
% as bad.
artifact_bad_frac = 0.01;
dropout_bad_frac = 0.01;

% Tuning parameters for looking for narrow-band noise.
% See nlProc_findSpectrumPeaks() for discussion.
if true
  % Relatively wide search bins, relatively insensitive.
  noisepeakwidth = 0.1;
  noisebackgroundwidth = 2.0;
  noisepeakthreshold = 3.0;
elseif true
  % Relatively narrow search bins. Somewhat more sensitive.
  noisepeakwidth = 0.03;
  noisebackgroundwidth = 1.5;
  noisepeakthreshold = 4.0;
else
  % Very narrow search bins. This is too sensitive (lots of harmonics).
  noisepeakwidth = 0.01;
  noisebackgroundwidth = 1.5;
  noisepeakthreshold = 4.0;
end

% Tuning parameters for looking at the LFP spectrum shape.
% See nlProc_examineLFPSpectrum() for discussion.
lfpspectrange = [ 4 200 ];
lfpbinwidth = 0.03;

% Tuning parameters for looking at correlations between channels.
% See nlProc_findCorrelatedChannels() for discussion.
% Actual sets of floating channels tend to have R values of 0.99 or so.
correl_abs_thresh = 0.9;
correl_rel_thresh = 4.0;


% Analog signal filtering.

% The power frequency filter filters the fundamental mode and some of the
% harmonics of the power line frequency. Mode count should be 2-3 typically.
power_freq = 60.0;
power_filter_modes = 3;

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


% Event code processing.

evcodebytes = 2;
evcodeendian = 'big';


% Time alignment.

% For coarse windows, one candidate is picked within the window and matched
% against other candidates. The window is walked forwards by its radius.
% Constant-delay alignment is performed using the first coarse window value.
aligncoarsewindows = [ 100.0 ];

% For medium windows, each event is considered as the center of a window and
% is matched against other candidates in the window.
alignmedwindows = [ 1.0 ];

% For fine alignment, each event is considered as the center of a window,
% all events in the window are considered to match their nearest candidates,
% and a fine-tuning offset is calculated for that window position.
alignfinewindow = 0.1;

% Outlier time-deltas will substantially skew time estimates around them.
alignoutliersigma = 4.0;

% This should either be 'quiet' or 'normal'. 'verbose' is for debugging.
alignverbosity = 'normal';


% Epoch segmentation.

% We're always using 'TrlStart' and 'TrlEnd' to identify trials.
% Those aren't stored here.

% To identify the span to _save_, we use 'trialstartcode' and 'trialendcode'.
% The trial starts at the _latest_ start code seen and ends at the _earliest_
% end code seen.
trialstartcodes = { 'TrlStart' };
trialendcodes = { 'TrlEnd' };

% We want to add a halo to give filters time to stabilize. This should be
% at least 3 times the longest corner period and preferably 10 times.
% The problem is that artifacts may occur at certain points in the trial
% (e.g. when rewards are given), and those may cause large filter artifacts.
trialstartpadsecs = 3.0;
trialendpadsecs = 3.0;

% We want to examine multiple time alignment cases (e.g. cue, choice, and
% feedback alignment).
% For each case, there may be multiple codes to align to (e.g. "correct" vs
% "incorrect"). We align to the _first_ such code seen, for a given case.
% Remember to use pairs of braces so that we get one structure instead of
% an array.
trialaligncodes = struct( 'cue', {{ 'StimOn' }} );


% Table columns to convert to FT waveform data.

% Cooked gaze coordinates from FrameData.
% NOTE - There's an 'EyePositionZ', but it doesn't contain useful data.
% NOTE - In the sample dataset, absolute position is -1k..+2k, and relative
% position is -1..+2, roughly.
frame_gaze_cols = { 'EyePositionX', 'EyePositionY', ...
  'RelativeEyePositionX', 'RelativeEyePositionY' };

% Sampling rate for cooked gaze data.
gaze_rate = lfp_rate;


% File I/O.

% The number of channels to load into memory at one time, when loading.
% This takes up at least 1 GB per channel-hour.
memchans = 4;

% Patterns that various channel names match.
% See "ft_channelselection" for special names. Use "*" as a wildcard.
name_patterns_ephys = { 'Amp*', 'CH*' };
name_patterns_digital = { 'Din*', 'Dout*', 'DigBits*', 'DigWords*' };
name_patterns_stim_current = { 'Stim*' };
name_patterns_stim_flags = { 'Flags*' };

% Which types of data to read.
% We usually want all data; this lets us turn off elements for testing.

want_data_ephys = true;
want_data_ttl = true;
want_data_stim = true;
want_data_events = true;



%
% This is the end of the file.
