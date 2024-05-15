function result = euInfo_helper_analyzeXCorr( ...
  wavedest, wavesrc, samprate, delaylist, params )

% function result = euInfo_helper_analyzeXCorr( ...
%   wavedest, wavesrc, samprate, delaylist, params )
%
% This is an analysis function, per TIMEWINLAGFUNCS.txt.
%
% This calculates cross-correlations between the supplied signals.
% If multiple trials are supplied, the trials are concatenated.
%
% "wavedest" and "wavesrc" are expected to contain real-valued waveform
%   data. These may be 1 x Nsamples vectors or Ntrials x Nsamples matrices.
% "params" contains the following fields:
%   "norm_method" is the normalization method to pass to "xcorr". This is
%   typically 'unbiased' (to normalize by sample count) or 'coeff' (to
%   normalize so that self-correlation is 1).


% Check for the empty case (querying result fields).

if isempty(wavedest) || isempty(wavesrc) || isempty(delaylist)
  result = struct( 'xcorr', [] );
  return;
end


% If we were passed matrices, turn them into vectors.

wavedest = reshape( wavedest, 1, [] );
wavesrc = reshape( wavesrc, 1, [] );


% NOTE - We have a list of lags to be tested, in samples.
% The "xcorr" function takes a maximum shift, not a list of shifts.

% This works fine with a delay of 0.
delaymax = max(abs(delaylist));
delaystested = (-delaymax):delaymax;

rvals = xcorr( wavedest, wavesrc, delaymax, params.norm_method );

resultmask = ismember(delaystested, delaylist);
rvals = rvals(resultmask);

result = struct();
result.xcorr = rvals;


% Done.
end


%
% This is the end of the file.
