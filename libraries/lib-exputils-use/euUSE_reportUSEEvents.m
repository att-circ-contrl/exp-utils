function reportmsg = ...
  euUSE_reportUSEEvents( boxevents, gameevents, evcodedefs )

% function reportmsg = ...
%   euUSE_reportUSEEvents( boxevents, gameevents, evcodedefs )
%
% This generates a human-readable summary of events read by
% euUSE_readAllUSEEvents().
%
% The supplied structures may be empty.
%
% "boxevents" is a structure containing SynchBox event data tables.
% "gameevents" is a structure containing USE event data tables.
% "evcodedefs" is a USE event code definition structure.
%
% "reportmsg" is a character vector containing a human-readable summary of
%   the number and type of events found.


reportmsg = '';

newline = sprintf('\n');


if isempty(evcodedefs)
  reportmsg = [ reportmsg '-- No event code definitions.' newline ];
else
  reportmsg = [ reportmsg sprintf('-- %d types of event code defined.\n', ...
    length(fieldnames(evcodedefs)) ) ];
end


reportmsg = [ reportmsg euUSE_reportEventTables( 'SynchBox', boxevents ) ];
reportmsg = [ reportmsg euUSE_reportEventTables( 'Game', gameevents ) ];


% Done.
end


%
% This is the end of the file.
