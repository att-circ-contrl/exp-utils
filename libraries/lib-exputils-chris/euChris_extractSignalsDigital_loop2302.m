function casesignals = euChris_extractSignalsDigital_loop2302( ...
  oldcasesignals, expmeta, signalconfig, verbosity )

% function casesignals = euChris_extractSignalsDigital_loop2302( ...
%   oldcasesignals, expmeta, signalconfig, verbosity )
%
% This function reads saved digital signals associated with one experiment
% and computes derived signals.
%
% This function works with 'loop2302' type experiments.
%
% "oldcasesignals" is a structure containing some or all of the signals
%   described in CHRISSIGNALS.txt. New signals are added to this.
% "expmeta" is one of the metadata structures returned by
%   euChris_getChrisMetadata(), with the fields described in CHRISEXPMETA.txt
%   (including the "casemeta" additional field).
% "signalconfig" is a structure with the following fields, per
%   SIGNALCONFIG.txt:
%   "notch_freqs" is a vector of frequencies to notch filter (may be empty).
%   "notch_bandwidth" is the bandwidth of the notch filter.
%   "artifact_suppression_level" is 0 for normal suppression, positive for
%     more suppression, or NaN to disable suppression.
%   "head_tail_trim_fraction" is the relative amount to trim from the head
%     and tail of the data (as a fraction of the total length).
%   "lfp_band" [ min max ] is the broad-band LFP frequency range.
%   "canon_detect_phase_width_degrees" is the width of the response window
%     to use when estimating what the phase detector signal should look like.
% "verbosity" is 'normal' or 'quiet'.
%
% "casesignals" is a copy of "oldcasesignals" with the following signals
%   added, per CHRISSIGNALS.txt:
%
%   "XXX_ftevents", "XXX_wave", "XXX_time", and "XXX_edges" are stored for
%     each of several TTL signals.
%     NOTE - These signals are not guaranteed to exist!
%     "XXX_ftevents" holds a Field Trip event structure array for events
%       associated with this TTL signal, per ft_read_event().
%     "XXX_wave" is a logical vector holding time-series waveform data for
%       this TTL signal.
%     "XXX_time" is a vector holding waveform timestamp data for this signal.
%     "XXX_edges" is a vector holding timestamps of rising signal edges.
%     Signals saved (values of "XXX") are "loopback", "detectmag",
%     "detectphase", "detectrand", "trigphase", "trigrand", "trigpower",
%     "trigimmed", and "trigused" (a duplicate of one of the other "trig"
%     signals).


casesignals = oldcasesignals;

want_banners = ~strcmp(verbosity, 'quiet');


% Extract relevant metadata structures, for convenience.
expconfig = expmeta.expconfig;
cookedmeta = expmeta.cookedmeta;



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
    casesignals.loopback_time = event_wave_times;
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
    casesignals.detectmag_time = event_wave_times;
    casesignals.detectmag_edges = event_edges{1}.risetimes;
  end

  if ~isempty(event_edges{2}.risetimes)
    casesignals.detectphase_ftevents = event_ftdata{2};
    casesignals.detectphase_wave = event_waves{2};
    casesignals.detectphase_time = event_wave_times;
    casesignals.detectphase_edges = event_edges{2}.risetimes;
  end

  if ~isempty(event_edges{3}.risetimes)
    casesignals.detectrand_ftevents = event_ftdata{3};
    casesignals.detectrand_wave = event_waves{3};
    casesignals.detectrand_time = event_wave_times;
    casesignals.detectrand_edges = event_edges{3}.risetimes;
  end

  if ~isempty(event_edges{4}.risetimes)
    casesignals.trigphase_ftevents = event_ftdata{4};
    casesignals.trigphase_wave = event_waves{4};
    casesignals.trigphase_time = event_wave_times;
    casesignals.trigphase_edges = event_edges{4}.risetimes;
  end

  if ~isempty(event_edges{5}.risetimes)
    casesignals.trigrand_ftevents = event_ftdata{5};
    casesignals.trigrand_wave = event_waves{5};
    casesignals.trigrand_time = event_wave_times;
    casesignals.trigrand_edges = event_edges{5}.risetimes;
  end

  if ~isempty(event_edges{6}.risetimes)
    casesignals.trigpower_ftevents = event_ftdata{6};
    casesignals.trigpower_wave = event_waves{6};
    casesignals.trigpower_time = event_wave_times;
    casesignals.trigpower_edges = event_edges{6}.risetimes;
  end

  if ~isempty(event_edges{7}.risetimes)
    casesignals.trigimmed_ftevents = event_ftdata{7};
    casesignals.trigimmed_wave = event_waves{7};
    casesignals.trigimmed_time = event_wave_times;
    casesignals.trigimmed_edges = event_edges{7}.risetimes;
  end

  if ~isempty(event_edges{8}.risetimes)
    casesignals.trigused_ftevents = event_ftdata{8};
    casesignals.trigused_wave = event_waves{8};
    casesignals.trigused_time = event_wave_times;
    casesignals.trigused_edges = event_edges{8}.risetimes;
  end

end



if want_banners
  disp('.. Finished reading digital signals.');
end



% Done.
end


%
% This is the end of the file.
