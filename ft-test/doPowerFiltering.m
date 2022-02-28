function newsignal = ...
  doPowerFiltering( oldsignal, power_freq, power_modes, use_thilo_filter )

% function newsignal = ...
%   doPowerFiltering( oldsignal, power_freq, power_modes, use_thilo_filter )
%
% This calls Field Trip's processing functions to perform power line noise
% rejection on a wideband signal.
%
% "oldsignal" is the Field Trip data structure to process.
% "power_freq" is the nominal power frequency in Hz (50 or 60 Hz).
% "power_modes" is the number of frequency modes to remove (1 = fundamental,
%   2 = fundamental and first harmonic, etc).
% "use_thilo_filter" is 1 to use Thilo's DFT comb. This might introduce
%   numerical noise in very long continuous data but is much faster than
%   time-domain FIR filtering.
%
% "newsignal" is a Field Trip data structure containing the filtered signal.


filt_power = euFT_getFiltPowerFIR(power_freq, power_modes);
if use_thilo_filter
  filt_power = euFT_getFiltPowerTW(power_freq, power_modes);
end

filt_power.feedback = 'no';

newsignal = ft_preprocessing(filt_power, oldsignal);


% Done.

end


%
% This is the end of the file.
