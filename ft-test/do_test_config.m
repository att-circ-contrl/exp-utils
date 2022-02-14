% Field Trip sample script / test script - Configuration.
% Written by Christopher Thomas.


%
% Behavior switches.
% These are what you'll usually want to edit.


% Trimming control.
% The idea is to trim big datasets to be small enough to fit in memory.
% 100 seconds is okay with 128ch, 1000 seconds is okay with 4ch.

want_crop_big = true;
crop_window_seconds = 100;
%crop_window_seconds = 1000;
want_detail_zoom = false;


% Ephys channel subset control.
% The idea is to read a small number of channels for debugging, for datasets
% that take a while to read.

want_chan_subset = true;


% Turn on and off various processing steps.

% Try to automatically label ephys channels as good/bad/floating/etc.
want_auto_channel_types = false;

% Process continuous data before segmenting.
want_monolithic = false;

% Compare and align Unity and TTL data and build trial definitions.
want_align_segment = true;

% Bring up the GUI data browser after processing.
want_browser = false;


% Optionally save data from various steps to disk.
% Optionally load previously-saved data instead of processing raw data.

want_save_data = true;
want_cache_autoclassify = true;
want_cache_monolithic = true;
want_cache_align_raw = true;
want_cache_align_done = true;



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


% Analog signal filtering.

% Use Thilo's comb-style DFT power filter instead of the time-domain one.
% This might introduce numerical noise in very long continuous data, but it's
% much faster than time-domain FIR filtering.
want_power_filter_thilo = true;

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


% File I/O.

% The number of channels to load into memory at one time, when loading.
% This takes up at least 1 GB per channel-hour.
memchans = 4;

% Patterns that various channel names match.
% See "ft_channelselection" for special names. Use "*" as a wildcard.
name_patterns_record = { 'Amp*', 'CH*' };
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
