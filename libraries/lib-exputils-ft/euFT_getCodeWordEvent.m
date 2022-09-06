function [ evtable have_events ] = euFT_getCodeWordEvent( ...
  namelut, wordsigname, bitsignames, firstbit, shiftbitsname, ...
  headerlabels, allevents )

% function [ evtable have_events ] = euFT_getCodeWordEvent( ...
%   namelut, wordsigname, bitsignames, firstbit, shiftbitsname, ...
%   headerlabels, allevents )
%
% This looks up channel label patterns for a given signal, looks up channels
% that match those patterns, picks appropriate channels, and finds events
% that are from these channels, merges them into event words, and, returns
% the result as a table.
%
% NOTE - This only works for LoopUtil events! Those have the channel names
% stored in the event records' "type" field.
%
% "namelut" is a structure indexed by signal name that has cell arrays of
%   Field Trip channel label specifiers (per ft_channelselection()), and
%   that also has a field storing the number of bits to shift code words.
% "wordsigname" is the class label to look for for whole-word data. This
%   should only match one Field Trip label.
% "bitsignames" is the wildcard class label to look for for single-bit data.
%   These are treated as word bits, and labels are assumed to end in the bit
%   number.
% "firstbit" is the bit number of the least-significant bit in the word. This
%   is usually 0 or 1, depending on channel label conventions.
% "shiftbitsname" is the LUT field to look for for the bit shift. If this
%   isn't found, a bit shift of 0 is assumed.
% "headerlabels" is the "label" cell array from the Field Trip header.
% "allevents" is the event list to search.
%
% "evtable" is a table containing the filtered event list. This may be empty.
% "have_events" is true if at least one matching event was detected.


% Initialize to safe output.
evtable = table();
have_events = false;


% Get the desired bit shift.
shiftbitcount = 0;
if isfield(namelut, shiftbitsname)
  shiftbitcount = namelut.(shiftbitsname);
end


% Get the desired channel lists.

wordchanlist = {};
bitschanlist = {};

if isfield(namelut, wordsigname)
  wordchanlist = ...
    ft_channelselection( namelut.(wordsigname), headerlabels, {} );
end

if isfield(namelut, bitsignames)
  bitschanlist = ...
    ft_channelselection( namelut.(bitsignames), headerlabels, {} );
end


% Look for events.
% Give priority to whole-word channels if present.

thisevlist = [];

if ~isempty(wordchanlist)

  % We only want a single channel's events.
  % There should be only one, but tolerate finding multiple.
  thischan = wordchanlist{1};

  % Filter the event list.
  % FIXME - This only works for LoopUtil events that store the channel
  % label in the "type" field!
  thisevlabels = { allevents(:).type };
  thismask = strcmp(thischan, thisevlabels);
  thisevlist = allevents(thismask);

elseif ~isempty(bitschanlist)

  % Get raw event words by merging bit channels.
  % Channel labels are assumed to end in the bit number.

  % FIXME - Choosing an arbitrary label for reconstructed words.
  thisevlist = ...
    euFT_assembleEventWords( bitschanlist, allevents, 'Words', firstbit );

end


% If we found events, build and save the table and apply the bit shift.

if ~isempty(thisevlist)
  evtable = struct2table(thisevlist);
  have_events = true;

  if shiftbitcount ~= 0
    % Negative counts shift to the right.
    % FIXME - Blithely assuming that the default type has enough bits!
    evtable.value = bitshift(evtable.value, -shiftbitcount);
  end
end


% Done.
end



%
% This is the end of the file.
