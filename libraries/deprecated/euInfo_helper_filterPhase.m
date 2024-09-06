function acceptflag = euInfo_helper_filterPhase( ...
  wavedest, wavesrc, samprate, params )

% function acceptflag = euInfo_helper_filterNone( ...
%   wavedest, wavesrc, samprate, params )
%
% This is an acceptance filter function, per TIMEWINLAGFUNCS.txt.
%
% This passes signal pairs that have sufficient phase locking and that
% have a (dest - src) phase difference within a specified range.
%
% "wavedest" and "wavesrc" are expected to contain phase angle data in
%   radians (preprocessing mode 'angle').
% "params" contains phase acceptance parameters per PHASEFILTPARAMS.txt.


% Get acceptance parameters.

phasetargetrad = params.phasetargetdeg * pi / 180;
accepthalfwidthrad = 0.5 * params.acceptwidthdeg * pi / 180;
minplv = params.minplv;


% Get phase locking and phase difference.

[ cmean cvar lindev ] = nlProc_calcCircularStats( wavedest - wavesrc );
plv = 1 - cvar;

phasediff = cmean - phasetargetrad;
phasediff = mod( phasediff + pi, 2*pi ) - pi;


% Decide whether this signal pair passes or not.

acceptflag = ( abs(phasediff) <= accepthalfwidthrad ) & ( plv >= minplv );


% Done.
end


%
% This is the end of the file.
