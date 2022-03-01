function newdata = doSignalConditioning( olddata, ...
  power_freq, power_modes, filter_type, extra_notches )

% function newdata = doSignalConditioning( olddata, ...
%   power_freq, power_modes, filter_type, extra_notches )
%
% This de-trends the signal, applies a power line rejection filter, and
% optionally applies the same type of notch filter to suppress additional
% narrow-band noise spikes.
%
% "olddata" is the FT dataset to process.
% "power_freq" is the power line fundamental frequency.
% "power_modes" is the number of power line modes to filter ( 1 = fundamental,
%   2 = fundamental + first harmonic, etc.).
% "filter_type" is 'fir', 'dft', 'cosine, 'brickwall', or 'thilo', per
%   doPowerfiltering().
% "extra_notches" is a vector containing any additional frequencies to
%   filter. This may be empty.


% Copy the old dataset.
newdata = olddata;

% De-trend.
newdata = ft_preprocessing( ...
  struct( 'detrend', 'yes', 'feedback', 'no' ), ...
  newdata );

% Apply the power line filter.
newdata = doPowerFiltering( newdata, power_freq, power_modes, filter_type);

% Apply the power line filter again at various extra notch frequencies.
% Only do fundamental-mode filtering for this.
for fidx = 1:length(extra_notches)
  newdata = doPowerFiltering( newdata, extra_notches(fidx), 1, filter_type );
end


% Done.

end


%
% This is the end of the file.
