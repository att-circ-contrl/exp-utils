function durstring = euUtil_makePrettyTime(dursecs)

% function durstring = euUtil_makePrettyTime(dursecs)
%
% This formats a duration (in seconds) in a meaningful human-readable way.
% Examples would be "5.0 ms" or "5d12h".
%
% "dursecs" is a duration in seconds to format. This may be fractional.
%
% "durstring" is a character array containing a terse human-readable
%   summary of the duration.

euUtil_warnDeprecated( 'Call nlUtil_makePrettyTime().' );

% This was moved to the LoopUtil library.
durstring = nlUtil_makePrettyTime(dursecs);


% Done.

end


%
% This is the end of the file.
