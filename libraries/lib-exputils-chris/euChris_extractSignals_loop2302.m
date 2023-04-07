function casesignals = ...
  euChris_extractSignals_loop2302( casemeta, signalconfig, verbosity )

% function casesignals = ...
%   euChris_extractSignals_loop2302( casemeta, signalconfig, verbosity )
%
% This function reads saved signals associated with one experiment and
% computes derived signals.
%
% This function works with 'loop2302' type experiments.
%
% "casemeta" is one of the metadata structures returned by
%   euChris_getChrisMetadata(), with the fields described in CHRISEXPMETA.txt
%   (including the "casemeta" additional field).
% "signalconfig" is a structure with the following fields:
%   "notch_freqs" is a vector of frequencies to notch filter (may be empty).
%   "notch_bandwidth" is the bandwidth of the notch filter.
%   "artifact_suppression_level" is 0 for normal suppression, positive for
%     more suppression, or NaN to disable suppression.
%   "head_tail_trim_fraction" is the relative amount to trim from the head
%     and tail of the data (as a fraction of the total length).
%   "lfp_band" is the broad-band LFP frequency range.
% "verbosity" is 'normal' or 'quiet'.
%
% "casesignals" is a structure containing the following fields:
%
%   "wb_time" and "wb_wave" are the wideband signal.
%   "lfp_time" and "lfp_wave" are the wide-cut LFP signal.
%   "band_time" and "band_wave" are the ideal (acausal) narrow-band signal.
%   "delayband_time" and "delayband_wave" are a version of the narrow-band
%     signal produced with a causal filter. This won't match TORTE's filter.
%
%   "canon_time", "canon_mag", "canon_phase", "canon_rms", and "canon_magflag"
%     are derived from the acausal band-pass signal. These are the time,
%     analytic magnitude and phase, acausal moving RMS average of the
%     magnitude, and magnitude excursion detection flag, respectively.
%   "delayed_time", "delayed_mag", "delayed_phase", "delayed_rms", and
%     "delayed_magflag" are derived from the delayed (causal) band-pass
%     signal. These are the time, analytic magnitude and phase, delayed
%     (causal) moving RMS average of the magnitude, and magnitude excursion
%     detection flag, respectively.


casesignals = struct();

want_banners = ~strcmp(verbosity, 'quiet');


% Extract relevant metadata structures, for convenience.
expconfig = casemeta.expconfig;
cookedmeta = casemeta.cookedmeta;



%
% Prepare for reading.

% The reading function tolerates empty signal names and gives empty output
% if _no_ signals were read.


% The first file has the wideband signal and loopback TTL signal.
% The second file has everything else.

filefirst = expconfig.file_path_first;
filesecond = expconfig.file_path_second;

have_first = ~isempty(filefirst);
have_second = ~isempty(filesecond);



%
% Read the wideband signal.

% Wideband is supposed to always exist.

if want_banners
  disp('.. Reading wideband data.');
end

label_wb = expconfig.chan_wb_ftlabel;
have_wb = have_first & (~isempty(label_wb));

ftdata_wb = struct([]);

if have_wb
  [ ftdata_wb, scratch ] = euHLev_readAndCleanSignals( ...
    filefirst, { label_wb }, {}, ...
    signalconfig.head_tail_trim_fraction, ...
    signalconfig.artifact_suppression_level, ...
    signalconfig.notch_freqs, signalconfig.notch_bandwidth );
end

if isempty(ftdata_wb)
  % Bail out here.
  error('### [euChris_extractSignals_loop2302]  No wideband data!');
end

casesignals.wb_time = ftdata_wb.time{1}(1,:);
casesignals.wb_wave = ftdata_wb.trial{1}(1,:);



%
% Get the wide-cut LFP and narrow-cut band-pass signals.
% Include causal and acausal versions of the narrow-cut signal.

if want_banners
  disp('.. Getting ground truth band-pass signals.');
end

config_filt = struct( ...
  'bpfilter', 'yes', 'bpfilttype', 'but', 'bpinstabilityfix', 'split', ...
  'bpfreq', signalconfig.lfp_band, ...
  'feedback', 'no' );

ftdata_lfp = ft_preprocessing( config_filt, ftdata_wb );

config_filt.bpfreq = cookedmeta.torteband;

ftdata_band = ft_preprocessing( config_filt, ftdata_wb );

config_filt.bpfiltdir = 'onepass';

ftdata_delayband = ft_preprocessing( config_filt, ftdata_wb );


% Store all of these.

casesignals.lfp_time = ftdata_lfp.time{1}(1,:);
casesignals.lfp_wave = ftdata_lfp.trial{1}(1,:);
casesignals.band_time = ftdata_band.time{1}(1,:);
casesignals.band_wave = ftdata_band.trial{1}(1,:);
casesignals.delayband_time = ftdata_delayband.time{1}(1,:);
casesignals.delayband_wave = ftdata_delayband.trial{1}(1,:);



%
% Get the "what TORTE should have done" signals.

if want_banners
  disp('.. Getting ground truth detection signals.');
end

sample_tau = cookedmeta.crossmagtau * cookedmeta.samprate;


% Ideal (acausal).

casesignals.canon_time = casesignals.band_time;
scratch = hilbert(casesignals.band_wave);
casesignals.canon_mag = abs(scratch);
casesignals.canon_phase = angle(scratch);

% First otuput is acausal, second output is causal.
[ rmsval scratch ] = ...
  nlProc_calcSmoothedRMS( casesignals.canon_mag, sample_tau );

casesignals.canon_rms = rmsval;
casesignals.canon_magflag = ...
  ( casesignals.canon_mag >= (cookedmeta.crossmagthresh * rmsval) );


% Delayed (causal).

casesignals.delayed_time = casesignals.delayband_time;
scratch = hilbert(casesignals.delayband_wave);
casesignals.delayed_mag = abs(scratch);
casesignals.delayed_phase = angle(scratch);

% First otuput is acausal, second output is causal.
[ scratch rmsval ] = ...
  nlProc_calcSmoothedRMS( casesignals.delayed_mag, sample_tau );

casesignals.delayed_rms = rmsval;
casesignals.delayed_magflag = ...
  ( casesignals.delayed_mag >= (cookedmeta.crossmagthresh * rmsval) );


% FIXME - NYI. Stopped here. Need to read TORTE and read digital signals.


% Done.
end


%
% This is the end of the file.
