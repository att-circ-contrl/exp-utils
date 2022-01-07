function cfg = euFT_getFiltPowerTW( powerfreq, modecount )

% function cfg = euFT_getFiltPowerTW( powerfreq, modecount )
%
% This generates a Field Trip ft_preprocessing() configuration structure for
% power-line filtering, using Thilo's old configuration. For each mode,
% Thilo specified a comb of frequencies to get something close to a
% band-stop filter.
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


% Pad 5 seconds before and after the signal, to reduce wrap-around artifacts.
% NOTE - This may misbehave if the signal isn't de-trended! I don't know if
% Field Trip subtracts the trend before filtering or not.

cfg.padding = 5;


% Add the frequencies to remove.

% Thilo went from -0.2 Hz to +0.2 Hz in steps of 0.1 Hz.
combfreqs = -0.2:0.1:0.2;

for midx = 1:modecount
  thisfreq = powerfreq * midx;
  cfg.dftfreq = [ cfg.dftfreq (thisfreq + combfreqs) ];
end


% Done.

end

%
% This is the end of the file.
