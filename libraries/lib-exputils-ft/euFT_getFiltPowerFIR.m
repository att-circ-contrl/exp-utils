function cfg = euFT_getFiltPowerFIR( powerfreq, modecount, samprate )

% function cfg = euFT_getFiltPowerFIR( powerfreq, modecount, samprate )
%
% This generates a Field Trip ft_preprocessing() configuration structure for
% power-line filtering, using the "bsfreq" option to get a time-domain
% multi-notch band-stop filter.
%
% NOTE - This is intended for long continuous data, where frequency-domain
% filtering might introduce numerical noise.
%
% NOTE - We're using the FIR implementation of this; the IIR implementation
% is unstable and FT flags it as such.
%
% FIXME - The FIR filter takes forever due to needing a very wide filter and
% Matlab doing convolution in the time domain. We also need to use the
% undocumented "bsfiltord" configuration option.
%
% "powerfreq" is the power-line frequency (typically 50 Hz or 60 Hz).
% "modecount" is the number of modes to include (1 = fundamental,
%   2 = fundamental plus first harmonic, etc).
% "samprate" is the sampling rate of the signal being filtered (needed to
%   calculate the number of points needed for the FIR).
%
% "cfg" is a Field Trip configuration structure for this filter.


% Set up a band-stop filter operating in the time domain.

cfg = struct();
cfg.bsfilter = 'yes';
% NOTE - We can't use a butterworth. The one Matlab designs is unstable,
% and FT notices this.
cfg.bsfilttype = 'fir';
cfg.bsfreq = [];


% Internal tuning parameters.

bandwidthnotch = 2.0;
% FIXME - Clamp bandwidth to a reasonable minimum fraction of the frequency.
bandwidth_minimum = 0.02;
% A FIR with a k value of 1 will be barely wide enough to have a notch.
% Higher gives a wider filter with better-defined notch walls.
fir_kfactor = 2;


% Pad 5 seconds before and after the signal, to reduce wrap-around artifacts.
% NOTE - This may misbehave if the signal isn't de-trended! I don't know if
% Field Trip subtracts the trend before filtering or not.
% NOTE - FT will usually refuse to pad the signal, for long signals.

cfg.padding = 5;


% Add the frequencies to remove.

bwmin = inf;

for midx = 1:modecount

  thisfreq = powerfreq * midx;
  thisbw = max(bandwidthnotch, thisfreq * bandwidth_minimum);

  % Keep track of the minimum bandwidth, so that we can specify FIR order.
  bwmin = min(bwmin, thisbw);

  cfg.bsfreq(midx,:) = ...
    [ (thisfreq - 0.5 * thisbw), (thisfreq + 0.5 * thisbw) ];

end


% Set the filter order manually.
% For a FIR, "order" is the number of points.

% It defaults to a quality factor of 3, which isn't useful for notch filters.
% We want at _least_ Q periods for a useful filter. More for a steep cutoff.

% Q = freq / bandwidth
% period = samprate / freq
%
% points = k * period * Q
% points = k * (samprate / freq) * (freq / bandwidth)
% points = k * samprate / bandwidth

cfg.bsfiltord = fir_kfactor * samprate / bwmin;


% Done.

end

%
% This is the end of the file.
