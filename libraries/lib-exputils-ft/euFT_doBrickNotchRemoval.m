function newdata = ...
  euFT_doBrickNotchRemoval( olddata, notch_list, notch_bw )

% function newdata = ...
%   euFT_doBrickNotchRemoval( olddata, notch_list, notch_bw )
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
% "notch_list" is a vector containing notch center frequencies to remove.
% "notch_bw" is the width of the notch. All notches have the same width.
%
% "newdata" is a copy of "olddata" with trial data waveforms filtered.


% Initialize output: Copy the old dataset.
% New elements are the same size as old, so initializing with a copy
% shouldn't cause memory problems.

newdata = olddata;


% Build a list of notches.

% FIXME - Clamp bandwidth to a reasonable minimum fraction of the frequency.
bandwidth_minimum = 0.02;
bw_list = max(notch_bw, notch_list * bandwidth_minimum);

low_corners = notch_list - 0.5 * bw_list;
high_corners = notch_list + 0.5 * bw_list;

notch_corners = {};
for nidx = 1:length(notch_list)
  notch_corners{nidx} = [ low_corners(nidx), high_corners(nidx) ];
end


% Walk through the trials and channels, performing filtering.

chancount = length(newdata.label);
trialcount = length(newdata.trial);
samprate = newdata.fsample;

for tidx = 1:trialcount
  thistrial = newdata.trial{tidx};

  for cidx = 1:chancount
    thiswave = thistrial(cidx,:);
    thiswave = nlProc_filterBrickBandStop( thiswave, samprate, notch_corners );
    thistrial(cidx,:) = thiswave;
  end

  newdata.trial{tidx} = thistrial;
end


% Done.

end


%
% This is the end of the file.
