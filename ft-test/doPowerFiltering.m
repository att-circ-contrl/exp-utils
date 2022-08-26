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
% "filter_type" is 'fir' to use the FIR filter (FIXME - takes forever),
%   'dft' to use a DFT band-stop filter (only usable with short signals;
%   time and memory go way up for longer), 'cosine' to use a DFT
%   filter that does cosine fitting (fast but does a poor job), 'brickwall'
%   to use a hard-stop frequency domain filter (produces ringing), and
%   and 'thilo' to use Thilo's old filter setup (a comb of cosine-fit
%   filters; performance comparable to 'cosine' in my tests).
%
% "newsignal" is a Field Trip data structure containing the filtered signal.


% Switch for using LoopUtil implementations rather than FT.
want_looputil_brick = true;

% Special-case filters that bypass FT.
if want_looputil_brick && strcmp('brickwall', filter_type)
  % Brick-wall frequency-domain filter.
  notch_bw = 2.0;
  newsignal = ...
    euFT_doBrickPowerFilter( oldsignal, power_freq, power_modes, notch_bw );
else
  % Use Field Trip to do the filtering.

  % Check other cases.
  if strcmp('fir', filter_type)
    % FIXME - This takes a really impractical amount of time.
    filt_power = ...
      euFT_getFiltPowerFIR(power_freq, power_modes, oldsignal.fsample);
  elseif strcmp('dft', filter_type)
    % NOTE - This takes a long time.
    filt_power = euFT_getFiltPowerDFT(power_freq, power_modes);
  elseif strcmp('cosine', filter_type)
    % NOTE - This works poorly.
    filt_power = euFT_getFiltPowerCosineFit(power_freq, power_modes);
  elseif strcmp('brickwall', filter_type)
    % FIXME - This doesn't work properly! Use the LoopUtil version instead.
    filt_power = euFT_getFiltPowerBrick(power_freq, power_modes);
  elseif strcmp('thilo', filter_type)
    % NOTE - This works poorly (it's a comb of 'cosine' filters).
    filt_power = euFT_getFiltPowerTW(power_freq, power_modes);
  else
    error([ 'Unknown filter type "' filter_type '".' ]);
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
