function tabdata = euUSE_aggregateTrialFiles(filepattern, sortcolumn)

% function tabdata = euUSE_aggregateTrialFiles(filepattern, sortcolumn)
%
% This reads the specified set of tab-delimited text files, aggregating the
% data contained within. The resulting combined table is sorted based on the
% specified column and returned.
%
% This is intended to be used with per-trial files, sorting on the timestamp.
%
% "filepattern" is the path-plus-wildcards file specifier to pass to dir().
% "sortcolumn" is the name of the table column to sort table rows with.
%
% "tabdata" is the resulting sorted merged table.


tabdata = table();

flist= dir(filepattern);
if ~isempty(flist)
  for fidx = 1:length(flist)
    thisname = [ flist(fidx).folder filesep flist(fidx).name ];
    thistable = readtable(thisname, 'Delimiter', 'tab');
    if fidx == 1
      tabdata = thistable;
    else
      tabdata = [ tabdata ; thistable ];
    end
  end
end

if ~isempty(tabdata)
  tabdata = sortrows(tabdata, sortcolumn);
end


% Done.

end


%
% This is the end of the file.
