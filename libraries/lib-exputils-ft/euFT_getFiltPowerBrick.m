function cfg = euFT_getFiltPowerBrick( powerfreq, modecount )

% function cfg = euFT_getFiltPowerBrick( powerfreq, modecount )
%
% This generates a Field Trip ft_preprocessing() configuration structure for
% power-line filtering in the frequency domain using a "brick wall" filter
% (squashing unwanted frequency components). This causes ringing near large
% disturbances (a top-hat in the frequency domain gives a sinc function
% impulse response).
%
% FIXME - We're using the undocumented "brickwall" bsfilttype option to get
% this filter.
%
% FIXME - This doesn't seem to be working properly; it boosts amplitude
% and only slightly attenuates unwanted frequencies.
%
% "powerfreq" is the power-line frequency (typically 50 Hz or 60 Hz).
% "modecount" is the number of modes to include (1 = fundamental,
%   2 = fundamental plus first harmonic, etc).
%
% "cfg" is a Field Trip configuration structure for this filter.


% Set up a power-line filter using a brick-wall frequency-domain filter.

cfg = struct();
cfg.bsfilter = 'yes';
cfg.bsfilttype = 'brickwall';
cfg.bsfreq = [];

% Internal tuning parameters.

bandwidthnotch = 2.0;
% FIXME - Clamp bandwidth to a reasonable minimum fraction of the frequency.
bandwidth_minimum = 0.02;


% Pad 5 seconds before and after the signal, to reduce wrap-around artifacts.
% NOTE - This may misbehave if the signal isn't de-trended! I don't know if
% Field Trip subtracts the trend before filtering or not.
% NOTE - FT will usually refuse to pad the signal, for long signals.

cfg.padding = 5;


% Add the frequencies to remove.

for midx = 1:modecount
  thisfreq = powerfreq * midx;
  thisbw = max(bandwidthnotch, thisfreq * bandwidth_minimum);

  % FIXME - This wants frequencies listed highest first then lowest.
  cfg.bsfreq(midx,:) = ...
    [ (thisfreq - 0.5 * thisbw), (thisfreq + 0.5 * thisbw) ];
end


% Done.

end


%
% This is the end of the file.
