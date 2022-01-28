function doPlotTimeStats( obase, tabstruct, misslabels, ...
  timelabelstruct, shiftlabelstruct, jitterzoom )

% function doPlotTimeStats( obase, tabmatch, taball, ...
%   misstabstruct, timelabelstruct, shiftlabelstruct, jitterzoom )
%
% This function generates several plots and statistics related to event
% timing.
%
% NOTE - Time is assumed to be in seconds, for purposes of precision and
% labels.
%
% "obase" is the prefix to use when constructing plot filenames.
% "tabstruct" is a structure containing tables with data tuples for
%   events from various source lists. Structure field names are file labels
%   to use for the contained tables.
% "misslabels" is a cell array containing field names in "tabstruct" that
%   correspond to "missed" events. These get a different set of plots.
% "timelabelstruct" is a structure containing the names of table columns that
%   have time data to be plotted. Structure field names are file labels to
%   use when plotting times taken from the corresponding columns.
% "shiftlabelstruct" is a structure with field names that are file labels
%   to use when plotting alignment shifts. Each field contains a structure
%   with a "timelabel" field (containing the column name to read time series
%   data from) and a "deltalabel" field (containing the column name to read
%   alignment time-shifts from).
% "jitterzoom" is the radius of the window to plot jitter details in, in
%   standard deviations. Typical values are 2-4.


tablabels = fieldnames(tabstruct);
timelabels = fieldnames(timelabelstruct);
shiftlabels = fieldnames(shiftlabelstruct);

scratchfig = figure();


% Walk through the list of data tables to plot.

for tabidx = 1:length(tablabels)

  thistablabel = tablabels{tabidx};
  thistab = tabstruct.(thistablabel);

  if ismember(thistablabel, misslabels)

    % This is a list of "missed" events.
    % We want to generate histograms of when these happened.

    % Walk through the time series list.
    for timeidx = 1:length(timelabels)
      % Get metadata.
      thistimelabel = timelabels{timeidx};
      thistimecol = timelabelstruct.(thistimelabel);

      helper_plotEventTimes( thistab.(thistimecol), scratchfig, ...
        sprintf('%s time for "%s" misses', thistimelabel, thistablabel), ...
        sprintf('%s-times-%s-%s.png', obase, thistablabel, thistimelabel) );
    end

  else

    % This is an ordinary event list.
    % Plot time drift and jitter statistics.

    % Walk through the time-shift list.
    for shiftidx = 1:length(shiftlabels)

      % Get metadata.
      thisshiftlabel = shiftlabels{shiftidx};
      thisshiftentry = shiftlabelstruct.(thisshiftlabel);
      thistimecol = thisshiftentry.timelabel;
      thisdeltacol = thisshiftentry.deltalabel;

      % Generate drift and jitter statistics.
      helper_reportStats( ...
        thistab.(thistimecol), thistab.(thisdeltacol), ...
        sprintf('%s-stats-%s-%s.txt', obase, thistablabel, thisshiftlabel) );

      % Generate time-shift plots.
      helper_plotTimeShift( ...
        thistab.(thistimecol), thistab.(thisdeltacol), ...
        jitterzoom, scratchfig, ...
        sprintf('%s for "%s" events', thisdeltacol, thistablabel), ...
        sprintf('%s-shift-%s-%s', obase, thistablabel, thisshiftlabel) );

    end

  end

end


close(scratchfig);


% Done.

end


%
% Helper functions.


% This computes alignment/drift/jitter, and also 7-figure stats for
% jitter after first-order (ramp) and second-order (bow) fitting.
%
% "timeseries" is a sequence of event time values.
% "deltaseries" is a sequence of alignment time-shift values.
% "fname" is the name of the text file to write to.

function helper_reportStats(timeseries, deltaseries, fname)

  % Only perform fits if we have at least 3 data points.

  if length(timeseries) >= 3

    % Get ramp fit.

    lincoeffs = polyfit(timeseries, deltaseries, 1);
    linvals = polyval(lincoeffs, timeseries);
    linresidue = deltaseries - linvals;

    rampcoeff = lincoeffs(1);
    constcoeff = lincoeffs(2);

    % Get quadratic fit.

    quadcoeffs = polyfit(timeseries, deltaseries, 2);
    quadvals = polyval(quadcoeffs, timeseries);
    quadresidue = deltaseries - quadvals;


    % Try to open the output file.

    fid = fopen(fname, 'w');
    if fid < 0
      disp(sprintf( '### Unable to write to "%s".', fname ));
    else

      % Compute and report stats.
      % FIXME - Assuming seconds!

      % General statistics.
      fprintf( fid, ...
        'Mean align %.4f s, drift %.1f ppm, jitter %.3f ms.\n', ...
        constcoeff, rampcoeff * 1e6, std(linresidue) * 1e3 );

      % 7-figure summary for line fit.
      fprintf( fid, 'Line fit jitter stats (deviation from ramp):\n' );
      percvec = 1e3 * prctile(linresidue, [ 2 9 25 50 75 91 98 ]);
      fprintf( fid, ...
        '  %.2f / %.2f / %.2f / [ %.2f ] / %.2f / %.2f / %.2f\n', ...
        percvec(1), percvec(2), percvec(3), percvec(4), ...
        percvec(5), percvec(6), percvec(7) );

      % 7-figure summary for quadratic fit.
      fprintf( fid, 'Quadratic fit jitter stats (deviation from bow):\n' );
      percvec = 1e3 * prctile(quadresidue, [ 2 9 25 50 75 91 98 ]);
      fprintf( fid, ...
        '  %.2f / %.2f / %.2f / [ %.2f ] / %.2f / %.2f / %.2f\n', ...
        percvec(1), percvec(2), percvec(3), percvec(4), ...
        percvec(5), percvec(6), percvec(7) );

      % Finished with this file.
      fclose(fid);

    end

  end

end


% This plots time shift vs time, and a histogram of time jitter.
%
% "timeseries" is a sequence of event time values.
% "deltaseries" is a sequence of alignment time-shift values.
% "thisfig" is a figure handle to use for plotting.
% "caselabel" is a string to annotate the plot title with.
% "fbase" is a prefix to use when building plot filenames.

function helper_plotTimeShift( timeseries, deltaseries, coredeviations, ...
  thisfig, caselabel, fbase )

  % Select this figure.
  figure(thisfig);


  % FIXME - Configuration.
  % Polynomial fit order. Usually this is 1 (ramp) or 2 (bow).
  fitorder = 1;


  % Only make plots if we have at least two data points.
  if length(timeseries) >= 2

    % Plot time shift against time.

    clf('reset');

    plot(timeseries, deltaseries, 'HandleVisibility', 'off');

    title(sprintf('Time Shift (%s)', caselabel));
    xlabel('Time (s)');
    ylabel('Time Shift (s)');

    saveas(thisfig, sprintf('%s-plot.png', fbase));


    % Calculate a fit and the fit residue.
    % This is usually a ramp fit (first-order) or bow (second-order).

    fitcoeffs = polyfit(timeseries, deltaseries, fitorder);
    fitvals = polyval(fitcoeffs, timeseries);
    deltaresidue = deltaseries - fitvals;
    deltaresidue = 1e3 * deltaresidue;

    % Get a rough idea of the residue's spread.
    residuemean = mean(deltaresidue);
    residuedev = std(deltaresidue);
    coremin = residuemean - coredeviations * residuedev;
    coremax = residuemean + coredeviations * residuedev;


    % Plot the fit residue against time.

    clf('reset');

    plot(timeseries, deltaresidue, 'HandleVisibility', 'off');

    ylim([ coremin coremax ]);

    title(sprintf('Time Shift Fit Residue (%s)', caselabel));
    xlabel('Time (s)');
    ylabel('Time Shift Residue (ms)');

    saveas(thisfig, sprintf('%s-residue.png', fbase));


    % Plot time shift jitter.
    % FIXME - Assume there are outliers, and make two plots.

    coreselect = (deltaresidue <= coremax) & (deltaresidue >= coremin);
    residuecore = deltaresidue(coreselect);
    residueoutliers = deltaresidue(~coreselect);


    if ~isempty(residuecore)
      clf('reset');

      histogram(residuecore, 100);

      xlim([ coremin coremax ]);

      title(sprintf('Time Shift Jitter Detail (%s)', caselabel));
      xlabel('Time Shift Jitter (ms)');
      ylabel('Count');

      saveas(thisfig, sprintf('%s-jitter-core.png', fbase));
    end

    if ~isempty(residueoutliers)
      clf('reset');

      histogram(residueoutliers, 100);

      title(sprintf('Time Shift Jitter Outliers (%s)', caselabel));
      xlabel('Time Shift Jitter (ms)');
      ylabel('Count');

      saveas(thisfig, sprintf('%s-jitter-outliers.png', fbase));
    end

  end


  % Reset this figure to free up plot-related memory.
  clf('reset');

end


% This plots a histogram of event arrival times.
% It's intended to map the locations of "miss" events.
%
% "timeseries" is a sequence of event time values.
% "thisfig" is a figure handle to use for plotting.
% "caselabel" is a string to annotate the plot title with.
% "fname" is the name to use for the rendered figure file.

function helper_plotEventTimes( timeseries, thisfig, caselabel, fname )

  % Select this figure.
  figure(thisfig);


  % Only make plots if we have at least two data points.
  if length(timeseries) >= 2

    % Plot a histogram of event arrival times.

    clf('reset');

    histogram(timeseries, 100);

    title(sprintf('Event Times (%s)', caselabel));
    xlabel('Time (s)');
    ylabel('Count');

    saveas(thisfig, fname);

  end


  % Reset this figure to free up plot-related memory.
  clf('reset');

end



%
% This is the end of the file.
