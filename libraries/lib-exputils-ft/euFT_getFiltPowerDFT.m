function cfg = euFT_getFiltPowerDFT( powerfreq, modecount )

% function cfg = euFT_getFiltPowerDFT( powerfreq, modecount )
%
% This generates a Field Trip ft_preprocessing() configuration structure for
% power-line filtering in the frequency domain (DFT filter), using the
% "dftbandwidth" option to get a band-stop filter with known bandwidth.
%
% NOTE - This is for short signals only (segmented trials)! For anything
% longer than a few seconds, the type of filter this uses consumes a very
% large amount of memory.
%
% "powerfreq" is the power-line frequency (typically 50 Hz or 60 Hz).
% "modecount" is the number of modes to include (1 = fundamental,
%   2 = fundamental plus first harmonic, etc).
%
% "cfg" is a Field Trip configuration structure for this filter.


% Set up a power-line filter operating in the frequency domain.

cfg = struct();
cfg.dftfilter = 'yes';
cfg.dftfreq = [];

% If we want to specify bandwidths, we have to use the "neighbour" method.
cfg.dftreplace = 'neighbour';

% Field Trip defaults to a widening series of notch bandwidths and a fixed
% signal frequency bin bandwidth. We're using fixed for both.
bandwidthnotch = 2.0;
bandwidthsignal = 2.0;

% FIXME - Clamp bandwidth to a reasonable minimum fraction of the frequency.
bandwidth_minimum = 0.02;

cfg.dftbandwidth = [];
cfg.dftneighbourwidth = [];


% Pad 5 seconds before and after the signal, to reduce wrap-around artifacts.
% NOTE - This may misbehave if the signal isn't de-trended! I don't know if
% Field Trip subtracts the trend before filtering or not.
% NOTE - FT will usually refuse to pad the signal, for long signals.

cfg.padding = 5;


% Add the frequencies to remove.

for midx = 1:modecount
  thisfreq = powerfreq * midx;
  % FIXME - Make sure bandwidth isn't too narrow.
  thisbwnotch = max(bandwidthnotch, thisfreq * bandwidth_minimum);
  thisbwsignal = max(bandwidthsignal, thisfreq * bandwidth_minimum);

  cfg.dftfreq = [ cfg.dftfreq thisfreq ];
  cfg.dftbandwidth = [ cfg.dftbandwidth thisbwnotch ];
  cfg.dftneighbourwidth = [ cfg.dftneighbourwidth thisbwsignal ];
end


% Done.

end

%
% This is the end of the file.
