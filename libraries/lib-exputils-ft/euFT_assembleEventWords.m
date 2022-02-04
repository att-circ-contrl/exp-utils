function wordevents = ...
  euFT_assembleEventWords( bitlabels, bitevents, wordlabel, firstbit )

% function wordevents = ...
%   euFT_assembleEventWords( bitlabels, bitevents, wordlabel, firstbit )
%
% This assembles events associated with individual bit changes into a
% sequence of events associated with code word changes.
%
% Channel labels are assumed to end in the bit number. The named bit number
% is treated as the least-significant bit in the code word (this is usually
% 0 or 1, depending on channel label conventions).
%
% NOTE - This only works for LoopUtil events! Those have the channel names
% stored in the event records' "type" field.
%
% NOTE - This uses unsigned 64-bit event words.
%
% "bitlabels" is a cell array containing channel labels for individual bits.
% "bitevents" is an event structure array to search for bit-change events in.
% "wordlabel" is the value to store in the derived list's "type" field.
% "firstbit" is the channel bit number corresponding to the least-significant
%   bit in the output word. This is usually 0 or 1.
%
% "wordevents" is an event structure array containing word-change events.


% Initialize output.
wordevents = ...
  struct('sample', {}, 'value', {}, 'type', {}, 'offset', {}, 'duration', {});
evcount = 0;


% FIXME - Do this the slow but reliable way, walking through events one at
% a time.


% Build a lookup table of Matlab bit indices for each channel.

bitlut = struct();

for lidx = 1:length(bitlabels)
  thislabel = bitlabels{lidx};
  tokenlist = regexp(thislabel, '(\d+)$', 'tokens');
  if isempty(tokenlist)
    % FIXME - Diagnostics.
    disp(sprintf( ...
      '###  Couldn''t get bit number from label "%s".', thislabel ));
  else
    thisnum = str2double(tokenlist{1}{1});
    if thisnum < firstbit
      % FIXME - Diagnostics.
      disp(sprintf('###  Channel "%s" has bit number below minimum "%d".', ...
        thislabel, firstbit));
    else
      thisnum = thisnum - firstbit;
      % Remember that Matlab considers the least-significant bit to be bit 1.
      thisnum = thisnum + 1;
      bitlut.(thislabel) = thisnum;
    end
  end
end


% Walk through the events, recording changes.
% FIXME - Assume that events are already sorted in temporal order!

prevtime = NaN;
currentword = uint64(0);

for evidx = 1:length(bitevents)
  thisev = bitevents(evidx);
  % FIXME - This only works for LoopUtil events, which store channel label
  % in "type"!
  thislabel = thisev.type;

  if isfield(bitlut, thislabel)
    thisbitnum = bitlut.(thislabel);
    thistime = thisev.sample;
    thisval = thisev.value;

    % If the time changed, write the _previous_ sample.
    if (~isnan(prevtime)) && (prevtime ~= thistime)
      evcount = evcount + 1;
      wordevents(evcount) = ...
        struct( 'sample', prevtime, 'value', currentword, ...
          'type', wordlabel, 'offset', [], 'duration', [] );
    end

    % Update the current sample.
    prevtime = thistime;
    if thisval > 0
      currentword = bitset(currentword, thisbitnum, 1);
    else
      currentword = bitset(currentword, thisbitnum, 0);
    end
  end
end

% If we had any matches at all, write the last value seen.
if ~isnan(prevtime)
  evcount = evcount + 1;
  wordevents(evcount) = ...
    struct( 'sample', prevtime, 'value', currentword, ...
      'type', wordlabel, 'offset', [], 'duration', [] );
end


% Done.

end


%
% This is the end of the file.
