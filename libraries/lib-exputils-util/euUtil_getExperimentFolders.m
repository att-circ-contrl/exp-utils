function [ dirs_opene dirs_intanrec dirs_intanstim dirs_use ] = ...
  euUtil_getExperimentFolders( topdir )

% function [ dirs_opene dirs_intanrec dirs_intanstim dirs_use ] = ...
%   euUtil_getExperimentFolders( topdir )
%
% This function searches a directory tree, looking for subfolders containing
% Open Ephys data (structure.oebin), Intan data (info.rhs/info.rhd), and
% USE data (RuntimeData folder).
%
% "topdir" is the folder to search.
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

if isdir(topdir)
  dirs_opene = helper_searchForFile(topdir, 'structure.oebin');
  dirs_intanrec = helper_searchForFile(topdir, 'info.rhd');
  dirs_intanstim = helper_searchForFile(topdir, 'info.rhs');

  dirs_use = helper_searchForDir(topdir, 'RuntimeData');
end


% Done.

end


%
% Helper Functions


% This looks for a file and returns a path, without the target file's name.

function dirs_found = helper_searchForFile( startdir, targetname )

  dirs_found = {};

  dirlist = dir([ startdir filesep '**' filesep targetname ]);

  for didx = 1:length(dirlist)
    thisentry = dirlist(didx);
    thisfile = thisentry.folder;
    dirs_found = [ dirs_found {thisfile} ];
  end

end


% This looks for a folder and returns a path, including the target folder.

function dirs_found = helper_searchForDir( startdir, targetname )

  dirs_found = {};

  % NOTE - This only lists the _contents_ of the target, not the target
  % itself. So, we'll get one or more entries with the target as the path,
  % for each matching target.

  dirlist = dir([ startdir filesep '**' filesep targetname ]);

  % Everything in the array should be a valid match.
  if ~isempty(dirlist)
    dirs_found = [ dirs_found { dirlist.folder } ];
  end

  % Reduce to only one entry per match.
  dirs_found = unique(dirs_found);

end


%
% This is the end of the file.
