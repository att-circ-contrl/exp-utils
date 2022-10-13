function [ rankreport ranktable ] = rankMatrixData( ...
  matrixdata, dataformat, datatitle, ...
  columncats, columnformat, columntitle, desiredcolidx, ...
  chanlabelsraw, chanlabelscooked, sortwanted )

% function [ rankreport ranktable ] = rankMatrixData( ...
%   matrixdata, dataformat, datatitle, ...
%   columncats, columnformat, columntitle, desiredcolidx, ...
%   chanlabelsraw, chanlabelscooked, sortwanted )
%
% This searches a matrix containing per-channel data, sorts it along a
% specified column, and produces a human-readable report describing the
% ranked channel values. It also produces an annotated table with the
% sorted matrix data suitable for writing to a CSV file.
%
% "matrixdata" is a Nchans x Ncols matrix of data values.
% "dataformat" is a sprintf template for formatting matrix data values.
% "datatitle" is a human-readable character array describing what the data is.
% "columncats" is a vector or cell array containing column category
%   values or labels. If this is empty, category information is omitted from
%   the report and output table. NOTE - If these are text labels, the labels
%   must be valid Matlab table column names!
% "columnformat" is a sprintf template for formatting column category
%   values, if they're numeric (vector rather than cell array).
% "columntitle" is a human-readable character array describing what type of
%   data the categories are.
% "desiredcolindex" is an index into "matrixdata" and "columncats" indicating
%   the desired column to sort on.
% "chanlabelsraw" is a cell array containing raw channel names.
% "chanlabelscooked" is a cell array containing cooked channel names.
% "sortwanted" indicates how to sort; 'min' finds the smallest values, 'max'
%   finds the largest values, 'absmin' the smallest magnitudes, and 'absmax'
%   the largest magnitudes.
%
% "rankreport" is a character array containing a human-readable report about
%   ranked channel values.
% "ranktable" is a table containing the data in "matrixdata", with an added
%   column containing channel names, and with the first row containing
%   column categories.


% Initialize.

rankreport = '';
ranktable = table();


% Sanity check.

% Remember that columncats may be empty.
desiredcolidx = min(desiredcolidx, length(columncats));
desiredcolidx = max(desiredcolidx, 1);

if ~isrow(columncats)
  columncats = columncats';
end
if ~iscolumn(chanlabelsraw)
  chanlabelsraw = chanlabelsraw';
end
if ~iscolumn(chanlabelscooked)
  chanlabelscooked = chanlabelscooked';
end

columncount = size(matrixdata);
columncount = columncount(2);


% Get sorting parameters.

sortdir = 'descend';
sorttype = 'real';

if strcmp('min', sortwanted)
  sortdir = 'ascend';
elseif strcmp('absmin', sortwanted)
  sortdir = 'ascend';
  sorttype = 'abs';
elseif strcmp('absmax', sortwanted)
  sorttype = 'abs';
end


% Get the sorted order.

sortcol = matrixdata(:,desiredcolidx);
[ sortcol, sortidx ] = sort( sortcol, sortdir, 'ComparisonMethod', sorttype );


%
% Generate a human-readable report.

sortlabelsraw = chanlabelsraw(sortidx);
sortlabelscooked = chanlabelscooked(sortidx);

if isempty(columncats)
  rankreport = '';
else
  rankreport = sprintf('Category (%s) values:\n', columntitle);

  for pidx = 1:length(columncats)
    if iscell(columncats)
      rankreport = [ rankreport '   ' columncats{pidx} ];
    else
      rankreport = ...
        [ rankreport '   ' sprintf(columnformat,columncats(pidx)) ];
    end
  end

  if iscell(columncats)
    rankreport = [ rankreport ...
      sprintf( [ '\nChosen %s:   %s\n' ], ...
      columntitle, columncats{desiredcolidx}) ];
  else
    rankreport = [ rankreport ...
      sprintf( [ '\nChosen %s:   ' columnformat '\n' ], ...
      columntitle, columncats(desiredcolidx)) ];
  end

  rankreport = [ rankreport sprintf('\n') ];
end

rankreport = [ rankreport sprintf('Channels ranked by %s:\n', datatitle) ];

for cidx = 1:length(sortlabelsraw)
  rankreport = [ rankreport ...
    sprintf( [ '%12s (raw %8s): ' dataformat '\n' ], ...
      sortlabelscooked{cidx}, sortlabelsraw{cidx}, sortcol(cidx)) ];
end



%
% Generate an augmented table.


% Sort the matrix before building the table.

matrixdata = matrixdata(sortidx,:);


% Make table column names.

if iscell(columncats) && (~isempty(columncats))
  tabcols = columncats;
else
  tabcols = {};
  for pidx = 1:columncount
    tabcols{pidx} = sprintf('Cat%d', pidx);
  end
end


% If we have numeric column categories, augment the matrix with them.

if (~isempty(columncats)) && (~iscell(columncats))
  matrixdata = vertcat(columncats, matrixdata);
  chanlabelsraw = vertcat({columntitle}, chanlabelsraw);
  chanlabelscooked = vertcat({columntitle}, chanlabelscooked);
end

% Build the table.

ranktable.('Channel') = chanlabelscooked;
ranktable.('RawChannel') = chanlabelsraw;
for pidx = 1:columncount
  ranktable.(tabcols{pidx}) = matrixdata(:,pidx);
end


% Done.

end


%
% This is the end of the file.
