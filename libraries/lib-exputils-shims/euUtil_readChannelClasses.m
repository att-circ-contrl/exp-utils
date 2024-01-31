function [ channames, chanclasses ] = ...
  euUtil_readChannelClasses( fname, namecolumn, classcolumn )

% This was moved to euMeta_xx.

disp('.. Deprecated function; call euMeta_readChannelClasses().');

[ channames chanclasses ] = ...
  euMeta_readChannelClasses(fname, namecolumn, classcolumn);

end

%
% This is the end of the file.
