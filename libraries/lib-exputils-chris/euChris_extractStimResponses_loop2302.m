function responsedata = euChris_extractStimResponses_loop2302( ...
  casemeta, signalconfig, trig_window_ms, train_gap_ms, ...
  want_all, want_lfp, want_narrowband, verbosity )

% function responsedata = euChris_extractStimResponses_loop2302( ...
%   casemeta, signalconfig, trig_window_ms, train_gap_ms, ...
%   want_all, want_lfp, want_narrowband, verbosity )
%
% This function reads ephys data in segments centered around stimulation
% events.
%
% This function works with 'loop2302' type experiments.
%
% "casemeta" is one of the metadata structures returned by
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
% "trig_window_ms" [ start stop ] is the window around stimulation events
%   to save, in milliseconds. E.g. [ -100 300 ].
% "train_gap_ms" is a duration in milliseconds. Stimulation events with this
%   separation or less are considered to be part of a pulse train.
% "want_all" is true if all channels are to be read, false if only hint and
%   experiment-specified channels are to be read.
% "want_lfp" is true if the broad-band LFP is to be extracted.
% "want_narrowband" is true if the narrow-band LFP is to be extracted.
% "verbosity" is 'normal' or 'quiet'.
%
% "responsedata" is a structure containing the following fields, per
%   CHRISRESPONSE.txt:
%
%   "ftdata_wb" is a Field Trip data structure containing the wideband data.
%   "ftdata_lfp" is a Field Trip data structure with the broad-band LFP data.
%     This is only present if "want_lfp" was true.
%   "ftdata_band" is a Field Trip data structure with the narrow-band LFP
%     data. This is only present if "want_narrowband" was true.
%
%   "tortecidx" is the index of the TORTE input channel in ftdata_XXX.
%   "hintcidx" is a vector with indices of hint channels in ftdata_XXX.
%
%   "trialindices_by_trainpos" is a cell array. Each cell - the Nth cell -
%     is a vector containing the trial indices of all trials that were the
%     Nth event in an event train.
%
% FIXME - NYI.


responsedata = struct([]);


% FIXME - NYI.
% FIXME - Document signalconfig.
% FIXME - Maybe support getting MUA too? Or HPF? Call getDerivedSignals?
% We have a batched version of that too.


% Done.
end


%
% This is the end of the file.
