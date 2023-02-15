function found = euHLev_checkChannelsExist( header_ft, headername, chanlist )

% function found = euHLev_checkChannelsExist( header_ft, headername, chanlist )
%
% This checks the "label" field of the specified FT header to see if it
% contains the requested channel names. Error messages are optionally
% displayed if channels are missing.
%
% "header_ft" is the Field Trip header to search.
% "headername" is a human-readable name for identifying the header when
%   reporting missing channels (e.g. 'FooHeader', for "FooHeader doesn't
%   contain..."). If this is [], no messages are produced.
% "chanlist" is a cell array containing the channel names to search for.
%
% "found" is true if all of the requested channels are found and false
%   otherwise.


found = true;

for cidx = 1:length(chanlist)

  thisname = chanlist{cidx};

  if ~ismember(thisname, header_ft.label)

    found = false;
    if ~isempty(headername)
      disp([ '###  ' headername ' doesn''t contain channel "' ...
        thisname '".' ]);
    end

  end

end


% Done.

end


%
% This is the end of the file.
