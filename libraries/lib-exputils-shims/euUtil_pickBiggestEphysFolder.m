function [ foldername foldersizes ] = ...
  euUtil_pickBiggestEphysfolder( folderlist )

% This was moved to euMeta_xx.

disp('.. Deprecated function; call euMeta_pickBiggestEphysFolder().');

[ foldername foldersizes ] = euMeta_pickBiggestEphysFolder(folderlist);

end

%
% This is the end of the file.
