function cfg = euFT_getFiltPowerCosineFit( powerfreq, modecount )

% function cfg = euFT_getFiltPowerCosineFit( powerfreq, modecount )
%
% This generates a Field Trip ft_preprocessing() configuration structure for
% power-line filtering in the frequency domain (DFT filter), using a cosine
% fit (subtracting the specified components).
%
% NOTE - This will work best for short trials. For longer trials, we may be
% able to pick up the fact that we're not exactly at the nominal frequency.
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

% This works using cosine fitting by default.


% Pad 5 seconds before and after the signal, to reduce wrap-around artifacts.
% NOTE - This may misbehave if the signal isn't de-trended! I don't know if
% Field Trip subtracts the trend before filtering or not.
% NOTE - FT will usually refuse to pad the signal, for long signals.

cfg.padding = 5;


% Add the frequencies to remove.

for midx = 1:modecount
  thisfreq = powerfreq * midx;
  cfg.dftfreq = [ cfg.dftfreq thisfreq ];
end


% Done.

end

%
% This is the end of the file.
