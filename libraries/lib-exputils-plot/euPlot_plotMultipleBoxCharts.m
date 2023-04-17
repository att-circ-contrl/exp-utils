function euPlot_plotMultipleBoxCharts( ...
  datavalues, databinvalues, datasetlabels, ...
  xtype, ytype, xrange, yrange, xstr, ystr, wantoutliers, boxwidth, ...
  plotlines, plothcursors, legendpos, titlestr, fname )

% function euPlot_plotMultipleBoxCharts( ...
%   datavalues, databinvalues, datasetlabels, ...
%   xtype, ytype, xrange, yrange, xstr, ystr, wantoutliers, boxwidth, ...
%   plotlines, plothcursors, legendpos, titlestr, fname )
%
% This creates a box plot showing several data series and data sets.
%
% Data is provided as one vector, which may be several concatenated datasets.
% Each sample has a "bin value" (a scalar number) and a "dataset label" (a
% character vector). Samples with the same "dataset label" are in the same
% dataset; each dataset gets its own colour. Each distinct "bin value" gets
% its own box in the plot; bin values are arranged on the X axis.
%
% "datavalues" is a vector with the Y axis data values to plot.
% "databinvalues" is a vector with per-sample X axis data values for each
%   sample in "datavalues". Use [] to not sort by bin.
% "datasetlabels" is a cell array with per-sample dataset labels for each
%   sample in "datavalues"; different datasets get different colours. Use {}
%   to not sort by dataset.
% "xtype" is 'linear' or 'log'.
% "ytype" is 'linear' or 'log'.
% "xrange" is the X axis range, or [] to auto-range.
% "yrange" is the Y axis range, or [] to auto-range.
% "xstr" is a character vector with the X axis label.
% "ystr" is a character vector with the Y axis label.
% "wantoutliers" is true to plot outlier dots and false otherwise.
% "boxwidth" is the box width ("boxchart" uses 0.5 as the default).
% "plotlines" is a cell array containing line definitions to plot. Each
%   line definition is a cell array with the form:
%   { x1 y1 x2 y2 colour label } ...If "label" is '', no legend line is shown.
% "plothcursors" is a cell array containing horizontal cursor definitions to
%   plot. Each horizontal cursor definition is a cell array with the form:
%   { yval colour label } ...If "label" is '', no legend line is shown.
% "legendpos" is the legend location showing set labels ('off' to disable).
% "titlestr" is a character vector with the plot title.
% "fname" is the filename to save the plot to.

  thisfig = figure();
  figure(thisfig);
  clf('reset');


  % Figure out if we're separating bins or datasets.

  have_by_bin = ~isempty(databinvalues);
  have_by_set = ~isempty(datasetlabels);


  % Call "boxchart" one or more times.

  % If we have bins but no datasets, make one call. All of the boxes are the
  % same colour.

  % We have datasets but no bins, we still have to make multiple calls
  % manually to get our desired colour palette.

  % If we have datasets _and_ bins, make multiple calls manually, and perturb
  % the bin values by an appropriate fraction of the box width on each call.
  % Use a legend to show the different datasets.

  % Using "GroupByColor" gives really bad placement, so we have to do this
  % manually. It also forces a default colour palette.


  if have_by_set
    setlabels = unique(datasetlabels);
    setcount = length(setlabels);
    % Use brighter/more sturated colours.
    setcolours = nlPlot_getColorSpread( [ 0.9 0 0 ], setcount, 240 );

    setoffsets = 0;
    gapcount = setcount - 1;
    if gapcount > 0
      setoffsets = 0:gapcount;
      setoffsets = (setoffsets / gapcount) - 0.5;
    end

    setoffsets = setoffsets * boxwidth;
    if setcount > 1
      boxwidth = boxwidth / setcount;
      boxwidth = boxwidth * 0.9;
    end
  end


  % Render the box plots.

  if have_by_set

    % One plot per dataset.
    % If we have no bins, use dataset labels.
    % If we have both bins and datasets, use a legend.

    hold on;

    for cidx = 1:setcount

      thislabel = setlabels{cidx};
      thiscol = setcolours{cidx};

      thismask = strcmp(datasetlabels, thislabel);
      thisdata = datavalues(thismask);

      if have_by_bin
        thisbinvalues = databinvalues(thismask);
        thisbinvalues = thisbinvalues + setoffsets(cidx);
      else
        thisbinvalues = {};
        thisbinvalues(1:length(thisdata)) = { thislabel };
        thisbinvalues = categorical(thisbinvalues);
      end

      if wantoutliers
        boxchart( thisbinvalues, thisdata, 'Boxwidth', boxwidth, ...
          'BoxFaceColor', thiscol, 'MarkerColor', thiscol, ...
          'DisplayName', thislabel, ...
          'Markerstyle', '.', 'JitterOutliers', 'on' );
      else
        boxchart( thisbinvalues, thisdata, 'Boxwidth', boxwidth, ...
          'BoxFaceColor', thiscol, 'DisplayName', thislabel, ...
          'Markerstyle', 'none' );
      end

    end

    hold off;

  else

    % No datasets; just one plot, with numeric bin values.

    if ~have_by_bin
      % Internally we get ordinal values (or a single value of "1") by
      % default, so just do that manually here.
      databinvalues = ones(size(datavalues));
    end

    if wantoutliers
      boxchart( databinvalues, datavalues, 'Boxwidth', boxwidth, ...
        'Markerstyle', '.', 'JitterOutliers', 'on' );
    else
      boxchart( databinvalues, datavalues, 'Boxwidth', boxwidth, ...
        'Markerstyle', 'none' );
    end

  end


  % If we were asked for lines or cursors, draw them.

  hold on;


  % Figure out what our X limits are, and whether we have a categorical axis.

  axis_is_categories = have_by_set && (~have_by_bin);

  % If we have no size information at all, we're centered on 1.
  xmin = 0;
  xmax = 2;

  if have_by_bin
    if isempty(xrange)
      % Span the data bin range, plus a bit.

      xmin = min(databinvalues);
      xmax = max(databinvalues);

      xpad = 1;
      if xmax > xmin
        xpad = 0.1 * (xmax - xmin);
        xmin = xmin - xpad;
        xmax = xmax + xpad;
      end
    else
      % Span the plot range.
      xmin = min(xrange);
      xmax = max(xrange);
    end
  elseif axis_is_categories
    % Our values are categorical, not numeric.
    setcats = categorical(datasetlabels);
    xmin = setcats(1);
    xmax = setcats(length(setcats));
  end


  % Draw lines if we're _not_ categorical.

  if ~axis_is_categories
    for lidx = 1:length(plotlines)
      thislinedef = plotlines{lidx};

      thisxseries = [ thislinedef{1} thislinedef{3} ];
      thisyseries = [ thislinedef{2} thislinedef{4} ];
      thiscol = thislinedef{5};
      thislabel = thislinedef{6};

      if isempty(thislabel)
        plot( thisxseries, thisyseries, 'Color', thiscol, ...
          'HandleVisibility', 'off' );
      else
        plot( thisxseries, thisyseries, 'Color', thiscol, ...
          'DisplayName', thislabel );
      end
    end
  end

  % Draw horizontal cursors no matter what.

  for lidx = 1:length(plothcursors)
    thislinedef = plothcursors{lidx};

    thisxseries = [ xmin xmax ];
    thisyseries = [ thislinedef{1} thislinedef{1} ];
    thiscol = thislinedef{2};
    thislabel = thislinedef{3};

    if isempty(thislabel)
      plot( thisxseries, thisyseries, 'Color', thiscol, ...
        'HandleVisibility', 'off' );
    else
      plot( thisxseries, thisyseries, 'Color', thiscol, ...
        'DisplayName', thislabel );
    end
  end


  % Finished with lines and cursors.

  hold off;


  % Set up axes and add decorations.

  if have_by_bin && (~isempty(xrange))
    xlim(xrange);
  else
    xlim('auto');
  end
  if ~isempty(yrange)
    ylim(yrange);
  else
    ylim('auto');
  end

  if have_by_bin && strcmp(xtype, 'log');
    set(gca, 'xscale', 'log');
  end
  if strcmp(ytype, 'log');
    set(gca, 'yscale', 'log');
  end

  if have_by_set && (~strcmp(legendpos, 'off'))
    legend('Location', legendpos);
  else
    legend('off');
  end

  title(titlestr);
  xlabel(xstr);
  ylabel(ystr);

  saveas(thisfig, fname);

  close(thisfig);
end



%
% This is the end of the file.
