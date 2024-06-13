function reportmsg = euHLev_reportTimeAlignment( timetables, fileprefix )

% function reportmsg = euHLev_reportTimeAlignment( timetables, fileprefix )
%
% This reports statistics about time alignments, and optionally makes plots.
%
% "timetables" is a structure containing several tables whose rows contain
%   corresponding timestamps from different devices (per TIMETABLES.txt).
% "fileprefix" is a prefix for generating plot filenames, or '' to not plot.
%
% "reportmsg" is a character vector containing a human-readable statistics
%   summary.


% Banner.
newline = sprintf('\n');
reportmsg = [ '-- Time alignment report:' newline ];


% Magic values.

columnprioritylist = { 'recTime', 'stimTime', 'unityTime' };

% Order for main curve fit.
fitorder = 1;
% Order for "get rid of bowing" fit.
boworder = 4;

% Outlier rejection for curve fitting.
if true
  outlierwindow = 30.0;
  outliersigma = 2.0;
else
  outlierwindow = NaN;
  outliersigma = NaN;
end

% NaN out the outliers when plotting; they'll still be in statistics.
want_nan_outliers = false;

want_tattle_outliers = false;

want_plots = ~isempty(fileprefix);


% Plotting setup.

% Set this to [] to not plot a zoomed figure.
zoomrange = [];
%zoomrange = [100 130];
%zoomrange = [2100 2130];

cols = nlPlot_getColorPalette();

if want_plots
  thisfig = figure();
  figure(thisfig);
end


% Walk through the tables.

tablist = fieldnames(timetables);

for tidx = 1:length(tablist)

  thistablabel = tablist{tidx};
  thistab = timetables.(thistablabel);

  columnlist = sort( thistab.Properties.VariableNames );
  columncount = length(columnlist);

  % Bail out if we have fewer than two columns.
  if columncount < 2
    continue;
  end


  % Figure out what our reference column is.
  % There are usually two columns, but tolerate more than two.

  colpriorities = NaN(size(columnlist));
  for cidx = 1:columncount
    thiscol = columnlist{cidx};
    thispriority = strcmp(thiscol, columnprioritylist);
    if any(thispriority)
      colpriorities(cidx) = min(find(thispriority));
    end
  end

  bestcol = columnlist{1};
  if any(~isnan(colpriorities))
    % This ignores NaN.
    scratch = min(colpriorities);
    bestcol = columnprioritylist{scratch};
  end


  % Make the report, and optionally make plots.

  firsttimes = thistab.(bestcol);

  for cidx = 1:columncount
    thiscol = columnlist{cidx};
    if ~strcmp(thiscol, bestcol)

      secondtimes = thistab.(thiscol);

      % Mean and drift should be the same no matter what the order, but
      % keep the ones from the standard fit, not bow-reduction fit.

      [ meandelta driftppm jitterbow polycoeffsbow residuebow outmask ] = ...
        nlProc_getTimingStats( firsttimes, secondtimes, boworder, ...
          outlierwindow, outliersigma );

      if want_nan_outliers
        residuebow(outmask) = NaN;
      end

      [ meandelta driftppm jitterlin polycoeffslin residuelin outmask ] = ...
        nlProc_getTimingStats( firsttimes, secondtimes, fitorder, ...
          outlierwindow, outliersigma );

      if want_nan_outliers
        residuelin(outmask) = NaN;
      end

      % Only tattle once, since both curve fits get the same outlier mask.
      if want_tattle_outliers
        disp(sprintf( '.. Flagged %d of %d residue samples as outliers.', ...
          sum(outmask), length(outmask) ));
      end

      reportmsg = [ reportmsg sprintf( ...
        [ '.. %s and %s:   dt %.1f s,  drift %d ppm,  ' ...
          'jitter %.1f (%.2f) ms\n' ], ...
        bestcol, thiscol, meandelta, round(driftppm), ...
        jitterlin * 1000, jitterbow * 1000 ) ];


      if want_plots

        % Convert the residue to milliseconds.
        residuelin = residuelin * 1000;
        residuebow = residuebow * 1000;

        % Get a time series for the residue and subtract the start time.
        residuetime = firsttimes - firsttimes(1);


        %
        % Histogram plots.


        % FIXME - Getting histogram extents by black magic.
        edgelist = nlProc_guessBinEdges( residuelin );

        clf('reset');

        histogram(residuelin, edgelist);

        xlabel('Time Error (ms)');
        ylabel('Count');

        legend('off');

        title([ 'Jitter (linear) - ' bestcol ' and ' thiscol ]);

        saveas(thisfig, ...
          [ fileprefix '-jitterlin-' bestcol '-' thiscol '.png' ]);


        % FIXME - Getting histogram extents by black magic.
        edgelist = nlProc_guessBinEdges( residuebow );

        clf('reset');

        histogram(residuebow, edgelist);

        xlabel('Time Error (ms)');
        ylabel('Count');

        legend('off');

        title([ 'Jitter (poly) - ' bestcol ' and ' thiscol ]);

        saveas(thisfig, ...
          [ fileprefix '-jitterpoly-' bestcol '-' thiscol '.png' ]);


        %
        % Residue line plots.


        clf('reset');

        plot(residuetime, residuelin, 'HandleVisibility', 'off');

        xlabel('Time (sec)');
        ylabel('Time Error (ms)');

        legend('off');

        title([ 'Residue (linear) - ' bestcol ' and ' thiscol ]);

        saveas(thisfig, ...
          [ fileprefix '-residuelin-' bestcol '-' thiscol '.png' ]);

        if ~isempty(zoomrange)
          xlim(zoomrange);
          saveas(thisfig, ...
            [ fileprefix '-residuelin-' bestcol '-' thiscol '-zoom.png' ]);
        end


        clf('reset');

        plot(residuetime, residuebow, 'HandleVisibility', 'off');

        xlabel('Time (sec)');
        ylabel('Time Error (ms)');

        legend('off');

        title([ 'Residue (poly) - ' bestcol ' and ' thiscol ]);

        saveas(thisfig, ...
          [ fileprefix '-residuepoly-' bestcol '-' thiscol '.png' ]);

        if ~isempty(zoomrange)
          xlim(zoomrange);
          saveas(thisfig, ...
            [ fileprefix '-residuepoly-' bestcol '-' thiscol '-zoom.png' ]);
        end

      end

    end
  end

end


% Finished plotting.

if want_plots
  close(thisfig);
end


% Banner.
reportmsg = [ reportmsg '-- End of report.' newline ];


% Done.
end


%
% This is the end of the file.
