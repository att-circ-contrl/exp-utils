function [ configfiles mapfiles ] = euUtil_getOpenEphysConfigFiles( topdir )

% This was moved to euMeta_xx.

euUtil_warnDeprecated( 'euUtil_getOpenEphysConfigFiles', ...
  'Call euMeta_getOpenEphysConfigFiles().' );

[ configfiles mapfiles ] = euMeta_getOpenEphysConfigFiles(topdir);

end

%
% This is the end of the file.
