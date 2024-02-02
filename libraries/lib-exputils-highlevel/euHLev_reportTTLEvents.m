function reportmsg = ...
  euHLev_reportTTLEvents( boxevents, gameevents, evcodedefs, ...
  deveventsraw, deveventscooked, devnames )

% function reportmsg = ...
%   euHLev_reportTTLEvents( boxevents, gameevents, evcodedefs, ...
%   deveventsraw, deveventscooked, devnames )
%
% This generates a human-readable summary of events read by
% euHLev_readAllTTLEvents().
%
% Event and event code definition structures may be empty.
%
% "boxevents" is a structure containing SynchBox event data tables.
% "gameevents" is a structure containing USE event data tables.
% "evcodedefs" is a USE event code definition structure per EVCODEDEFS.txt.
% "deveventsraw" is a structure indexed by device type containing each
%   device's raw Field Trip event list, per euUSE_readAllEphysEvents().
% "deveventscooked" is a structure indexed by device type containing each
%   device's cooked event tables, per euUSE_readAllEphysEvents().
% "devnames" is a structure indexed by device type containing human-readable
%   device names.
%
% "reportmsg" is a character vector containing a human-readable summary of
%   the number and type of events found.


% First, report game events, if any.

reportmsg = euUSE_reportUSEEvents( boxevents, gameevents, evcodedefs );



% Don't assume that the raw and cooked device lists match; iterate each
% separately.


%
% Build a merged name list to catch orphans.

rawlabels = {};
if ~isempty(deveventsraw)
  rawlabels = fieldnames(deveventsraw);
end

cookedlabels = {};
if ~isempty(deveventscooked)
  cookedlabels = fieldnames(deveventscooked);
end

if isempty(devnames)
  devnames = struct();
end
namelabels = fieldnames(devnames);

alllabels = unique( [ rawlabels cookedlabels namelabels ] );

for lidx = 1:length(alllabels)
  thislabel = alllabels{lidx};
  if ~ismember(thislabel, namelabels)
    devnames.(thislabel) = thislabel;
  end
end


%
% Report raw events.

for devidx = 1:length(rawlabels)
  thisdev = rawlabels{devidx};
  reportmsg = [ reportmsg ...
    sprintf( '-- %s had %d raw Field Trip Events.\n', ...
      devnames.(thisdev), length(deveventsraw.(thisdev)) ) ];
end


%
% Report cooked events.

for devidx = 1:length(cookedlabels)
  thisdev = cookedlabels{devidx};
  reportmsg = [ reportmsg euUSE_reportEventTables( ...
    [ devnames.(thisdev) ' processed' ], deveventscooked.(thisdev) ) ];
end


% Ending banner.

reportmsg = [ reportmsg '-- End of report.' sprintf('\n') ];


% Done.
end


%
% This is the end of the file.
