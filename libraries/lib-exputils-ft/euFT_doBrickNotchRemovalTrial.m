function newmatrix = ...
  euFT_doBrickNotchRemovalTrial( oldmatrix, samprate, notch_list, notch_bw )

% function newmatrix = ...
%   euFT_doBrickNotchRemovalTrial( oldmatrix, samprate, notch_list, notch_bw )
%
% This performs band-stop filtering in the frequency domain by squashing
% frequency components (a "brick wall" filter). This causes ringing near
% large disturbances (a top-hat in the frequency domain gives a sinc
% function impulse response).
%
% This is intended to operate on individual trial matrices from Field Trip
% data, but can be used with any Nchannels x Nsamples data.
%
% NOTE - This uses the LoopUtil brick-wall filter implementation.
%
% "oldmatrix" is a Nchans x Nsamples matrix to process.
% "samprate" is the sampling rate, in Hz.
% "notch_list" is a vector containing notch center frequencies to remove.
% "notch_bw" is the width of the notch. All notches have the same width.
%
% "newmatrix" is a copy of "oldmatrix" with channel waveforms filtered.


% Initialize output.
newmatrix = oldmatrix;


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


% Walk through the channels, performing filtering.

chancount = size(oldmatrix,1);

for cidx = 1:chancount
  thiswave = oldmatrix(cidx,:);
  thiswave = nlProc_filterBrickBandStop( thiswave, samprate, notch_corners );
  newmatrix(cidx,:) = thiswave;
end


% Done.

end


%
% This is the end of the file.
