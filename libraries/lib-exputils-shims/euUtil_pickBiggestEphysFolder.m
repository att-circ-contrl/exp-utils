function [ foldername foldersizes ] = ...
  euUtil_pickBiggestEphysFolder( folderlist )

% This was moved to euMeta_xx.

euUtil_warnDeprecated( 'euUtil_pickBiggestEphysFolder', ...
  'Call euMeta_pickBiggestEphysFolder().' );

[ foldername foldersizes ] = euMeta_pickBiggestEphysFolder(folderlist);

end

%
% This is the end of the file.
