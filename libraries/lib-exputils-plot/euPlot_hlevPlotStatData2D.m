function euPlot_hlevPlotStatData2D( plotdata, plottype, decorations, ...
  xrange, yrange, loglin, legendlutcase, legendlutprobe, ...
  figtitle, xtitle, ytitle, outfile )

% function euPlot_hlevPlotStatData2D( plotdata, plottype, decorations, ...
%   xrange, yrange, loglin, legendlutcase, legendlutprobe, ...
%   figtitle, xtitle, ytitle, outfile )
%
% This renders cooked plot data to an XY plot or a line plot.
%
% NOTE - Axes that are labels rather than numeric data will be arranged in
% lexical order.
%
% "plotdata" is cooked plot data, per PLOTDATACOOKED.txt.
% "plottype" is 'xy' or 'line'.
% "decorations" is a cell array which may include any of the following:
%   'diag' draws a diagonal line (usually for xy plots).
%   'hunity' draws a horizontal line at Y=1.
%   'hzero' draws a horizontal line at Y=0.
% "xrange" [ min max ] specifies the X axis range, or [] to auto-range.
% "yrange" [ min max ] specifies the Y axis range, or [] to auto-range.
% "loglin" is 'log' or 'linear', applying to both axes. This is normally
%   only log for XY plots. Label data will always be linear.
% "legendlutcase" is a plotting style lookup table indexed by case label,
%   per PLOTLEGENDLUT.txt.
% "legendlutprobe" is a plotting style lookup table indexed by probe label,
%   per PLOTLEGENDLUT.txt.
% "figtitle" is the title to use for the figure.
% "xtitle" is the title to use for the X axis.
% "ytitle" is the title to use for the Y axis.
% "outfile" is the name of the file to write to.
%
% No return value.


%
% Bail out if we have no data.

if isempty(plotdata)
  return;
end



%
% Get label lookup tables if X or Y holds label data.
% These get sorted in lexical order (side effect of "unique").

xticlabels = {};
yticlabels = {};

if iscell( plotdata(1).dataseriesx )
  xticlabels = nlUtil_extractStructureSeries( plotdata, 'dataseriesx' );
  xticlabels = unique(xticlabels);
end

if iscell( plotdata(1).dataseriesy )
  yticlabels = nlUtil_extractStructureSeries( plotdata, 'dataseriesy' );
  yticlabels = unique(yticlabels);
end


% Only numeric axes can be log-scale.

want_x_log = false;
want_y_log = false;

if strcmp(loglin, 'log')
  want_x_log = isempty(xticlabels);
  want_y_log = isempty(yticlabels);
end



%
% Get ranges.

if isempty(xrange)
  if isempty(xticlabels)
    defaultrange = [ 0 1 ];
  else
    % Default to 0..n+1, to get sensible ranges for labels.
    defaultrange = [ 0 (1 + length(xticlabels)) ];
  end

  [ minvalx maxvalx ] = euPlot_getStructureSeriesRange( ...
    plotdata, 'dataseriesx', defaultrange, [] );

  % Kludge to catch constant-data case.
  if maxvalx == minvalx
    maxvalx = minvalx + 1;
  end
else
  minvalx = min(xrange);
  maxvalx = max(xrange);
end

if isempty(yrange)
  if isempty(yticlabels)
    defaultrange = [ 0 1 ];
  else
    % Default to 0..n+1, to get sensible ranges for labels.
    defaultrange = [ 0 (1 + length(yticlabels)) ];
  end

  extravalsy = [];
  if ismember('hunity', decorations)
    extravalsy = [ extravalsy 1 ];
  end
  if ismember('hzero', decorations)
    extravalsy = [ extravalsy 0 ];
  end

  [ minvaly maxvaly ] = euPlot_getStructureSeriesRange( ...
    plotdata, 'dataseriesy', defaultrange, extravalsy );

  % Kludge to catch constant-data case.
  if maxvaly == minvaly
    maxvaly = minvaly + 1;
  end
else
  minvaly = min(yrange);
  maxvaly = max(yrange);
end


% Get the XY plot range.
minvaldiag = min(minvalx, minvaly);
maxvaldiag = max(maxvalx, maxvaly);

% Tweak plot foor location.
minvaly = min(0, minvaly);
minvaldiag = min(0, minvaldiag);

% Clamp for logscale plots.
if want_x_log
  minvalx = 0.01 * maxvalx;
  minvaldiag = max(minvaldiag, minvalx);
end
if want_y_log
  minvaly = 0.01 * maxvaly;
  minvaldiag = max(minvaldiag, minvaly);
end



%
% Set up for plotting.

thisfig = figure();

figure(thisfig);
clf('reset');

hold on;


cols = nlPlot_getColorPalette();

% Matlab's default marker size is 6.
markersize = 4;



%
% Plot individual data series.
% NOTE - Building the legend afterwards; plot without display names.

casesplotted = {};
probesplotted = {};

allcaselabels = legendlutcase(:,1);
allprobelabels = legendlutprobe(:,1);

for recidx = 1:length(plotdata)

  % Get data series.

  thisxseries = plotdata(recidx).dataseriesx;
  thisyseries = plotdata(recidx).dataseriesy;


  % Special-case label series.

  if iscell(thisxseries)
    thisxseries = nlUtil_getLabelIndices( thisxseries, xticlabels );
  end

  if iscell(thisyseries)
    thisyseries = nlUtil_getLabelIndices( thisyseries, yticlabels );
  end


  % Figure out colours, line styles, and markers.

  caselabel = plotdata(recidx).caselabel;
  probelabel = plotdata(recidx).probelabel;

  casesplotted = unique( [ casesplotted { caselabel } ] );
  probesplotted = unique( [ probesplotted { probelabel } ] );

  scratch = min(find(strcmp(caselabel, allcaselabels)));
  thiscolour = legendlutcase{scratch, 2};

  scratch = min(find(strcmp(probelabel, allprobelabels)));
  thislinetype = legendlutprobe{scratch, 3};
  thismarktype = legendlutprobe{scratch, 4};


  if strcmp(plottype, 'xy')
    plot( thisxseries, thisyseries, 'Color', thiscolour, ...
      'LineStyle', 'none', 'Marker', thismarktype, ...
      'MarkerSize', markersize, 'HandleVisibility', 'off' );
  elseif strcmp(plottype, 'line')
    plot( thisxseries, thisyseries, 'Color', thiscolour, ...
      'LineStyle', thislinetype, 'Marker', thismarktype, ...
      'MarkerSize', markersize, 'HandleVisibility', 'off' );
  end
end



%
% Add decorations.

if ismember('diag', decorations)
  plot( [minvaldiag maxvaldiag], [minvaldiag maxvaldiag], ...
    'Color', cols.gry, 'HandleVisibility', 'off' );
end

if ismember('hunity', decorations)
  plot( [minvalx maxvalx], [1 1], ...
    'Color', cols.gry, 'HandleVisibility', 'off' );
end

if ismember('hzero', decorations)
  plot( [minvalx maxvalx], [0 0], ...
    'Color', cols.gry, 'HandleVisibility', 'off' );
end



%
% Build the legend.
% Doing this per pair gets too big to display, so show cases and
% probes separately.

for cidx = 1:length(allcaselabels)
  if ismember(allcaselabels{cidx}, casesplotted)
    % Get all three elements (colour, line type, and marker) from the LUT.
    plot( NaN, NaN, 'Color', legendlutcase{cidx,2}, ...
      'LineStyle', legendlutcase{cidx,3}, ...
      'Marker', legendlutcase{cidx,4}, 'MarkerSize', markersize, ...
      'DisplayName', legendlutcase{cidx,5} );
  end
end

for pidx = 1:length(allprobelabels)
  if ismember(allprobelabels{pidx}, probesplotted)
    % Get all three elements (colour, line type, and marker) from the LUT.
    if strcmp(plottype, 'xy')
      % For XY, omit the line (line style 'none').
      plot( NaN, NaN, 'Color', legendlutprobe{pidx,2}, ...
        'LineStyle', 'none', ...
        'Marker', legendlutprobe{pidx,4}, 'MarkerSize', markersize, ...
        'DisplayName', legendlutprobe{pidx,5} );
    else
      % For line plots, include all three elements.
      plot( NaN, NaN, 'Color', legendlutprobe{pidx,2}, ...
        'LineStyle', legendlutprobe{pidx,3}, ...
        'Marker', legendlutprobe{pidx,4}, 'MarkerSize', markersize, ...
        'DisplayName', legendlutprobe{pidx,5} );
    end
  end
end



%
% Add annotations.

hold off;

title( figtitle );

xlabel( xtitle );
ylabel( ytitle );

if ~isempty(xticlabels)
  [ scratch xticlabels ] = euUtil_makeSafeStringArray( xticlabels );
  set( gca, 'XTick', 1:length(xticlabels), 'XTickLabel', xticlabels );
end

if ~isempty(yticlabels)
  [ scratch yticlabels ] = euUtil_makeSafeStringArray( yticlabels );
  set( gca, 'YTick', 1:length(yticlabels), 'YTickLabel', yticlabels );
end

if strcmp(plottype, 'xy')
  legend('Location', 'southeast');
else
  legend('Location', 'northeast');
end



%
% Axis limits depend on whether we have a log plot or a linear one.

% Minimum is already clamped; we're changing the maximum extents to leave
% space for the legend.

if strcmp(plottype, 'xy')
  % Use the joint minimum and maximum range, to keep diagonals diagonal.
  % FIXME - Only do this if both axes are numeric, not labels!
  if isempty(xticlabels) && isempty(yticlabels)
    minvalx = minvaldiag;
    minvaly = minvaldiag;
    maxvalx = maxvaldiag;
    maxvaly = maxvaldiag;
  end

  % XY plot has the X range padded.
  if want_x_log
    maxvalx = 4*maxvalx;
  else
    maxvalx = minvalx + 1.3*(maxvalx-minvalx);
  end
else
  % Line plot has the Y range padded.
  if want_y_log
    maxvaly = 4*maxvaly;
  else
    maxvaly = minvaly + 1.3*(maxvaly-minvaly);
  end
end

if want_x_log
  set(gca, 'xscale', 'log');
end
if want_y_log
  set(gca, 'yscale', 'log');
end

xlim([ minvalx maxvalx ]);
ylim([ minvaly maxvaly ]);



%
% Save the figure and clean up.

saveas(thisfig, outfile);

close(thisfig);



% Done.
end


%
% This is the end of the file.
