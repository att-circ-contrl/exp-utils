function [ firstindices lastindices ] = ...
  euAlign_getSlidingWindowIndices( firsttimes, secondtimes, windowrad )

% This was moved to nlProc_xx.
euUtil_warnDeprecated( 'Call nlProc_getSlidingWindowIndices().' );

[ firstindices lastindices ] = ...
  nlProc_getSlidingWindowIndices( firsttimes, secondtimes, windowrad );


end

%
% This is the end of the file.
