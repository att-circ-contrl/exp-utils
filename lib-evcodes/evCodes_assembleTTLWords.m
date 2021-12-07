function [ wordsamps, wordvals ] = ...
  evCodes_assembleTTLWords( risesamps, fallsamps, word_bit_lut )

% function [ wordsamps, wordvals ] = ...
%   evCodes_assembleTTLWords( risesamps, fallsamps, word_bit_lut )
%
% This function assembles multiple TTL event channels into one code word
% event channel. Code changes one sample apart are merged; changes farther
% than one sample apart are assumed to be real.
%
% "risesamps" is a cell array indexed by TTL channel number containing
%   sample indices of rising edges.
% "fallsamps" is a cell array indexed by TTL channel number containing
%   sample indices of falling edges.
% "word_bit_lut" is a vector indexed by TTL channel number. Entries that
%   contain nonzero values are added to the code word when that TTL channel
%   is high.
%
% "wordsamps" is a vector containing sample indices of code word changes.
% "wordvals" is a vector containing code word values resulting from changes.


%
% Extract only the channels that we care about.

ttlbits = min(length(risesamps), length(fallsamps));

extcount = 0;
extrise = {};
extfall = {};
extvals = [];

for bidx = 1:length(word_bit_lut)
  if (0 ~= word_bit_lut(bidx)) && (bidx <= ttlbits)
    extcount = extcount + 1;
    extrise{extcount} = risesamps{bidx};
    extfall{extcount} = fallsamps{bidx};
    extvals(extcount) = word_bit_lut(bidx);
  end
end

if length(word_bit_lut) > 0
  % FIXME - Force type.
  % This makes sure that bitwise operations work and output stay consistent.
  extvals = cast(extvals, 'uint32');
end



%
% Get a master list of times when changes happened.
% Figure out the starting value here too.

alltimes = [];
startword = 0;

if length(extvals) > 0
  % FIXME - Force type.
  % This makes sure that bitwise operations work and output stay consistent.
  startword = cast(startword, 'like', extvals);
end

for bidx = 1:length(extvals)
  % Defer sorting, since we have a fairly small number of channels.
  % FIXME - We know a priori that these are columns. We should make sure!
  alltimes = [ alltimes ; extrise{bidx} ; extfall{bidx} ];

  % If the first event we see for this bit is a falling edge, start high.
  if ~isempty(extfall{bidx})
    if isempty(extrise{bidx})
      startword = startword + extvals(bidx);
    else
      risetime = extrise{bidx}(1);
      falltime = extfall{bidx}(1);
      if falltime < risetime
        startword = startword + extvals(bidx);
      end
    end
  end
end

% This sorts in addition to removing duplicates.
alltimes = unique(alltimes);


%
% Do the code event list reconstruction. Don't deglitch yet.

% FIXME - There is a clever way of doing this. I'm using the not-clever
% and slower way, because it's easier to implement and debug.

wordsamps = [];
wordvals = [];

thiswordval = startword;
outcount = 0;

risereadptrs = ones(size(extvals));
fallreadptrs = ones(size(extvals));

for tidx = 1:length(alltimes)
  thistime = alltimes(tidx);

  for bidx = 1:length(extvals)

    thisrise = extrise{bidx};
    readptr = risereadptrs(bidx);
    if readptr <= length(thisrise)
      if thisrise(readptr) == thistime
        % NOTE - Bitwise operations tolerate missed edges.
%        thiswordval = thiswordval + extvals(bidx);
        thiswordval = bitor(thiswordval, extvals(bidx));
        risereadptrs(bidx) = readptr + 1;
      end
    end

    thisfall = extfall{bidx};
    readptr = fallreadptrs(bidx);
    if readptr <= length(thisfall)
      if thisfall(readptr) == thistime
        % NOTE - Bitwise operations tolerate missed edges.
%        thiswordval = thiswordval - extvals(bidx);
        thiswordval = bitand( thiswordval, bitcmp(extvals(bidx)) );
        fallreadptrs(bidx) = readptr + 1;
      end
    end

  end

  % We know _something_ happened, so emit the new code.
  outcount = outcount + 1;
  wordsamps(outcount) = thistime;
  wordvals(outcount) = thiswordval;
end


%
% Deglitch the event list.
% Changes 1 sample apart are assumed to be the same change.

oldsamps = wordsamps;
oldvals = wordvals;

wordsamps = [];
wordvals = [];
outcount = 0;

if length(oldsamps) > 0
  wordsamps(1) = oldsamps(1);
  wordvals(1) = oldvals(1);
  outcount = 1;
end

for tidx = 2:length(oldsamps)
  if (1 + oldsamps(tidx-1)) == oldsamps(tidx)
    % Still part of the same event.
    wordvals(outcount) = oldvals(tidx);
  else
    % New event.
    outcount = outcount + 1;
    wordsamps(outcount) = oldsamps(tidx);
    wordvals(outcount) = oldvals(tidx);
  end
end


% Done.

end


%
% This is the end of the file.
