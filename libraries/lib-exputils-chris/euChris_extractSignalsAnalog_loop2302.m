function casesignals = euChris_extractSignals_loop2302( ...
  oldcasesignals, expmeta, signalconfig, verbosity )

% function casesignals = euChris_extractSignals_loop2302( ...
%   oldcasesignals, expmeta, signalconfig, verbosity )
%
% This function reads saved analog signals associated with one experiment
% and computes derived signals.
%
% This function works with 'loop2302' type experiments.
%
% "oldcasesignals" is a structure containing some or all of the signals
%   described in CHRISSIGNALS.txt. New signals are added to this.
% "expmeta" is one of the metadata structures returned by
%   euChris_getChrisMetadata(), with the fields described in CHRISEXPMETA.txt
%   (including the "casemeta" additional field).
% "signalconfig" is a structure with the fields noted in SIGNALCONFIG.txt,
%   including the following:
%   - Trimming configuration.
%   - Notch filtering configuration.
%   - LFP band specification.
%   - Phase detection width for estimating ground-truth phase detection.
%   - Artifact suppression settings.
%   - Squash settings.
% "verbosity" is 'normal' or 'quiet'.
%
% "casesignals" is a copy of "oldcasesignals" with the following signals
%   added, per CHRISSIGNALS.txt:
%
%   "wb_time" and "wb_wave" are the wideband signal.
%   "lfp_time" and "lfp_wave" are the wide-cut LFP signal.
%   "band_time" and "band_wave" are the ideal (acausal) narrow-band signal.
%   "delayband_time" and "delayband_wave" are a version of the narrow-band
%     signal produced with a causal filter. This won't match TORTE's filter.
%
%   "canon_time", "canon_mag", "canon_phase", and "canon_rms" are derived
%     from the acausal band-pass signal. These are the time, analytic
%     magnitude and phase, and the acausal moving RMS average of the
%     magnitude, respectively.
%   "delayed_time", "delayed_mag", "delayed_phase", and "delayed_rms"
%     are derived from the delayed (causal) band-pass signal. These are the
%     time, analytic magnitude and phase, and delayed (causal) moving RMS
%     average of the magnitude, respectively.
%   "canon_magflag", "canon_phaseflag", "delayed_magflag", and
%     "delayed_phaseflag" are the magnitude excursion detection flag and
%     the phase target match flag derived from the acausal and delayed
%     (causal) signals described above.
%   "canon_magflag_edges", "canon_phaseflag_edges", "delayed_magflag_edges",
%     and "delayed_phaseflag_edges" are vectors holding timestamps of rising
%     edges of the corresponding magnitude detection flags and of the
%     delayed phase detection flag, and timestamps of the high pulse
%     midpoints of the acausal phase detection flag.
%
%   "torte_time", "torte_mag", and "torte_phase" are the recorded values
%     of the TNE Lab Phase Calculator plugin's estimates of instantaneous
%     magnitude and instantaneous phase.
%     NOTE - These signals are not guaranteed to exist!
%   "torte_wave" is a reconstruction of the narrow-band signal using
%     "torte_mag" and "torte_phase". This should look like "delayband_wave".


casesignals = oldcasesignals;

want_banners = ~strcmp(verbosity, 'quiet');


% Extract relevant metadata structures, for convenience.
expconfig = expmeta.expconfig;
cookedmeta = expmeta.cookedmeta;

% Package artifact configuration.
[ artmethod, artconfig ] = ...
  euChris_getArtifactConfigFromSignalConfig( signalconfig );

% Get squash configuration.
squashconfig = struct();
if isfield(signalconfig, 'squash_config')
  squashconfig = signalconfig.squash_config;
end



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
  % FIXME - Some artifact suppression methods won't work for monolithic
  % data!
  ftdata_wb = euHLev_readAndCleanSignals( ...
    filefirst, { label_wb }, ...
    signalconfig.head_tail_trim_fraction, ...
    artmethod, artconfig, squashconfig, ...
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

% First output is acausal, second output is causal.
[ rmsval scratch ] = ...
  nlProc_calcSmoothedRMS( casesignals.canon_mag, sample_tau );

casesignals.canon_rms = rmsval;
casesignals.canon_magflag = ...
  ( casesignals.canon_mag >= (cookedmeta.crossmagthresh * rmsval) );

pdetect_width_rad = signalconfig.canon_detect_phase_width_degrees * pi / 180;

% Acausal phase accept window is centered on zero error.
scratch = casesignals.canon_phase;
scratch = mod((scratch + pi - cookedmeta.crossphaseval), 2*pi) - pi;
casesignals.canon_phaseflag = (scratch <= (0.5 * pdetect_width_rad)) ...
  & (scratch >= (-0.5 * pdetect_width_rad));

% Magnitude detection time is the rising edge, but phase detection time is
% the _midpoint_ of the phase detector's pulse, since it's centered on zero.
[ rsamp fsamp bsamp hsamp lsamp ] = ...
  nlProc_getBooleanEdges(casesignals.canon_magflag);
casesignals.canon_magflag_edges = casesignals.canon_time(rsamp);
[ rsamp fsamp bsamp hsamp lsamp ] = ...
  nlProc_getBooleanEdges(casesignals.canon_phaseflag);
casesignals.canon_phaseflag_edges = casesignals.canon_time(hsamp);


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

% Causal phase accept window has one _edge_ at zero error.
scratch = casesignals.delayed_phase;
scratch = mod((scratch + pi - cookedmeta.crossphaseval), 2*pi) - pi;
casesignals.delayed_phaseflag = ...
  (scratch <= pdetect_width_rad) & (scratch >= 0);

% Magnitude and phase detection times are at the rising edge.
[ rsamp fsamp bsamp hsamp lsamp ] = ...
  nlProc_getBooleanEdges(casesignals.delayed_magflag);
casesignals.delayed_magflag_edges = casesignals.delayed_time(rsamp);
[ rsamp fsamp bsamp hsamp lsamp ] = ...
  nlProc_getBooleanEdges(casesignals.delayed_phaseflag);
casesignals.delayed_phaseflag_edges = casesignals.delayed_time(rsamp);


%
% Get the "what TORTE actually did" signals, if they exist.

label_mag = expconfig.chan_mag_ftlabel;
label_phase = expconfig.chan_phase_ftlabel;

have_torte = have_second & (~isempty(label_mag)) & (~isempty(label_phase));

if want_banners
  if have_torte
    disp('.. Reading TORTE tattle signals.');
  else
    disp('.. TORTE tattle signals weren''t saved.');
  end
end


ftdata_torte = struct([]);

if have_torte
  % These are derived signals. Don't use notch filtering or artifact
  % suppression.
  ftdata_torte = euHLev_readAndCleanSignals( ...
    filesecond, { label_mag, label_phase }, ...
    signalconfig.head_tail_trim_fraction, ...
    'none', struct(), struct(), [], NaN );

  casesignals.torte_time = ftdata_torte.time{1}(1,:);

  % Handle the "channels shuffled" case.
  idxmag = find(strcmp( label_mag, ftdata_torte.label ));
  idxphase = find(strcmp( label_phase, ftdata_torte.label ));

  % Bulletproofing - Catch failure to save these signals.
  have_torte_mag = ~isempty(idxmag);
  have_torte_phase = ~isempty(idxphase);

% FIXME - Diagnostics.
oldwarn = warning('on','all');

  if ~have_torte_mag
    warning( [ '### [euChris_extractSignals_loop2302]  ' ...
      'Can''t find signal "' label_mag '" (TORTE magnitude)!' ] );
  end
  if ~have_torte_phase
    warning( [ '### [euChris_extractSignals_loop2302]  ' ...
      'Can''t find signal "' label_phase '" (TORTE phase)!' ] );
  end

% FIXME - Diagnostics.
warning(oldwarn);

  if have_torte_mag
    casesignals.torte_mag = ftdata_torte.trial{1}(idxmag,:);
  end

  if have_torte_phase
    casesignals.torte_phase = ftdata_torte.trial{1}(idxphase,:);
    % This was in degrees; convert to radians (and re-wrap).
    casesignals.torte_phase = casesignals.torte_phase * pi / 180;
    casesignals.torte_phase = ...
      mod( casesignals.torte_phase + pi, 2*pi ) - pi;
  end

  if have_torte_mag && have_torte_phase
    scratch = casesignals.torte_mag .* exp(i * casesignals.torte_phase);
    % We only want the real component.
    casesignals.torte_wave = real(scratch);
  end
end



if want_banners
  disp('.. Finished reading analog signals.');
end



% Done.
end


%
% This is the end of the file.
