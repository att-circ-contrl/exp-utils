function [ datalfp dataspike datarect ] = doFeatureFiltering( ...
  datawide, lfp_corner, lfp_rate, spike_corner, ...
  rect_band, rect_lowpass, rect_rate )

% function [ datalfp dataspike datarect ] = doFeatureFiltering( ...
%   datawide, lfp_corner, lfp_rate, spike_corner, ...
%   rect_band, rect_lowpass, rect_rate )
%
% This performs filtering to turn a wideband signal into an LFP signal
% (low-pass filtered and downsampled), a spike signal (high-pass filtered),
% and a rectified activity signal (band-pass filtered, rectified, low-pass
% filtered, and then downsampled).
%
% "datawide" is the wideband Field Trip data structure.
% "lfp_corner" is the low-pass corner frequency for the LFP signal.
% "lfp_rate" is the desired sampling rate of the LFP signal.
% "spike_corner" is the high-pass corner frequency for the spike signal.
% "rect_band" [low high] are the band-pass corners for the rectified signal.
% "rect_lowpass" is the low-pass smoothing corner for the rectified signal.
% "rect_rate" is the desired sampling rate of the rectified signal.
%
% "datalfp" is the LFP signal Field Trip data structure.
% "dataspike" is the spike signal Field Trip data structure.
% "datarect" is the rectified activity signal Field Trip data structure.


% Produce LFP signals.

filtconfig = ...
  struct( 'lpfilter', 'yes', 'lpfilttype', 'but', 'lpfreq', lfp_corner );
resampleconfig = struct( 'resamplefs', lfp_rate, 'detrend', 'no' );

filtconfig.feedback = 'no';
resampleconfig.feedback = 'no';

datalfp = ft_preprocessing(filtconfig, datawide);
datalfp = ft_resampledata(resampleconfig, datalfp);


% Produce spike signals.

filtconfig = struct( ...
  'hpfilter', 'yes', 'hpfilttype', 'but', 'hpfreq', spike_corner );

filtconfig.feedback = 'no';

dataspike = ft_preprocessing(filtconfig, datawide);


% Produce rectified activity signal.

filtconfigband = struct( 'bpfilter', 'yes', 'bpfilttype', 'but', ...
  'bpfreq', [ min(rect_band), max(rect_band) ] );
rectconfig = struct('rectify', 'yes');
filtconfiglow = struct( ...
  'lpfilter', 'yes', 'lpfilttype', 'but', 'lpfreq', rect_lowpass );
resampleconfig = struct( 'resamplefs', rect_rate, 'detrend', 'no' );

filtconfigband.feedback = 'no';
rectconfig.feedback = 'no';
filtconfiglow.feedback = 'no';
resampleconfig.feedback = 'no';


% FIXME - We can group some of these calls, but that requires detailed
% knowledge of the order in which FT applies preprocessing operations.
% Do them individually for safety's sake.

datarect = ft_preprocessing(filtconfigband, datawide);
datarect = ft_preprocessing(rectconfig, datarect);
datarect = ft_preprocessing(filtconfiglow, datarect);
datarect = ft_resampledata(resampleconfig, datarect);


% Done.

end


%
% This is the end of the file.
