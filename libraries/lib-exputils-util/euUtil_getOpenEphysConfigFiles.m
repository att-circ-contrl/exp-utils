function [ configfiles mapfiles ] = euUtil_getOpenEphysConfigFiles( topdir )

% function [ configfiles mapfiles ] = euUtil_getOpenEphysConfigFiles( topdir )
%
% This function looks for files with "Config" or "Mapping" in the name (not
% case-sensitive) and reports their full names (including path).
%
% This is intended to be used to find Open Ephys channel mapping and
% configuration files.
%
% "topdir" is the top-level folder to search (usually the Open Ephys folder).
%
% "configfiles" is a cell array containing full filenames that had "config".
% "mapfiles" is a cell array containing full filenames that had "mapping".


% Initialize.

configfiles = {};
mapfiles = {};

% Search the tree.

if isdir(topdir)

  [ fnames fpaths ] = nlIO_searchForFile(topdir, '*Config*');
  fullnames = strcat(fpaths, filesep, fnames);
  [ fnames fpaths ] = nlIO_searchForFile(topdir, '*config*');
  configfiles = [ fullnames strcat(fpaths, filesep, fnames) ];
  configfiles = unique(configfiles);


  [ fnames fpaths ] = nlIO_searchForFile(topdir, '*Mapping*');
  fullnames = strcat(fpaths, filesep, fnames);
  [ fnames fpaths ] = nlIO_searchForFile(topdir, '*mapping*');
  mapfiles = [ fullnames strcat(fpaths, filesep, fnames) ];
  mapfiles = unique(mapfiles);

end


% Done.

end


%
% This is the end of the file.
