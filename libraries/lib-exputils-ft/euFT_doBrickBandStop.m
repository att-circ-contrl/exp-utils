function newdata = ...
  euFT_doBrickBandStop( olddata, notch_freq, notch_modes, notch_bw )

% function newdata = ...
%   euFT_doBrickBandStop( olddata, notch_freq, notch_modes, notch_bw )
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


% Initialize output: Copy the old dataset.
% New elements are the same size as old, so initializing with a copy
% shouldn't cause memory problems.

newdata = olddata;


% FIXME - Clamp bandwidth to a reasonable minimum fraction of the frequency.
bandwidth_minimum = 0.02;


% Build a list of notches.

notch_list = {};
for nidx = 1:notch_modes
  this_freq = notch_freq * nidx;
  % FIXME - Make sure bandwidth isn't too narrow.
  this_bw = max(notch_bw, this_freq * bandwidth_minimum);

  notch_list{nidx} = ...
    [ (this_freq - 0.5 * this_bw), (this_freq + 0.5 * this_bw) ];
end


% Walk through the trials and channels, performing filtering.

chancount = length(newdata.label);
trialcount = length(newdata.trial);
samprate = newdata.fsample;

for tidx = 1:trialcount
  thistrial = newdata.trial{tidx};

  for cidx = 1:chancount
    thiswave = thistrial(cidx,:);
    thiswave = nlProc_filterBrickBandStop( thiswave, samprate, notch_list );
    thistrial(cidx,:) = thiswave;
  end

  newdata.trial{tidx} = thistrial;
end


% Done.

end


%
% This is the end of the file.
