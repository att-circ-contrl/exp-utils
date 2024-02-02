function reportmsg = euUSE_reportEventTables( sourcename, cookedevents )

% function reportmsg = euUSE_reportEventTables( sourcename, cookedevents )
%
% This generates a human-readable summary of the events contained in the
% specified "cooked events" structure.
%
% "sourcename" is a character vector containing a human-readable name for
%   the device sourcing the events.
% "cookedevents" is a structure with one field name per USE event type,
%   containing USE event data tables. This may be struct() or struct([])
%   and may contain empty tables.
%
% "reportmsg" is a character vector containing a human-readable summary of
%   the number and type of events found.


reportmsg = '';

newline = sprintf('\n');

if isempty(cookedevents)
  reportmsg = [ reportmsg '-- No ' sourcename ' events.' newline ];
elseif isempty(fieldnames(cookedevents))
  reportmsg = [ reportmsg '-- No ' sourcename ' events.' newline ];
else
  reportmsg = [ reportmsg '-- ' sourcename ' events:' newline ];

  fieldlist = fieldnames(cookedevents);
  for fidx = 1:length(fieldlist)
    thisfield = fieldlist{fidx};
    reportmsg = [ reportmsg sprintf('  %6d -- %s\n', ...
      height(cookedevents.(thisfield)), thisfield ) ];
  end
end



% Done.
end


%
% This is the end of the file.
