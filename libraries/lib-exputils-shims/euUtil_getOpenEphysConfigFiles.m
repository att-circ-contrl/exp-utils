function [ configfiles mapfiles ] = euUtil_getOpenEphysConfigFiles( topdir )

% This was moved to euMeta_xx.

disp('.. Deprecated function; call euMeta_getOpenEphysConfigFiles().');

[ configfiles mapfiles ] = euMeta_getOpenEphysconfigFiles(topdir);

end

%
% This is the end of the file.
