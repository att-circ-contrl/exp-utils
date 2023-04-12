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
%   "canon_detect_phase_width_degrees" is the width of the response window
%     to use when estimating what the phase detector signal should look like.
% "verbosity" is 'normal' or 'quiet'.
%
% "casesignals" is a structure containing the following fields, per
%   CHRISSIGNALS.txt:
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
%
%   "XXX_ftevents", "XXX_wave", "XXX_times", and "XXX_edges" are stored for
%     each of several TTL signals.
%     NOTE - These signals are not guaranteed to exist!
%     "XXX_ftevents" holds a Field Trip event structure array for events
%       associated with this TTL signal, per ft_read_event().
%     "XXX_wave" is a logical vector holding time-series waveform data for
%       this TTL signal.
%     "XXX_times" is a vector holding sample timestamp data for this signal.
%     "XXX_edges" is a vector holding timestamps of rising signal edges.
%     Signals saved (values of "XXX") are "loopback", "detectmag",
%     "detectphase", "detectrand", "trigphase", "trigrand", "trigpower",
%     "trigimmed", and "trigused" (a duplicate of one of the other "trig"
%     signals).


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
  ftdata_wb = euHLev_readAndCleanSignals( ...
    filefirst, { label_wb }, ...
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
casesignals.canon_magflag_edges = caessignals.canon_time(rsamp);
[ rsamp fsamp bsamp hsamp lsamp ] = ...
  nlProc_getBooleanEdges(casesignals.canon_phaseflag);
casesignals.canon_phaseflag_edges = caessignals.canon_time(hsamp);


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
casesignals.delayed_magflag_edges = caessignals.delayed_time(rsamp);
[ rsamp fsamp bsamp hsamp lsamp ] = ...
  nlProc_getBooleanEdges(casesignals.delayed_phaseflag);
casesignals.delayed_phaseflag_edges = caessignals.delayed_time(rsamp);


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
    NaN, [], NaN );

  casesignals.torte_time = ftdata_torte.time{1}(1,:);

  % Handle the "channels shuffled" case.
  idxmag = find(strcmp( label_mag, ftdata_torte.label ));
  idxphase = find(strcmp( label_phase, ftdata_torte.label ));

  casesignals.torte_mag = ftdata_torte.trial{1}(idxmag,:);
  casesignals.torte_phase = ftdata_torte.trial{1}(idxphase,:);
end



%
% Get the digital signals.

% Loopback is in the first file; all others are in the second.
% Not all are guaranteed to be present.


if want_banners
  disp('.. Reading digital signals.');
end


% Make note of the signals that we want.

label_trigloop = expconfig.chan_ttl_loopback_trig_ftlabel;
have_loopback = have_first & (~isempty(label_trigloop));


label_detectmag = expconfig.chan_ttl_detect_mag_ftlabel;
label_detectphase = expconfig.chan_ttl_detect_phase_ftlabel;
label_detectrand = expconfig.chan_ttl_detect_rand_ftlabel;

have_detectmag = have_second & (~isempty(label_detectmag));
have_detectphase = have_second & (~isempty(label_detectphase));
have_detectrand = have_second & (~isempty(label_detectrand));


label_trigphase = expconfig.chan_ttl_trig_phase_ftlabel;
label_trigrand = expconfig.chan_ttl_trig_rand_ftlabel;
label_trigpower = expconfig.chan_ttl_trig_power_ftlabel;
label_trigimmed = expconfig.chan_ttl_trig_immed_ftlabel;
% This will be a duplicate of one of the others.
label_trigused = expconfig.chan_ttl_trig_selected_ftlabel;

have_trigphase = have_second & (~isempty(label_trigphase));
have_trigrand = have_second & (~isempty(label_trigrand));
have_trigpower = have_second & (~isempty(label_trigpower));
have_trigimmed = have_second & (~isempty(label_trigimmed));
% This will be a duplicate of one of the others.
have_trigused = have_second & (~isempty(label_trigused));


have_any_second_signals = ...
  have_detectmag || have_detectphase || have_detectrand ...
  || have_trigphase || have_trigrand || have_trigpower ...
  || have_trigimmed;



% Read the loopback signal, if we have it.

if have_loopback
  [ event_ftdata, event_waves, event_wave_times, event_edges ] = ...
    euHLev_readEvents( filefirst, { label_trigloop }, ...
    signalconfig.head_tail_trim_fraction );

  % Only store this if we found more than zero events.
  if ~isempty(event_edges{1}.risetimes)
    casesignals.loopback_ftevents = event_ftdata{1};
    casesignals.loopback_wave = event_waves{1};
    casesignals.loopback_times = event_wave_times;
    casesignals.loopback_edges = event_edges{1}.risetimes;
  end
end



% Read the other TTL signals, if we have them.
% We may only get non-empty results for a subset of them.

if have_any_second_signals

  % We get results in the same order that we asked for them.
  % Ask for the "used" signal too; there's no extra overhead for this.

  [ event_ftdata, event_waves, event_wave_times, event_edges ] = ...
    euHLev_readEvents( filesecond, ...
      { label_detectmag, label_detectphase, label_detectrand, ...
        label_trigphase, label_trigrand, label_trigpower, ...
        label_trigimmed, label_trigused }, ...
      signalconfig.head_tail_trim_fraction );

  % Only store a given signal if we found more than zero events for it.

  if ~isempty(event_edges{1}.risetimes)
    casesignals.detectmag_ftevents = event_ftdata{1};
    casesignals.detectmag_wave = event_waves{1};
    casesignals.detectmag_times = event_wave_times;
    casesignals.detectmag_edges = event_edges{1}.risetimes;
  end

  if ~isempty(event_edges{2}.risetimes)
    casesignals.detectphase_ftevents = event_ftdata{2};
    casesignals.detectphase_wave = event_waves{2};
    casesignals.detectphase_times = event_wave_times;
    casesignals.detectphase_edges = event_edges{2}.risetimes;
  end

  if ~isempty(event_edges{3}.risetimes)
    casesignals.detectrand_ftevents = event_ftdata{3};
    casesignals.detectrand_wave = event_waves{3};
    casesignals.detectrand_times = event_wave_times;
    casesignals.detectrand_edges = event_edges{3}.risetimes;
  end

  if ~isempty(event_edges{4}.risetimes)
    casesignals.trigphase_ftevents = event_ftdata{4};
    casesignals.trigphase_wave = event_waves{4};
    casesignals.trigphase_times = event_wave_times;
    casesignals.trigphase_edges = event_edges{4}.risetimes;
  end

  if ~isempty(event_edges{5}.risetimes)
    casesignals.trigrand_ftevents = event_ftdata{5};
    casesignals.trigrand_wave = event_waves{5};
    casesignals.trigrand_times = event_wave_times;
    casesignals.trigrand_edges = event_edges{5}.risetimes;
  end

  if ~isempty(event_edges{6}.risetimes)
    casesignals.trigpower_ftevents = event_ftdata{6};
    casesignals.trigpower_wave = event_waves{6};
    casesignals.trigpower_times = event_wave_times;
    casesignals.trigpower_edges = event_edges{6}.risetimes;
  end

  if ~isempty(event_edges{7}.risetimes)
    casesignals.trigimmed_ftevents = event_ftdata{7};
    casesignals.trigimmed_wave = event_waves{7};
    casesignals.trigimmed_times = event_wave_times;
    casesignals.trigimmed_edges = event_edges{7}.risetimes;
  end

  if ~isempty(event_edges{8}.risetimes)
    casesignals.trigused_ftevents = event_ftdata{8};
    casesignals.trigused_wave = event_waves{8};
    casesignals.trigused_times = event_wave_times;
    casesignals.trigused_edges = event_edges{8}.risetimes;
  end

end



if want_banners
  disp('.. Finished reading signals.');
end



% Done.
end


%
% This is the end of the file.
