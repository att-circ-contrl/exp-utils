function newdata = ...
  euAlign_alignByShiftAndPad( olddata, oldtimes, reftimes, padmethod )

% function newdata = ...
%   euAlign_alignByShiftAndPad( olddata, oldtimes, reftimes, padmethod )
%
% This function aligns and pads or crops a waveform to match a reference
% time series.
%
% NOTE - The time series are assumed to be uniformly sampled and have the
% same sampling rate.
%
% Waveform extents that do not overlap the reference time series are cropped,
% and the waveform is padded to span the entire reference time series if it
% doesn't already do so.
%
% "olddata" is a vector containing the waveform data to align/crop/pad.
% "oldtimes" is a vector containing the corrsponding time series.
% "reftimes" is a vector containing the desired target time series.
% "padmethod" is 'nan', 'copy', or 'zero', indicating what padded regions
%   are to be filled with. 'copy' duplicates the nearest "olddata" sample.
%
% "newdata" is a shifted cropped/padded version of "olddata" with sample
%   times corresponding to "reftimes".


% Get information about what we're doing.

oldcount = length(oldtimes);
refcount = length(reftimes);

oldstart = oldtimes(1);
oldend = oldtimes(oldcount);

refstart = reftimes(1);
refend = reftimes(refcount);

datastart = olddata(1);
dataend = olddata(oldcount);

samprate = (refcount - 1) / (refend - refstart);


% Initialize output.

newdata = NaN(size(reftimes));
if strcmp(padmethod, 'zero')
  newdata = zeros(size(reftimes));
end

want_copy = strcmp(padmethod, 'copy');


% Figure out what we're copying and what we're padding.

if oldstart < refstart
  copystartref = 1;
  copystartold = 1 + round( samprate * (refstart - oldstart) );
else
  copystartref = 1 + round( samprate * (oldstart - refstart) );
  copystartold = 1;
end

if oldend < refend
  copyendref = refcount - round( samprate * (refend - oldend) );
  copyendold = oldcount;
else
  copyendref = refcount;
  copyendold = oldcount - round( samprate * (oldend - refend) );
end


% Do the padding.
% We only need to do this if we're copying endpoint values; zero and NaN
% are already filled in.

if want_copy
  if copystartref > 1
    newdata(1:(copystartref-1)) = olddata(1);
  end

  if copyendref < refcount
    newdata((copyendref+1):refcount) = olddata(oldcount);
  end
end


% Copy the overlapping portion.

if copystartold <= copyendold
  newdata(copystartref:copyendref) = olddata(copystartold:copyendold);
end


% Done.
end


%
% This is the end of the file.
