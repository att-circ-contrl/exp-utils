function [ dirs_opene dirs_intanrec dirs_intanstim dirs_use ] = ...
  euUtil_getExperimentFolders( topdir )

% This was moved to euMeta_xx.

disp('.. Deprecated function; call euMeta_getExperimentFolders().');

[ dirs_opene dirs_intanrec dirs_intanstim dirs_use ] = ...
  euMeta_getExperimentFolders(topdir);

end

%
% This is the end of the file.
