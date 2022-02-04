function [ evtable have_events ] = ...
  euFT_getSingleBitEvent( namelut, thissigname, headerlabels, allevents )

% function [ evtable have_events ] = ...
%   euFT_getSingleBitEvent( namelut, thissigname, headerlabels, allevents )
%
% This looks up a channel label pattern for a given signal, looks up channels
% that match that pattern, picks the first such channel, and then finds
% events that are from that channel, returning the result as a table.
%
% NOTE - This only works for LoopUtil events! Those have the channel labels
% stored in the event records' "type" field.
%
% "namelut" is a structure indexed by signal name that has cell arrays of
%   Field Trip channel label specifiers (per ft_channelselection()).
% "thissigname" is the signal label to look for in "namelut".
% "headerlabels" is the "label" cell array from the Field Trip header.
% "allevents" is the event list to search.
%
% "evtable" is a table containing the filtered event list's fields. This
%   table may be empty.
% "have_events" is true if at least one matching event was detected.


evtable = table();
have_events = false;

if isfield(namelut, thissigname)
  chanlist = ft_channelselection( namelut.(thissigname), headerlabels, {} );

  if ~isempty(chanlist)
    % We only want a single channel's events.
    % There should be only one, but tolerate finding multiple.
    thischan = chanlist{1};

    % Filter the event list.
    % FIXME - This only works for LoopUtil events that store the channel
    % label in the "type" field!
    thisevlabels = { allevents(:).type };
    thismask = strcmp(thischan, thisevlabels);
    thisevlist = allevents(thismask);

    % If we still have events, build and save the table.
    if ~isempty(thisevlist)
      evtable = struct2table(thisevlist);
      have_events = true;
    end
  end
end


% Done.
end



%
% This is the end of the file.
