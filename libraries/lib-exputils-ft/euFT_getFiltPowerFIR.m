function cfg = euFT_getFiltPowerFIR( powerfreq, modecount )

% function cfg = euFT_getFiltPowerFIR( powerfreq, modecount )
%
% This generates a Field Trip ft_preprocessing() configuration structure for
% power-line filtering, using the "bsfreq" option to get a time-domain
% multi-notch band-stop filter.
%
% We're using the FIR implementation of this; the IIR implementation is
% unstable and FT flags it as such.
%
% NOTE - This is intended for long continuous data, where frequency-domain
% filtering might introduce numerical noise.
%
% "powerfreq" is the power-line frequency (typically 50 Hz or 60 Hz).
% "modecount" is the number of modes to include (1 = fundamental,
%   2 = fundamental plus first harmonic, etc).
%
% "cfg" is a Field Trip configuration structure for this filter.


% Set up a band-stop filter operating in the time domain.

cfg = struct();
cfg.bsfilter = 'yes';
% NOTE - We can't use a butterworth. The one Matlab designs is unstable,
% and FT notices this.
cfg.bsfilttype = 'fir';
cfg.bsfreq = [];


% Internal tuning parameter.
bandwidthnotch = 2.0;


% Pad 5 seconds before and after the signal, to reduce wrap-around artifacts.
% NOTE - This may misbehave if the signal isn't de-trended! I don't know if
% Field Trip subtracts the trend before filtering or not.
% NOTE - FT will usually refuse to pad the signal, for long signals.

cfg.padding = 5;


% Add the frequencies to remove.

for midx = 1:modecount
  thisfreq = powerfreq * midx;
  halfbw = 0.5 * bandwidthnotch;
  cfg.bsfreq(midx,:) = [ (thisfreq - halfbw), (thisfreq + halfbw) ];
end


% Done.

end

%
% This is the end of the file.
