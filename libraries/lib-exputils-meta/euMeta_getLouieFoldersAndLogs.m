function sessionlist = ...
  euMeta_getLouieFoldersAndLogs( sessionfolders, logfilepatterns );

% function sessionlist = ...
%   euMeta_getLouieFoldersAndLogs( sessionfolders, logfilepatterns );
%
% This fetches recording/USE folder locations and session metadata for all
% recording sessions found in a specified list of top-level directories.
%
% NOTE - Any folders that we couldn't find log data for are dropped.
%
% "sessionfolders" is a cell array containing paths to folders to
%   recursively probe for ephys data.
% "logfilepatterns" is a cell array containing filename patterns (including
%   wildcards) that may match Louie's log files.
%
% "sessionlist" is structure array, with the following fields (per
%   SESSIONMETA.txt):
%   "logdata" is a record structure from Louie's log file.
%   "folder_session" is a character vector with the session's top-level path.
%   "folders_openephys" is a cell array of Open Ephys data folder paths.
%   "folders_intanrec" is a cell array of Intan recording controller folders.
%   "folders_intanstim" is a cell array of Intan stim controller folders.
%   "folders_game" is a cell array of game data folder paths.


% Make an empty structure array with the correct fields.
sessionlist = struct( ...
  'logdata', {}, 'folder_session', {}, 'folders_openephys', {}, ...
  'folders_intanrec', {}, 'folders_intanstim', {}, 'folders_game', {} );


% Debugging/tattling.
want_report_orphans = true;



% Load all matching log files.

raw_logs = struct([]);
for pidx = 1:length(logfilepatterns)
  thisflist = dir(logfilepatterns{pidx});
  for fidx = 1:length(thisflist)
    if ~thisflist(fidx).isdir
      thisfile = [ thisflist(fidx).folder filesep thisflist(fidx).name ];

      % Catch broken symlinks and other non-files with "isfile".
      if isfile(thisfile)

        % This will discard any corrupted records, complaining on console.
        thislogdata = euMeta_getLouieLogData( thisfile, '' );

        % Tolerate dissimilar fields.
        raw_logs = nlUtil_concatStructArrays(raw_logs, thislogdata);

      end
    end
  end
end



% Find the raw list of data folders.

raw_openephys = {};
raw_intanrec = {};
raw_intanstim = {};
raw_game = {};

for fidx = 1:length(sessionfolders)
  [ thislist_openephys thislist_intanrec thislist_intanstim ...
    thislist_game ] = euMeta_getExperimentFolders( sessionfolders{fidx} );

  raw_openephys = [ raw_openephys thislist_openephys ];
  raw_intanrec = [ raw_intanrec thislist_intanrec ];
  raw_intanstim = [ raw_intanstim thislist_intanstim ];
  raw_game = [ raw_game thislist_game ];
end

% Remove duplicates. This also sorts.
raw_openephys = unique(raw_openephys);
raw_intanrec = unique(raw_intanrec);
raw_intanstim = unique(raw_intanstim);
raw_game = unique(raw_game);



% Try to associate each data folder with exactly one log record.

owners_openephys = ...
  helper_findOwners( raw_openephys, raw_logs, want_report_orphans );
owners_intanrec = ...
  helper_findOwners( raw_intanrec, raw_logs, want_report_orphans );
owners_intanstim = ...
  helper_findOwners( raw_intanstim, raw_logs, want_report_orphans );
owners_game = ...
  helper_findOwners( raw_game, raw_logs, want_report_orphans );



% Consolidate entries.

% FIXME - Skip anything we didn't find an owner for.
% We'd otherwise have to do a clever parse of the folder name to find out
% which data folders should be grouped. Clever is bad.

ownerlist = [ owners_openephys owners_intanrec owners_intanstim owners_game ];
ownerlist = ownerlist(~isnan(ownerlist));
% This sorts as well.
ownerlist = unique(ownerlist);

for oidx = 1:length(ownerlist)
  thisowner = ownerlist(oidx);

  thisrec = struct();
  thisrec.logdata = raw_logs(thisowner);

  thisrec.folder_session = '';

  thismask = (owners_openephys == thisowner);
  thisrec.folders_openephys = raw_openephys(thismask);

  thismask = (owners_intanrec == thisowner);
  thisrec.folders_intanrec = raw_intanrec(thismask);

  thismask = (owners_intanstim == thisowner);
  thisrec.folders_intanstim = raw_intanstim(thismask);

  thismask = (owners_game == thisowner);
  thisrec.folders_game = raw_game(thismask);

  sessionlist(oidx) = thisrec;
end



% Back-annotate session folders.

for sidx = 1:length(sessionlist)
  thisrec = sessionlist(sidx);

  allfolders = [ reshape( thisrec.folders_openephys, 1, [] ) ...
    reshape( thisrec.folders_intanrec, 1, [] ), ...
    reshape( thisrec.folders_intanstim, 1, [] ) ];

  thisdataset = thisrec.logdata.dataset;
  thisidx = find( contains( allfolders, thisdataset ) );

  if isempty(thisidx)
    % FIXME - This shouldn't happen.
    % The only entries in the session list were ones where at least one
    % folder associated with a dataset was found.
    disp([ '#  Can''t find top-level session folder for "' thisdataset '".' ]);
  else
    % Pick the first matching folder.
    thispath = allfolders{ thisidx(1) };

    % Look for the prefix up to and including the top-level folder.
    thisidx = strfind(thispath, thisdataset);
    if isempty(thisidx)
      % FIXME - This _really_ shouldn't happen (logic error).
      disp('#  Logic error searching for session folder within path.');
    else
      % Handle multiple matches within the path.
      thisidx = thisidx(1);

      % This may be empty, and includes the file separator if present.
      thisprefix = thispath(1:(thisidx-1));

      sessionlist(sidx).folder_session = [ thisprefix thisdataset ];
    end
  end
end



% Done.
end


%
% Helper Functions


% For each folder in "folderlist", an owner in "metalist" is identified,
% and the index of that owner is stored in "ownerlist". If no owner can be
% identified, NaN is stored.

function ownerlist = helper_findOwners( folderlist, metalist, want_tattle )

  ownerlist = NaN(size(folderlist));


  datasetlist = cell(size(metalist));
  datelist = cell(size(metalist));

  if isfield(metalist, 'dataset')
    datasetlist = { metalist.dataset };
  end
  if isfield(metalist, 'date')
    datelist = { metalist.date };
  end


  % This ends up giving priority to the last matching metadata record.
  for midx = 1:length(metalist)
    thiskey = datasetlist{midx};
    if isempty(thiskey)
      thiskey = datelist{midx};
    end

    if ~isempty(thiskey)
      foldermask = contains(folderlist, thiskey);
      ownerlist(foldermask) = midx;
    end
  end


  % Report orphaned folders, if desired.
  if want_tattle
    foldermask = isnan(ownerlist);
    orphanlist = folderlist(foldermask);

    for oidx = 1:length(orphanlist)
      disp(sprintf( '#  Can''t find log entry for folder:\n"%s"', ...
        orphanlist{oidx} ));
    end
  end

end



%
% This is the end of the file.
