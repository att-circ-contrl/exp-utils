function [ recontime reconchanwaves ] = euChris_reconstructOscCosine( ...
  wintime, winperiods, samprate, extendmethod, ...
  oscmag, oscfreq, oscphase, oscmean, oscramp )

% function [ recontime reconchanwaves ] = euChris_reconstructOscCosine( ...
%   wintime, winperiods, samprate, extendmethod, ...
%   oscmag, oscfreq, oscphase, oscmean, oscramp )
%
% This reconstructs per-channel cosine oscillations based on their detection
% parameters.
%
% This is mostly intended as a plotting aid.
%
% NOTE - Since there's only one time series (following Field Trip trial
% conventions), it's sized for the largest window (lowest frequency).
% Reconstructions past the requested number of periods may be extended or
% set to NaN, per "extendmethod".
%
% "wintime" is the timestamp of the middle of the reconstruction window.
% "winperiods" is the number of oscillation periods to reconstruct.
% "samprate" is the sampling rate for the reconstructed waves.
% "extendmethod" is 'extend' or 'crop', for windows larger than the desired
%   number of periods.
% "oscmag" is a Nchans x 1 vector with per-channel cosine magnitudes.
% "oscfreq" is a Nchans x 1 vector with per-channel cosine frequencies.
% "oscphase" is a Nchans x 1 vector with per-channel cosine phases at the
%   window midpoint.
% "oscmean" is a Nchans x 1 vector with per-channel DC offsets.
% "oscramp" (optional) is a Nchans x 1 vector with per-channel line-fit
%   slopes. If this is missing or [], a slope of 0 is used (no line fit).
%
% "recontime" is a 1 x Nsamples timestamp series.
% "reconchanwaves" is a Nchans x Nsamples set of reconstructed waveforms.


% Get our reconstruction window without the time offset, for now.
% Size this for the lowest detected frequency / largest window.

% This tolerates NaNs.
winrad = winperiods * 0.5 / min(oscfreq);

samprad = round( winrad * samprate );
samprad = max(1, samprad);
recontime = (-samprad):samprad;
recontime = recontime / samprate;
if ~iscolumn(recontime)
  recontime = transpose(recontime);
end


% If we don't have slope information, assume a slope of zero.
if ~exist('oscramp', 'var')
  oscramp = zeros(size(oscmean));
elseif isempty(oscramp)
  oscramp = zeros(size(oscmean));
end


% Render our reconstructed waves.

reconchanwaves = [];

for cidx = 1:length(oscmag)
  thismag = oscmag(cidx);
  thisfreq = oscfreq(cidx);
  thisphase = oscphase(cidx);
  thismean = oscmean(cidx);
  thisramp = oscramp(cidx);

  % The window midpoint has timestamp zero, so reconstruction is easy.
  thisbg = recontime * thisramp + thismean;
  thisrecon = ...
    thismag * cos(recontime * 2 * pi * thisfreq + thisphase) + thisbg;

  if strcmp(extendmethod, 'crop')
    % Crop to the desired time range.
    thiswinrad = winperiods * 0.5 / thisfreq;
    thismask = (recontime < (-thiswinrad)) | (recontime > thiswinrad);
    thisrecon(thismask) = NaN;
  end

  reconchanwaves(cidx,:) = thisrecon;
end


% Shift the reconstructed time window.

recontime = recontime + wintime;



% Done.
end


%
% This is the end of the file.
