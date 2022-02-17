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
  % FIXME - traversing in unsorted order.
  % We should traverse this is "natural" sorted order (per sort_nat).
  % If we do that, then we can allow the undocumented "empty sortcolumn name
  % skips sorting" option.

  for fidx = 1:length(flist)
    thisname = [ flist(fidx).folder filesep flist(fidx).name ];
    thistable = readtable(thisname, 'Delimiter', 'tab');

    if fidx == 1
      tabdata = thistable;
    else
      % NOTE - We need to promote appropriate non-cell columns to cell columns
      % before concatenating. Whether they're auto-detected correctly or not
      % depends on the data in the table.

      % FIXME - Assuming that any misdetected data is read as numeric data!

      colnames = tabdata.Properties.VariableNames;
      for cidx = 1:length(colnames)
        thiscol = colnames{cidx};
        if iscell(tabdata.(thiscol)) && (~iscell(thistable.(thiscol)))
          thistable.(thiscol) = num2cell(thistable.(thiscol));
        elseif (~iscell(tabdata.(thiscol))) && iscell(thistable.(thiscol))
          tabdata.(thiscol) = num2cell(tabdata.(thiscol));
        end
      end

      % Concatenate the tables, now that they're compatible.
      tabdata = [ tabdata ; thistable ];
    end
  end
end

if (~isempty(tabdata)) && (~isempty(sortcolumn))
  tabdata = sortrows(tabdata, sortcolumn);

  % FIXME - Sanity-check the sorting!
  if true
    sortseries = tabdata.(sortcolumn);
    sortcount = length(sortseries);
    uniquecount = length(unique(sortseries));
    if uniquecount < sortcount
      disp(sprintf( ...
        [ '###  [euUSE_aggregateTrialFiles] NOTE - Sorting column "%s" ' ...
          'only had %d of %d unique values, when processing "%s".' ], ...
        sortcolumn, uniquecount, sortcount, filepattern ));
    end
  end
end


% Done.

end


%
% This is the end of the file.
