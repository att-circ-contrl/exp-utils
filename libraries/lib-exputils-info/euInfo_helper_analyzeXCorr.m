function result = euInfo_helper_analyzeXCorr( ...
  wavefirst, wavesecond, samprate, delaylist, params )

% function result = euInfo_helper_analyzeXCorr( ...
%   wavefirst, wavesecond, samprate, delaylist, params )
%
% This is an analysis function, per TIMEWINLAGFUNCS.txt.
%
% This calculates cross-correlations between the supplied signals.
% If multiple trials are supplied, the trials are concatenated.
%
% "wavefirst" and "wavesecond" are expected to contain real-valued waveform
%   data.
% "params" is ignored.


% If we were passed matrices, turn them into vectors.

wavefirst = reshape( wavefirst, 1, [] );
wavesecond = reshape( wavesecond, 1, [] );


% NOTE - We have a list of lags to be tested, in samples.
% The "xcorr" function takes a maximum shift, not a list of shifts.

% This works fine with a delay of 0.
delaymax = max(abs(delaylist));
delaystested = (-delaymax):delaymax;

rvals = xcorr( wavefirst, wavesecond, delaymax, params.norm_method );

resultmask = ismember(delaystested, delaylist);
rvals = rvals(resultmask);

result = struct();
result.xcorr = rvals;


% Done.
end


%
% This is the end of the file.
