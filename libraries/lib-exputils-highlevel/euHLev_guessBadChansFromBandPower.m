function badchanmask = euHLev_guessBadChansFromBandPower( ...
  bandpower, tonepower, bandrange, tonerange )

% function badchanmask = euHLev_guessBadChansFromBandPower( ...
%   bandpower, tonepower, bandrange, tonerange )
%
% This z-scores the output of nlProc_getBandPower() across channels, and
% identifies outliers (presumed to be bad channels). Multiple iterations may
% be performed (removing extreme outliers and recomputing outlier thresholds).
%
% If more iterations are performed than there are rows in "bandrange" or
% "tonerange", the last row in the relevant matrix is duplicated as needed.
%
% "bandpower" is a nChans x nBands x nTrials matrix containing total in-band
%   power for each channel, band, and trial.
% "tonepower" is a nChans x nBands x nTrials matrix containing normalized
%   tone power (defined as the maximum in-band component power divided by
%   the median in-band component power).
% "bandrange" [ low high ; low high ; ... ] is the accepted range for in-band
%   power, in standard deviations. Anything outside this range is an outlier.
%   A value of NaN for a low or high threshold results in a default value
%   being used. The number of rows indicates the number of pruning passes to
%   be performed. An empty matrix [] is interpreted as [ NaN NaN ].
% "tonerange" [ low high ; low high ; ... ] is the accepted range for tone
%   power, in standard deviations. Anything outside this range is an outlier.
%   A value of NaN for a low or high threshold results in a default value
%   being used. The number of rows indicates the number of pruning passes to
%   be performed. An empty matrix [] is interpreted as [ NaN NaN ].
%
% "badchanmask" is a nChans x 1 boolean vector that's true for bad channels
%   and false otherwise.


%
% Magic values.

defaultbandrange = [ -2 inf ];
defaulttonerange = [ -inf 2 ];

% Number of bands that have to vote "bad" for a channel to be bad.
minbadcount = 2;

% 'zscore', 'median', or 'twosided'.
scoremethod = 'twosided';


%
% Fill in empty ranges if necessary.

if isempty(bandrange)
  bandrange = [ NaN NaN ];
end

if isempty(tonerange)
  tonerange = [ NaN NaN ];
end



%
% Get metadata.

chancount = size(bandpower,1);
bandcount = size(bandpower,2);

passcount = max( size(bandrange,1), size(tonerange,1) );


%
% Figure out how many observations are "bad" and build the "bad channel" mask.

% Collapse trials.
bandpower = mean(bandpower,3);
tonepower = mean(tonepower,3);


% Iteratively check for bad trials.

thisbandrange = defaultbandrange;
thistonerange = defaulttonerange;

badchanmask = false([ chancount, 1 ]);

for pidx = 1:passcount

  % Get this pass's thresholds, retaining the old ones if we're out of rows.
  if size(bandrange,1) >= pidx
    thisbandrange = bandrange(pidx,:);
  end
  if size(tonerange,1) >= pidx
    thistonerange = tonerange(pidx,:);
  end

  % Replace NaN with defaults.
  thisbandrange(isnan(thisbandrange)) = defaultbandrange(isnan(thisbandrange));
  thistonerange(isnan(thistonerange)) = defaulttonerange(isnan(thistonerange));


  % Get non-bad data and normalize.

  validmask = ~badchanmask;

  if any(validmask)

    % Get valid channels and z-score only across these.

    thisbandpower = bandpower(validmask,:,:);
    thistonepower = tonepower(validmask,:,:);

    normband = nlProc_normalizeAcrossChannels( thisbandpower, scoremethod );
    normtone = nlProc_normalizeAcrossChannels( thistonepower, scoremethod );


    % Get outliers.
    badband = ...
      (normband < min(thisbandrange)) | (normband > max(thisbandrange));
    badtone = ...
      (normtone < min(thistonerange)) | (normtone > max(thistonerange));

    % Collapse bands, to get per-channel outlier counts.
    thisbadmask = sum(badband,2) + sum(badtone,2);

    % Compare with the "bad observations" threshold to get the mask.
    thisbadmask = (thisbadmask >= minbadcount);


    % Update this subset of the global bad channel mask.
    badchanmask( find(validmask) ) = thisbadmask;
  end

end



% Done.
end


%
% This is the end of the file.
