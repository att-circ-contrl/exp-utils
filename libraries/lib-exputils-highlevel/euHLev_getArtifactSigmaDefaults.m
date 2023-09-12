function paramstruct = euHLev_getArtifactSigmaDefaults( samprate )

% function paramstruct = euHLev_getArtifactSigmaDefaults( samprate )
%
% This function returns a structure containing reasonable default tuning
% parameters for nlArt_removeArtifactsSigma and nlFT_removeArtifactsSigma.
%
% "samprate" is either a sampling rate (to get durations in samples, for
%   nlArt_removeArtifactsSigma) or NaN (to get durations in milliseconds
%   or seconds, for nlFT_removeArtifactsSigma).
%
% "paramstruct" is a structure with the following fields:
%   "ampdetect" is the threshold for flagging amplitude excursions.
%   "derivdetect" is the threshold for flagging derivative excursions.
%   "ampturnoff" is the turn-off threshold for amplitude excursion detection.
%   "derivturnoff" is the turn-off threshold for derivative excursion
%     detection.
%   "squashbefore" is the added number of samples or milliseconds ahead of
%     the excursion to squash.
%   "squashafter" is the added number of samples or milliseconds after the
%     excursion to squash.
%   "derivsmooth" is the size of the derivative smoothing window in samples
%     or milliseconds.
%   "dcsmooth" is the size of the dc-level smoothing window in samples or
%     seconds.


% Mostly copied from the channel tool defaults.
% NOTE - This will flag spikes as excursions in some cases!

paramstruct = struct( ...
  'ampdetect', 6, 'ampturnoff', 3, ...
  'derivdetect', 8, 'derivturnoff', 3, ...
  'squashbefore', 100, 'squashafter', 100, ...
  'derivsmooth', 10, 'dcsmooth', 3 );


if ~isnan(samprate)
  paramstruct.squashbefore = ...
    round(paramstruct.squashbefore * samprate / 1000);
  paramstruct.squashafter = ...
    round(paramstruct.squashafter * samprate / 1000);
  paramstruct.derivsmooth = ...
    round(paramstruct.derivsmooth * samprate / 1000);
  paramstruct.dcsmooth = round(paramstruct.dcsmooth * samprate);
end


% Done.
end


%
% This is the end of the file.
