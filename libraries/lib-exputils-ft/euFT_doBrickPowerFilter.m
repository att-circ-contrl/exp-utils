function newdata = ...
  euFT_doBrickPowerFilter( olddata, notch_freq, notch_modes, notch_bw )

% function newdata = ...
%   euFT_doBrickPowerfilter( olddata, notch_freq, notch_modes, notch_bw )
%
% This performs band-stop filtering in the frequency domain by squashing
% frequency components (a "brick wall" filter). This causes ringing near
% large disturbances (a top-hat in the frequency domain gives a sinc
% function impulse response).
%
% NOTE - This uses the LoopUtil brick-wall filter implementation. To use
% Field Trip's implementation, call euFT_getFiltPowerBrick() to get a FT
% filter configuration structure.
%
% "olddata" is the FT data structure to process.
% "notch_freq" is the fundamental frequency of the family of notches.
% "notch_modes" is the number of frequency modes to remove (1 = fundamental,
%   2 = fundamental and first harmonic, etc).
% "notch_bw" is the width of the notch. Harmonics have the same width.
%
% "newdata" is a copy of "olddata" with trial data waveforms filtered.


% Wrap the notch filter function.

notch_list = (1:notch_modes) * notch_freq;

newdata = euFT_doBrickNotchRemoval( olddata, notch_list, notch_bw );


% Done.

end


%
% This is the end of the file.
