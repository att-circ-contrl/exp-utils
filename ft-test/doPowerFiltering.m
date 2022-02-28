function newsignal = ...
  doPowerFiltering( oldsignal, power_freq, power_modes, filter_type )

% function newsignal = ...
%   doPowerFiltering( oldsignal, power_freq, power_modes, filter_type )
%
% This calls Field Trip's processing functions to perform power line noise
% rejection on a wideband signal.
%
% "oldsignal" is the Field Trip data structure to process.
% "power_freq" is the nominal power frequency in Hz (50 or 60 Hz).
% "power_modes" is the number of frequency modes to remove (1 = fundamental,
%   2 = fundamental and first harmonic, etc).
% "filter_type" is 'fir' to use the FIR filter (FIXME - Doesn't work),
%   'dft' to use a DFT band-stop filter (only usable with short signals;
%   time and memory go way up for longer), 'cosine' to use a DFT
%   filter that does cosine fitting (fast but does a poor job), 'dftkludge'
%   to use a hard-stop frequency domain filter (produces ringing), and
%   and 'thilo' to use Thilo's old filter setup (a comb of cosine-fit
%   filters; performance comparable to 'cosine' in my tests).
%
% "newsignal" is a Field Trip data structure containing the filtered signal.


% Special-case the kludge cases that bypass FT.
if strcmp('dftkludge', filter_type)

  % Kludge: Filter in the frequency domain by brute force and ignorance.
  notch_bw = 2.0;
  newsignal = ...
    euFT_doKludgeBandStop( oldsignal, power_freq, power_modes, notch_bw );

else
  % Use Field Trip to do the filtering.

  % Default to FIR, as it always works.
  filt_power = euFT_getFiltPowerFIR(power_freq, power_modes);

  % Check other cases.
  if strcmp('dft', filter_type)
    filt_power = euFT_getFiltPowerDFT(power_freq, power_modes);
  elseif strcmp('cosine', filter_type)
    filt_power = euFT_getFiltPowerCosineFit(power_freq, power_modes);
  elseif strcmp('thilo', filter_type)
    filt_power = euFT_getFiltPowerTW(power_freq, power_modes);
  end

  % Suppress progress reports.
  filt_power.feedback = 'no';

  % Call Field Trip's filtering routines.
  newsignal = ft_preprocessing(filt_power, oldsignal);
end


% Done.

end


%
% This is the end of the file.
