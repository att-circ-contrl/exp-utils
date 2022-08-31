function [ reftime newsignals ] = ...
  euUSE_removeLargeTimeOffset( oldsignals, timecolumn, desiredreftime )

% function [ reftime newsignals ] = ...
%   euUSE_removeLargeTimeOffset( oldsignals, timecolumn, desiredreftime )
%
% This function subtracts a large time offset from all signal tables in
% the provided structure.
%
% This is intended to be used to modify Unity timestamps, which are relative
% to 1 Jan 1970.
%
% "oldsignals" is a structure with fields that each contain a table of
%   timestamped events.
% "timecolumn" is the name of the table column that contains timestamps.
% "desiredreftime" is a desired time offset to be subtracted from all
%   timestamps. If this argument is omitted, and arbitrary offset is chosen.
%
% "reftime" is the time value that was subtracted from all timestamps.
% "newsignals" is a copy of "oldsignals" with "reftime" subtracted from all
%   tables' timestamp columns.


reftime = 0;
newsignals = struct();

signames = fieldnames(oldsignals);


% First pass: Get an arbitrarily-chosen reference time.
% We're using the minimum timestamp value we can see in the data.

for fidx = 1:length(signames)
  thislabel = signames{fidx};
  thistab = oldsignals.(thislabel);

  if ~isempty(thistab)
    thistimes = thistab.(timecolumn);
    if ~isempty(thistimes)

      thismin = min(thistimes);

      if fidx <= 1
        reftime = thismin;
      else
        reftime = min(reftime, thismin);
      end

    end
  end
end


% Override the auto-detected reference with a supplied reference if one was
% given.
if exist('desiredreftime', 'var')
  reftime = desiredreftime;
end


% Second pass: Subtract the reference time.

for fidx = 1:length(signames)
  thislabel = signames{fidx};
  thistab = oldsignals.(thislabel);

  if ~isempty(thistab)
    thistab.(timecolumn) = thistab.(timecolumn) - reftime;
  end

  newsignals.(thislabel) = thistab;
end


% Done.

end


%
% This is the end of the file.
