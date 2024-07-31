function [ maplabelsraw maplabelscooked ] = ...
  euUtil_getLabelChannelMap_OEv5( mapdir, datadir )

% This was moved to euMeta_xx.

euUtil_warnDeprecated( 'euUtil_getLabelChannelMap_OEv5', ...
  'Call euMeta_getLabelChannelMap_OEv5().' );

[ maplabelsraw maplabelscooked ] = ...
  euMeta_getLabelChannelMap_OEv5(mapdir, datadir);

end

%
% This is the end of the file.
