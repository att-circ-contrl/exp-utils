function [ summary details ] = ...
  euChris_summarizeSignalsPresent_loop2302( sigstruct )

% function [ summary details ] = ...
%   euChris_summarizeSignalsPresent_loop2302( sigstruct )
%
% This function generates a human-readable summary describing which signals
% are present or absent in a 'loop2302' extracted signals structure.
%
% "sigstruct" is a structure containing extracted signals, per
%   CHRISSIGNALS.txt.
%
% "summary" is a cell array containing character vectors holding lines of
%   text for a human-readable summary of which signals are present/absent.
% "details" is a cell array containing character vectors holding lines of
%   text for a detailed human-readable description of signals present/absent.


summary = {};
details = {};


% Just go by field names, without checking content length.
siglist = fieldnames(sigstruct);


% Wideband and filtered signals.

thisline = '  WBt: ';
thisline = helper_appendYN(thisline, ismember('wb_time', siglist));
thisline = [ thisline '  WBw: ' ];
thisline = helper_appendYN(thisline, ismember('wb_wave', siglist));
thisline = [ thisline '  LFPt: ' ];
thisline = helper_appendYN(thisline, ismember('lfp_time', siglist));
thisline = [ thisline '  LFPw: ' ];
thisline = helper_appendYN(thisline, ismember('lfp_wave', siglist));
thisline = [ thisline '  NBt: ' ];
thisline = helper_appendYN(thisline, ismember('band_time', siglist));
thisline = [ thisline '  NBw: ' ];
thisline = helper_appendYN(thisline, ismember('band_wave', siglist));
thisline = [ thisline '  DLt: ' ];
thisline = helper_appendYN(thisline, ismember('delayband_time', siglist));
thisline = [ thisline '  DLw: ' ];
thisline = helper_appendYN(thisline, ismember('delayband_wave', siglist));

details = [ details { thisline } ];

summaryline = '  Ephys: ';
summaryline = helper_appendYN(summaryline, ismember('wb_wave', siglist));


% Ideal (acausal) analytic signals and detection flags.

thisline = '  ACt: ';
thisline = helper_appendYN(thisline, ismember('canon_time', siglist));
thisline = [ thisline '  ACm: ' ];
thisline = helper_appendYN(thisline, ismember('canon_mag', siglist));
thisline = [ thisline '  ACp: ' ];
thisline = helper_appendYN(thisline, ismember('canon_phase', siglist));
thisline = [ thisline '  ACr: ' ];
thisline = helper_appendYN(thisline, ismember('canon_rms', siglist));

thisline = [ thisline '    ACFLm: ' ];
thisline = helper_appendYN(thisline, ismember('canon_magflag', siglist));
thisline = [ thisline '  ACFLp: ' ];
thisline = helper_appendYN(thisline, ismember('canon_phaseflag', siglist));

details = [ details { thisline } ];


% Simulated (causal) analytic signals and detection flags.

thisline = '  DLt: ';
thisline = helper_appendYN(thisline, ismember('delayed_time', siglist));
thisline = [ thisline '  DLm: ' ];
thisline = helper_appendYN(thisline, ismember('delayed_mag', siglist));
thisline = [ thisline '  DLp: ' ];
thisline = helper_appendYN(thisline, ismember('delayed_phase', siglist));
thisline = [ thisline '  DLr: ' ];
thisline = helper_appendYN(thisline, ismember('delayed_rms', siglist));

thisline = [ thisline '    DLFLm: ' ];
thisline = helper_appendYN(thisline, ismember('delayed_magflag', siglist));
thisline = [ thisline '  DLFLp: ' ];
thisline = helper_appendYN(thisline, ismember('delayed_phaseflag', siglist));

details = [ details { thisline } ];


% On-line estimated analytic signals and detection flags.

thisline = '  OEt: ';
thisline = helper_appendYN(thisline, ismember('torte_time', siglist));
thisline = [ thisline '  OEm: ' ];
thisline = helper_appendYN(thisline, ismember('torte_mag', siglist));
thisline = [ thisline '  OEp: ' ];
thisline = helper_appendYN(thisline, ismember('torte_phase', siglist));
% There is no "torte RMS" value. Saving that was one special-case test.
% Reconstructed wave from mag .* exp(i * phase).
thisline = [ thisline '  OEw: ' ];
thisline = helper_appendYN(thisline, ismember('torte_wave', siglist));

% FIXME - Assume that if XXX_edges exists for a TTL signal, the other
% TTL-associated signals for XXX also exist (don't check).

thisline = [ thisline '    DETm: ' ];
thisline = helper_appendYN(thisline, ismember('detectmag_edges', siglist));
thisline = [ thisline '  DETp: ' ];
thisline = helper_appendYN(thisline, ismember('detectphase_edges', siglist));
thisline = [ thisline '  DETr: ' ];
thisline = helper_appendYN(thisline, ismember('detectrand_edges', siglist));

details = [ details { thisline } ];

summaryline = [ summaryline '  TORTE: ' ];
summaryline = helper_appendYN(summaryline, ismember('torte_mag', siglist));
summaryline = [ summaryline '  Detect: ' ];
summaryline = ...
  helper_appendYN(summaryline, ismember('detectmag_edges', siglist));


% Generated triggers and loopback recording of the trigger.

thisline = '  TRph: ';
thisline = helper_appendYN(thisline, ismember('trigphase_edges', siglist));
thisline = [ thisline '  TRra: ' ];
thisline = helper_appendYN(thisline, ismember('trigrand_edges', siglist));
thisline = [ thisline '  TRpw: ' ];
thisline = helper_appendYN(thisline, ismember('trigpower_edges', siglist));
thisline = [ thisline '  TRim: ' ];
thisline = helper_appendYN(thisline, ismember('trigimmed_edges', siglist));

thisline = [ thisline '    TRused: ' ];
thisline = helper_appendYN(thisline, ismember('trigused_edges', siglist));

thisline = [ thisline '    TRloop: ' ];
thisline = helper_appendYN(thisline, ismember('loopback_edges', siglist));

details = [ details { thisline } ];

summaryline = [ summaryline '  Trig: ' ];
summaryline = ...
  helper_appendYN(summaryline, ismember('trigused_edges', siglist));
summaryline = [ summaryline '  Loopback: ' ];
summaryline = ...
  helper_appendYN(summaryline, ismember('loopback_edges', siglist));

summary = [ summary { summaryline } ];


% Done.
end


%
% Helper functions.

function newtext = helper_appendYN( oldtext, flagval )
  if flagval
    newtext = [ oldtext 'Y' ];
  else
    newtext = [ oldtext 'N' ];
  end
end


%
% This is the end of the file.
