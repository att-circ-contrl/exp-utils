function chanmap = euUtil_getOpenEphysChannelMap_v5( inputfolder )

% This was moved to euMeta_xx.

euUtil_warnDeprecated( 'euUtil_getOpenEphysChannelMap_v5', ...
  'Call euMeta_getOpenEphysChannelMap_v5().' );

chanmap = euMeta_getOpenEphysChannelMap_v5(inputfolder);

end

%
% This is the end of the file.
