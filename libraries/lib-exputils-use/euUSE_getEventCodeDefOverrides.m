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

% NOTE - BlockCondition is 501..599. Leave it that way; it appears in other
% data files as-is, so changing it here would cause discrepancies.

defoverrides = struct( ...
  'Dimensionality', struct('offset', 200), ...
  'RewardValidity', struct('offset', 100), ...
  'TrialIndex', struct('offset', 4000), ...
  'TrialNumber', struct('offset', 12000), ...
  'TokensAdded', struct('offset', 70) );



% Done.

end


%
% This is the end of the file.
