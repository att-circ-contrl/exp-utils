function [ dirs_opene dirs_intanrec dirs_intanstim dirs_use ] = ...
  euUtil_getExperimentFolders( topdir )

% function [ dirs_opene dirs_intanrec dirs_intanstim dirs_use ] = ...
%   euUtil_getExperimentFolders( topdir )
%
% This function searches a directory tree, looking for subfolders containing
% Open Ephys data (structure.oebin), Intan data (info.rhs/info.rhd), and
% USE data (RuntimeData folder).
%
% "topdir" is the folder to search. This may contain wildcards.
%
% "dirs_opene" is a cell array containing paths to Open Ephys folders.
% "dirs_intanrec" is a cell array containing paths to Intan recorder folders.
% "dirs_intanstim" is a cell array with paths to Intan stimulator folders.
% "dirs_use" is a cell array with paths to USE "RuntimeData" folders.


% Initialize.

dirs_opene = {};
dirs_intanrec = {};
dirs_intanstim = {};
dirs_use = {};


% Search the tree.

% FIXME - We can't use "isdir" if "topdir" is a wildcard expression.
%if isdir(topdir)
  [ scratch dirs_opene ] = nlIO_searchForFile(topdir, 'structure.oebin');
  [ scratch dirs_intanrec ] = nlIO_searchForFile(topdir, 'info.rhd');
  [ scratch dirs_intanstim ] = nlIO_searchForFile(topdir, 'info.rhs');

  dirs_use = nlIO_searchForDir(topdir, 'RuntimeData');
%end


% Done.

end


%
% This is the end of the file.
