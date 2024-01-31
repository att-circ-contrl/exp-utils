function sessionlist = ...
  euUtil_getLouieFoldersAndLogs( sessionfolders, logfilepatterns)

% This was moved to euMeta_xx.

disp('.. Deprecated function; call euMeta_getLouieFoldersAndLogs().');

sessionlist = euMeta_getLouieFoldersAndLogs(sessionfolders, logfilepatterns);

end

%
% This is the end of the file.
