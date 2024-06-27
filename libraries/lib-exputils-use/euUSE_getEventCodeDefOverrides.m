function defoverrides = euUSE_getEventCodeDefOverrides()

% function defoverrides = euUSE_getEventCodeDefOverrides()
%
% This function provides a default "hints" structure for parsing event code
% definitions. This is mostly used for changing the range of codes that have
% ranged values encoded.
%
% NOTE - This is entirely composed of magic values reflecting our current
% USE configuration, and will have to be manually edited if that changes.
%
% "defoverrides" is a structure suitable for passing to
%   euUSE_parseEventCodeDefs().


% Event code definition table overrides.
% These are mostly used for changing the range of encoded ranged values.

% FIXME - This is entirely composed of magic values reflecing our current
% USE configuration.


% NOTE - BlockData.txt and BlockDef.txt use the BlockCondition values
% produced here, but I'd made a note that some other files use the raw values
% I no longer remember where that came up.

% NOTE - Context "-1" (code 1899) is used as a "no context" code.
% We're special-casing that elsewhere rather than messing with the code
% range and offset here.

defoverrides = struct( ...
  'BlockCondition', struct('offset', 501), ...
  'Dimensionality', struct('offset', 200), ...
  'RewardValidity', struct('offset', 100), ...
  'TrialIndex', struct('offset', 4000), ...
  'TrialNumber', struct('offset', 12000), ...
  'TokensAdded', struct('offset', 70) );



% Done.

end


%
% This is the end of the file.
