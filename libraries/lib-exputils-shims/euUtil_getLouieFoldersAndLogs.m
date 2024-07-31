function sessionlist = ...
  euUtil_getLouieFoldersAndLogs( sessionfolders, logfilepatterns)

% This was moved to euMeta_xx.

euUtil_warnDeprecated( 'euUtil_getLouieFoldersAndLogs', ...
  'Call euMeta_getLouieFoldersAndLogs().' );

sessionlist = euMeta_getLouieFoldersAndLogs(sessionfolders, logfilepatterns);

end

%
% This is the end of the file.
