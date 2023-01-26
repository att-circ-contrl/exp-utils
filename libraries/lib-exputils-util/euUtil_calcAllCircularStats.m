function [ cmean cvar lindev fwhmraw fwhmabove ] = ...
  euUtil_calcAllCircularStats( angleseries )

% function [ cmean cvar lindev fwhmraw fwhmabove ] = ...
%   euUtil_calcAllCircularStats( angleseries )
%
% This calculates circular statistics for an angle series using
% "nlProc_calcCircularStats", and also estimates the FWHM of the series
% using "bbCalc_estimateFWHM".
%
% "angleseries" is a vector containing angles in radians.
%
% "cmean" is the circular mean of the angle series.
% "cvar" is the circular variance of the angle series. Phase locking value
%   is (1 - cvar).
% "lindev" is the linear standard deviation of the angle series. For tightly
%   clustered angles, this can be more intuitive than circular variance.
% "fwhmraw" is the estimated full-width half-maximum of the angle distribution
%   measured relative to amplitude zero.
% "fwhmabove" is the estimated full-width half-maximum of the angle
%   distribution measured relative to the distribution's estimated "floor".


% Get circular statistics.
[ cmean cvar lindev ] = nlProc_calcCircularStats( angleseries );

% Get a zero-average distribution from -pi..pi.
angleseries = angleseries - cmean;
angleseries = mod( angleseries + pi, 2*pi ) - pi;

% Guess at the FWHM by black magic.
[ fwhmraw floorval fwhmabove ] = bbCalc_estimateFWHM( angleseries );


% Done.
end


%
% This is the end of the file.
