function cfg = euFT_getFiltPowerShort( powerfreq, modecount )

% function cfg = euFT_getFiltPowerShort( powerfreq, modecount )
%
% This generates a Field Trip ft_preprocessing() configuration structure for
% power-line filtering, using the "dftbandwidth" option to get a band-stop
% filter.
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

cfg.dftbandwidth = [];
cfg.dftneighbourwidth = [];


% Pad 5 seconds before and after the signal, to reduce wrap-around artifacts.
% NOTE - This may misbehave if the signal isn't de-trended! I don't know if
% Field Trip subtracts the trend before filtering or not.

cfg.padding = 5;


% Add the frequencies to remove.

for midx = 1:modecount
  thisfreq = powerfreq * midx;
  cfg.dftfreq = [ cfg.dftfreq thisfreq ];
  cfg.dftbandwidth = [ cfg.dftbandwidth bandwidthnotch ];
  cfg.dftneighbourwidth = [ cfg.dftneighbourwidth bandwidthsignal ];
end


% Done.

end

%
% This is the end of the file.