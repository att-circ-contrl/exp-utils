function euChris_plotCaseDataBoxes( ...
  casedata, plotpercase, yfield, xfield, ...
  casetitles, caselabels, plottype, xstr, ystr, ...
  titleprefix, titlesuffix, fnameprefix, fnamesuffix )

% function euChris_plotCaseDataBoxes( ...
%   casedata, plotpercase, yfield, xfield, ...
%   casetitles, caselabels, plottype, xstr, ystr, ...
%   titleprefix, titlesuffix, fnameprefix, fnamesuffix )
%
% This makes a series of box plots with individual and aggregated data.
%
% This is intended to work with the output of "euChris_evalXXX" functions,
% which generate structures with various statistics stored as fields. This
% functiton is passed a cell array of such structures (for different
% experiment cases), and plots individual and aggregate statistics.
%
% "casedata" is a cell array containing per-case structures with data.
% "plotpercase" is true if per-case plots are to be generated in additon to
%   combined/aggregated plots.
% "yfield" is the structure field name containing data values to plot.
% "xfield" is the structure field name containing per-sample category/bin
%   values/labels. This is a vector for numeric values and a cell array for
%   labels.
% "casetitles" is a cell array containing plot-safe human-readable case titles.
% "caselabels" is a cell array containing filename-safe per-case labels.
% "plottype" is a label giving hints about how to set up the plot. Use '' for
%   defaults. Known values are: 'tortemagrel', 'tortemagabs', 'tortphase'
% "xstr" is a character vector containing the X axis label.
% "ystr" is a character vector containing the Y axis label.
% "titleprefix" is a character vector with plot-safe text to add before the
%   case title (including whitespace and delimiters).
% "titlesuffix" is a character vector with plot-safe text to append after the
%   case title (including whitespace and delimiters).
% "fnameprefix" is a character vector with filename-safe text to add before
%   the case label.
% "fnamesuffix" is a character vector with filename-safe text to append after
%   the case label.
%
% No return value.


% Figure out plot details depending on the type hint.

xtype = 'linear';
ytype = 'linear';
xrange = [];
yrange = [];
legendpos = 'off';
boxwidth = 0.5;
wantoutliers = true;
plotlines = {};
plothcursors = {};

cols = nlPlot_getColorPalette();

if strcmp(plottype, 'tortemagrel')
  xtype = 'linear';
  ytype = 'log';
  xrange = [ 0 4 ];
  yrange = [ 0.2 200 ];
  boxwidth = 0.2;
  plothcursors = { { 1 cols.gry '' } };
elseif strcmp(plottype, 'tortemagabs')
  xtype = 'linear';
  ytype = 'linear';
  xrange = [ 0 4 ];
  yrange = [ 0 10 ];
  boxwidth = 0.2;
  plotlines = { { 0 0 4 4 cols.gry '' } };
elseif strcmp(plottype, 'tortephaseerr')
  yrange = [ -200 200 ];
  xrange = [ -200 200 ];
  boxwidth = 30;
  plothcursors = { { 0 cols.gry '' } };
end


% Per-case plots.
% Build the aggregate data here.

aggrydata = [];
aggrxdata = [];
aggrlabels = {};

% FIXME - Enable warnings.
oldwarn = warning('on', 'all');

for cidx = 1:length(caselabels)

  thiscaselabel = caselabels{cidx};
  thiscasetitle = casetitles{cidx};
  thiscasedata = casedata{cidx};

  % NOTE - Bulletproof this as a precaution.
  if ~( isfield(thiscasedata, yfield) && isfield(thiscasedata, xfield) )
    warning( [ '### [euChris_plotCaseDataBoxes]  Case "' thiscaselabel ...
      '" is missing field "' xfield '" and/or "' yfield '".' ] );
    continue;
  end

  thisydata = thiscasedata.(yfield);
  thisxdata = thiscasedata.(xfield);

  if ~isrow(thisydata)
    thisydata = transpose(thisydata);
  end
  if ~isrow(thisxdata)
    thisxdata = transpose(thisxdata);
  end

  aggrydata = [ aggrydata thisydata ];
  aggrxdata = [ aggrxdata thisxdata ];

  thislabelvec = {};
  % FIXME - Maybe use titles?
  thislabelvec(1:length(thisydata)) = { thiscaselabel };
  aggrlabels = [ aggrlabels thislabelvec ];


  % Only generate per-case plots if we were asked to.

  if plotpercase
    titlestr = [ titleprefix thiscasetitle titlesuffix ];
    fname = [ fnameprefix thiscaselabel fnamesuffix ];

    euPlot_plotMultipleBoxCharts( thisydata, thisxdata, {}, ...
      xtype, ytype, xrange, yrange, xstr, ystr, ...
      wantoutliers, boxwidth, plotlines, plothcursors, 'off', ...
      titlestr, fname );
  end

end


% Aggregate plots.
% One with true aggregate data, one showing the per-case data in one plot.

euPlot_plotMultipleBoxCharts( aggrydata, aggrxdata, {}, ...
  xtype, ytype, xrange, yrange, xstr, ystr, ...
  wantoutliers, boxwidth, plotlines, plothcursors, 'off', ...
  [ titleprefix 'Aggregate' titlesuffix ], ...
  [ fnameprefix 'aggregate' fnamesuffix ] );

euPlot_plotMultipleBoxCharts( aggrydata, aggrxdata, aggrlabels, ...
  xtype, ytype, xrange, yrange, xstr, ystr, ...
  wantoutliers, boxwidth, plotlines, plothcursors, 'northeast', ...
  [ titleprefix 'Combined' titlesuffix ], ...
  [ fnameprefix 'all' fnamesuffix ] );


% FIXME - Finished with warnings.
warning(oldwarn);


% Done.
end



%
% This is the end of the file.
