function newlist = euMeta_pruneLouieSessionList( oldlist, desiredsessions )

% function newlist = euMeta_pruneLouieSessionList( oldlist, desiredsessions )
%
% This filters a raw list of detected sessions to include only those listed
% in the "desiresessions" metadata list. The filtered session list is
% augmented with information from the desired session metadata.
%
% NOTE - This version of the function only works for experiments that use
% Louie's metadata format.
%
% "oldlist" is a struct array with detected session metadata, per
%   SESSIONMETA.txt. This is from euMeta_getLouieFoldersAndLogs().
% "desiredsessions" is a struct array with metadata about desired sessions,
%   per DESIREDSESSIONS.txt. This is from euMeta_getDesiredSessions_xx().
%
% "newlist" is a struct array with augmented session metadata for sessions
%   that are listed in "desiredsessions".


newlist = struct([]);

datasetlist = { desiredsessions.dataset };

for oldidx = 1:length(oldlist)
  thisrec = oldlist(oldidx);
  thisdataset = thisrec.logdata.dataset;

  desiredidx = find(strcmp( thisdataset, datasetlist ));
  if ~isempty(desiredidx)

    % Blithely assume only one entry, but handle duplicates gracefully.
    desiredidx = desiredidx(1);

    thisdesired = desiredsessions(desiredidx);

    thisrec.monkey = thisdesired.monkey;
    thisrec.probedefs = thisdesired.probedefs;

    [ safelabel safetitle ] = euUtil_makeSafeString( thisdataset );
    thisrec.sessionid = thisdataset;
    thisrec.sessionlabel = safelabel;
    thisrec.sessiontitle = safetitle;

    newlist = [ newlist thisrec ];

  end
end



% Done.
end


%
% This is the end of the file.
