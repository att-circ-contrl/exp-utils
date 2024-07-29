function badchanmask = euHLev_guessBadChansFromBandPower( ...
  normband, normtone, bandrange, tonerange )

% function badchanmask = euHLev_guessBadChansFromBandPower( ...
%   normband, normtone, bandrange, tonerange )
%
% This processes the output of nlProc_getBandPower(), and decides which
% channels are good and which are bad.
%
% "normband" is a nChans x nBands x nTrials matrix containing normalized
%   total in-band power for each channel, band, and trial. This is expected
%   to be z-scored across channels (zero mean, standard deviation +/- 1).
% "normtone" is a nChans x nBands x nTrials matrix containing normalized
%   tone power (with tone power defined as the maximum in-band component
%   power divided by median in-band component power). This is expected to be
%   z-scored across channels (zero mean, standard deviation +/- 1).
% "bandrange" [ low high ] is the accepted range for in-band power. Specify []
%   to use defaults. Anything outside this range is considered bad. A value
%   of NaN for low or high thresholds results in a default value being used.
% "tonerange" [ low high ] is the accepted range for tone power. specify []
%   to use defaults. Anything outside this range is considered bad. A value
%   of NaN for low or high thresholds results in a default value being used.
%
% "badchanmask" is a 1 x nChans boolean vector that's true for bad channels
%   and false otherwise.


%
% Magic values.

defaultbandrange = [ -2 inf ];
defaulttonerange = [ -inf 2 ];

% Number of bands that have to vote "bad" for a channel to be bad.
minbadcount = 2;



%
% Set ranges to defaults if necessary.

if length(bandrange) ~= 2
  bandrange = [ NaN NaN ];
end

if length(tonerange) ~= 2
  tonerange = [ NaN NaN ];
end

bandrange(isnan(bandrange)) = defaultbandrange(isnan(bandrange));
tonerange(isnan(tonerange)) = defaulttonerange(isnan(tonerange));



%
% Get metadata.

chancount = size(normband,1);
bandcount = size(normband,2);



%
% Figure out how many observations are "bad" and build the "bad channel" mask.

% Collapse trials.
normband = mean(normband,3);
normtone = mean(normtone,3);

% Get bad observations.
badband = (normband < min(bandrange)) | (normband > max(bandrange));
badtone = (normtone < min(tonerange)) | (normtone > max(tonerange));

% Collapse bands, to get per-channel bad observation counts.
badchanmask = sum(badband,2) + sum(badtone,2);

% Compare with the "bad observations" threshold to get the mask.
badchanmask = (badchanmask >= minbadcount);



% Done.
end


%
% This is the end of the file.
