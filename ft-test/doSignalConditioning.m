function newdata = doSignalConditioning( olddata, ...
  power_freq, power_modes, extra_notches )

% function newdata = doSignalConditioning( olddata, ...
%   power_freq, power_modes, extra_notches )
%
% This de-trends the signal, applies a power line rejection filter, and
% optionally applies a notch filter to suppress additional narrow-band noise
% peaks.
%
% This uses brick-wall filtering, as that was the only variant that gave
% reasonable results with reasonable time and memory use.
%
% "olddata" is the FT dataset to process.
% "power_freq" is the power line fundamental frequency.
% "power_modes" is the number of power line modes to filter ( 1 = fundamental,
%   2 = fundamental + first harmonic, etc.).
% "extra_notches" is a vector containing any additional frequencies to
%   filter. This may be empty.


% Copy the old dataset.
newdata = olddata;


% De-trend.
newdata = ft_preprocessing( ...
  struct( 'detrend', 'yes', 'feedback', 'no' ), ...
  newdata );


% Apply the power line filter.
% NOTE - Brick-wall filter gave the best results, and FT's implementation of
% that was buggy as of 2021.

notch_bandwidth = 2.0;
newdata = ...
  euFT_doBrickPowerFilter( newdata, power_freq, power_modes, notch_bandwidth );


% Apply a notch filter at manually-specified additional frequencies.

if ~isempty(extra_notches)
  newdata = ...
    euFT_doBrickNotchRemoval( newdata, extra_notches, notch_bandwidth );
end


% Done.

end


%
% This is the end of the file.
