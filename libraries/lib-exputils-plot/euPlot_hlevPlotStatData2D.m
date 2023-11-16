function euPlot_hlevPlotStatData2D( plotdata, plottype, decorations, ...
  xrange, yrange, loglin, legendlutcase, legendlutprobe, ...
  figtitle, xtitle, ytitle, outfile )

% function euPlot_hlevPlotStatData2D( plotdata, plottype, decorations, ...
%   xrange, yrange, loglin, legendlutcase, legendlutprobe, ...
%   figtitle, xtitle, ytitle, outfile )
%
% This renders cooked plot data to an XY plot or a line plot.
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
%   only log for XY plots.
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
% Get ranges.

if isempty(xrange)
  % Default to 0..n+1, to get sensible ranges for labels.
  defaultrange = [ 0 (1 + length(plotdata(1).dataseriesx)) ];
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
  extravalsy = [];
  if ismember('hunity', decorations)
    extravalsy = [ extravalsy 1 ];
  end
  if ismember('hzero', decorations)
    extravalsy = [ extravalsy 0 ];
  end

  % Default to 0..n+1, to get sensible ranges for labels.
  defaultrange = [ 0 (1 + length(plotdata(1).dataseriesy)) ];
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
minvalxy = min(minvalx, minvaly);
maxvalxy = max(maxvalx, maxvaly);

% Tweak plot foor location.
minvaly = min(0, minvaly);
minvalxy = min(0, minvalxy);

% Clamp for logscale plots.
if strcmp(loglin, 'log')
  minvalx = 0.01 * maxvalx;
  minvaly = 0.01 * maxvaly;
  minvalxy = 0.01 * maxvalxy;
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
  % The X series might be channel indices; that's ok.

  thisxseries = plotdata(recidx).dataseriesx;
  thisyseries = plotdata(recidx).dataseriesy;


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
  plot( [minvalxy maxvalxy], [minvalxy maxvalxy], ...
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

if strcmp(plottype, 'xy')
  legend('Location', 'southeast');
else
  legend('Location', 'northeast');
end



%
% Axis limits depend on whether we have a log plot or a linear one.

% Minimum is already clamped; we're changing the maximum extents to leave
% space for the legend.

if strcmp(loglin, 'log')
  set(gca, 'xscale', 'log');
  set(gca, 'yscale', 'log');

  if strcmp(plottype, 'xy')
    xlim([ minvalxy 4*maxvalxy ]);
    ylim([ minvalxy maxvalxy ]);
  else
    xlim([ minvalx maxvalx ]);
    ylim([ minvaly 4*maxvaly ]);
  end
else
  if strcmp(plottype, 'xy')
    xlim([ minvalxy (minvalxy + 1.3*(maxvalxy-minvalxy)) ]);
    ylim([ minvalxy maxvalxy ]);
  else
    xlim([ minvalx maxvalx ]);
    ylim([ minvaly (minvaly + 1.3*(maxvaly-minvaly)) ]);
  end
end



%
% Save the figure and clean up.

saveas(thisfig, outfile);

close(thisfig);



% Done.
end


%
% This is the end of the file.
