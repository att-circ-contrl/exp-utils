function euChris_plotResponseStatistics( ...
  statdata, global_filter, plotdefs, aggr_only, fnameprefix )

% function euChris_plotResponseStatistics( ...
%   statdata, global_filter, plotdefs, aggr_only, fnameprefix )
%
% This plots statistics for changes in extracted features induced by
% stimulation.
%
% "statdata" is a cell array containing stimulation response feature data
%   structures, per CHRISSTIMFEATURES.txt, including labels for
%   session/case/probe and (if plotted) channel indices/labels.
% "global_filter" is a structure array containing a filter list, per
%   nlUtil_pruneStructureList(). This is applied to "statdata" before plotting.
% "plotdefs" is a structure array with the following fields:
%   "label" is a filename-safe identifier for this plot definition.
%   "type" is 'xy', 'box', 'line', or 'timeheat'.
%   "xaxis" is the statdata field to use for the independent axis.
%   "xtitle" is the title to use for the independent axis.
%   "yaxis" is the statdata field to use for the dependent axis.
%   "ytitle" is the title to use for the dependent axis.
%   "titleprefix" is a prefix to use when building plot titles.
%   "titlesuffixes" is a cell array which may include the following:
%     'before' emits "NN ms Before" in the title.
%     'after' emits "NN ms After" in the title.
%   "decorations" is a cell array which may include the following:
%     'diag' draws a diagonal line (typically for XY plots).
%     'hunity' draws a horizontal line at Y=1 (typically for relative data).
%     'hzero' draws a horizontal line at Y=0 (typically for absolute data).
%   "caseblacklist" is a cell array with case labels to ignore.
%   "casewhitelist" is a cell array; only cases in this list are plotted. If
%     this is {}, all cases may be plotted (subject to the blacklist).
% "aggr_only" is true to suppress per-session plots (only plotting aggregate).
% "fnameprefix" is a prefix used when building output filenames.
%
% No return value.


% Magic values.

% Matlab default marker size is 6.
markersize = 4;


% Apply the global filter.

[ statdata ~ ] = nlUtil_pruneStructureList( statdata, global_filter );


% Bail out if we have no data.

if isempty(statdata)
  return;
end



%
% Augment the statistics data with plot-specific metadata.

% FIXME - Split out label extraction, and add merge-sub-session function.

[ statdata sessionlabels caselabels probelabels timelabels ...
  sessiontitles casetitles probetitles timetitles timevaluesms ] = ...
  euChris_stimFeaturesToRawPlotData_loop2302( statdata );


% Grab additional metadata that this doesn't collect.

% We know that we have at least one record.
% Window data should be consistent, so take it from the first record.

timebeforems = statdata{1}.winbefore * 1000;
% Remember to take the absolute value for the "before" time.
timebeforetitle = sprintf( '%d ms', round(abs(timebeforems)) );


% Get derived session, case, and probe metadata.

casecount = length(caselabels);
sessioncount = length(sessionlabels);
probecount = length(probelabels);
wincount = length(timevaluesms);

% Keys have to be valid structure field names, starting with a letter.
sessionkeys = nlUtil_sprintfCellArray( 'x%s', sessionlabels );



%
% Build palette and line style lookup tables.

cols = nlPlot_getColorPalette();

% Use +1 so that we don't actually use the +360 case.
casecols = nlPlot_getColorSpread( cols.red, casecount + 1, 360 );

% Get per-probe styles.
[ probelines probemarks ] = nlPlot_getLineMarkStyleSpread( probecount );

% Convert these into cell array lookup tables.

legendlutcase = cell(casecount,4);
legendlutcase(:,1) = caselabels(:);
legendlutcase(:,2) = casecols(1:casecount);
legendlutcase(:,3) = { '-' };
legendlutcase(:,4) = { 'none' };
legendlutcase(:,5) = casetitles(:);

legendlutprobe = cell(probecount,4);
legendlutprobe(:,1) = probelabels(:);
legendlutprobe(:,2) = { cols.blk };
legendlutprobe(:,3) = probelines(:);
legendlutprobe(:,4) = probemarks(:);
legendlutprobe(:,5) = probetitles(:);



%
% Get a scratch figure.

thisfig = figure();



%
% Walk through the requested plots.

% NOTE - We'll print per-session _and_ aggregated all-session plots.

for plotidx = 1:length(plotdefs)
  thisdef = plotdefs(plotidx);

  if ~ismember(thisdef.type, {'xy', 'box', 'line', 'timeheat'})
    disp([ '### Unrecognized plot type "' thisdef.type '" requested.' ]);
  else

    % Pre-filter the list.

    thisfilter = struct( 'srcfield', 'caselabel' );
    thisfilter.blacklist = thisdef.caseblacklist;
    thisfilter.whitelist = thisdef.casewhitelist;

    [ statsubset ~ ] = nlUtil_pruneStructureList( statdata, thisfilter );

    fieldswanted = { thisdef.xaxis thisdef.yaxis };

    [ statsubset ~ ] = ...
      nlUtil_confirmStructureFields( statsubset, fieldswanted );


    %
    % Get the cooked data list.

    cookeddata = euPlot_hlevRawPlotDataToCooked( statsubset, ...
      thisdef.xaxis, thisdef.yaxis );

    % Bail out if we have no data.
    if isempty(cookeddata)
      disp([ '.. Skipping plots for "' thisdef.label '" (no data).' ]);
      continue;
    end


    %
    % Compute plot ranges.

    % FIXME - We need to let the user choose whether to have consistent
    % ranges or per-session/per-case/per-probe ranges!

    % Special-case horizontal cursors.
    extravalsy = [];
    if ismember('hunity', thisdef.decorations)
      extravalsy = [ extravalsy 1 ];
    end
    if ismember('hzero', thisdef.decorations)
      extravalsy = [ extravalsy 0 ];
    end

    % NOTE - Ranging labels will give the supplied default. Setting that
    % to NaN lets us detect the default case and set it to auto-range.

    xrange = [];
    yrange = [];

    [ minvalx maxvalx ] = euPlot_getStructureSeriesRange( ...
      cookeddata, 'dataseriesx', [ NaN NaN ], [] );
    [ minvaly maxvaly ] = euPlot_getStructureSeriesRange( ...
      cookeddata, 'dataseriesy', [ NaN NaN ], extravalsy );

    if ~isnan(minvalx)
      xrange = [ minvalx maxvalx ];
    end
    if ~isnan(minvaly)
      yrange = [ minvaly maxvaly ];
    end


    %
    % Switch by plot type. This affects how we iterate.

    if strcmp(thisdef.type, 'xy') || strcmp(thisdef.type, 'line')

      % XY plot or line plot.

      % FIXME - Data might not be time-binned!

      for widx = 1:wincount
        windowmask = strcmp( timelabels{widx}, { cookeddata.timelabel } );

        % Per-session plots.

        if ~aggr_only
          for sidx = 1:sessioncount
            sessionmask = ...
              strcmp( sessionlabels{sidx}, { cookeddata.sessionlabel } );

            thiscooked = cookeddata( windowmask & sessionmask );

            if ~isempty(thiscooked)

              thistitle = [ thisdef.titleprefix plottitlesuffixes{widx} ...
                ' - ' sessiontitles{sidx} ];
              thisfname = [ fnameprefix '-' thisdef.label ...
                '-' sessionlabels{sidx} '-' timelabels{widx} '.png' ];

              euPlot_hlevPlotStatData2D( thiscooked, ...
                thisdef.type, thisdef.decorations, ...
                xrange, yrange, 'linear', 'linear', ...
                legendlutcase, legendlutprobe, ...
                thistitle, thisdef.xtitle, thisdef.ytitle, thisfname );

              if strcmp(thisdef.type, 'xy')
                % Emit another copy with log axes.

                thisfname = [ fnameprefix '-' thisdef.label ...
                  '-' sessionlabels{sidx} '-' timelabels{widx} '-log.png' ];

                euPlot_hlevPlotStatData2D( thiscooked, ...
                  thisdef.type, thisdef.decorations, ...
                  xrange, yrange, 'log', 'log', ...
                  legendlutcase, legendlutprobe, ...
                  thistitle, thisdef.xtitle, thisdef.ytitle, thisfname );
              end

            end
          end
        end

        % Aggregate plot across all sessions.

        thiscooked = cookeddata( windowmask );

        if ~isempty(thiscooked)

          thistitle = [ thisdef.titleprefix plottitlesuffixes{widx} ...
            ' - Aggregate' ];
          thisfname = [ fnameprefix '-' thisdef.label ...
            '-aggr-' timelabels{widx} '.png' ];

          euPlot_hlevPlotStatData2D( thiscooked, ...
            thisdef.type, thisdef.decorations, ...
            xrange, yrange, 'linear', 'linear', ...
            legendlutcase, legendlutprobe, ...
            thistitle, thisdef.xtitle, thisdef.ytitle, thisfname );

% FIXME - Emit log versions of line plots too.
% FIXME - Add a plot def "log, linear, or both" switch.
if true
%          if strcmp(thisdef.type, 'xy')
            % Emit another copy with log axes.

            thisfname = [ fnameprefix '-' thisdef.label ...
              '-aggr-' timelabels{widx} '-log.png' ];

            euPlot_hlevPlotStatData2D( thiscooked, ...
              thisdef.type, thisdef.decorations, ...
              xrange, yrange, 'log', 'log', ...
              legendlutcase, legendlutprobe, ...
              thistitle, thisdef.xtitle, thisdef.ytitle, thisfname );
          end

        end
      end  % for widx

      % End of XY plot or line plot.

    elseif strcmp(thisdef.type, 'timeheat')

      % Heat-map across time.

      % FIXME - Splitting by case, probe, and session.
      % We should accept plotdef parameters telling what to split by.
      % FIXME - We can't actually aggregate this! Aggregation has to
      % happen at a higher level, recalculating statistics.

      for sidx = 1:sessioncount
        sessionmask = ...
          strcmp( sessionlabels{sidx}, { cookeddata.sessionlabel } );

        for cidx = 1:casecount
          casemask = ...
            strcmp( caselabels{cidx}, { cookeddata.caselabel } );

          for pidx = 1:probecount
            probemask = ...
              strcmp( probelabels{pidx}, { cookeddata.probelabel } );

            thiscooked = cookeddata( sessionmask & casemask & probemask );

            if ~isempty(thiscooked)
              thistitle = [ thisdef.titleprefix ' - ' sessiontitles{sidx} ...
                ' - ' casetitles{cidx} ' - ' probetitles{pidx} ];
              thisfname = [ fnameprefix '-' thisdef.label ...
                '-' sessionlabels{sidx} '-' caselabels{cidx} ...
                '-' probelabels{pidx} '.png' ];

              euPlot_hlevPlotStatTimeHeatmap( thiscooked, ...
                [], xrange, yrange, 'linear', 'linear', 'linear', ...
                thistitle, 'Time (ms)', thisdef.xtitle, thisdef.ytitle, ...
                thisfname );
            end
          end

          % Make an all-probes plot, to test partial set handling.
% FIXME - Put the all-probes plot behind a switch for now.
if false

          thiscooked = cookeddata( sessionmask & casemask );

          if ~isempty(thiscooked)
            thistitle = [ thisdef.titleprefix ' - ' sessiontitles{sidx} ...
              ' - ' casetitles{cidx} ];
            thisfname = [ fnameprefix '-' thisdef.label ...
              '-' sessionlabels{sidx} '-' caselabels{cidx} '.png' ];

            euPlot_hlevPlotStatTimeHeatmap( thiscooked, ...
              [], xrange, yrange, 'linear', 'linear', 'linear', ...
              thistitle, 'Time (ms)', thisdef.xtitle, thisdef.ytitle, ...
              thisfname );
          end
end
        end  % for cidx
      end  % for sidx

      % End of heat-map across time.

    end



    %
    % First pass: Traverse the data records, filter them, sort them by
    % session, and store a serialized list.

% FIXME - Obsolete. Switch to cooked data and remove this.

% FIXME - Redo ranging, since this doesn't auto-range labels.

    % NOTE - Ranging labels will give []. This is fine; the plotting
    % function will auto-range them properly.
    % Set the default range to 0..n+1, to get sensible ranges for labels.
    [ minvalx maxvalx ] = euPlot_getStructureSeriesRange( ...
      cookeddata, 'dataseriesx', ...
      [ 0 (1 + length(cookeddata(1).dataseriesx)) ], [] );
    [ minvaly maxvaly ] = euPlot_getStructureSeriesRange( ...
      cookeddata, 'dataseriesy', ...
      [ 0 (1 + length(cookeddata(1).dataseriesy)) ], extravalsy );


    datalist = {};
    plottitlesuffixes = {};

    casesplotted = {};
    probesplotted = {};

    for widx = 1:wincount

      % Build this window's plot title.

      thissuffix = '';

      if ismember('before', thisdef.titlesuffixes)
        thissuffix = [ thissuffix ' ' timebeforetitle ' Before' ];
      end

      if ismember('after', thisdef.titlesuffixes)
        if ismember('before', thisdef.titlesuffixes)
          thissuffix = [ thissuffix ' and' ];
        end
        thissuffix = [ thissuffix ' ' timetitles{widx} ' After' ];
      end

      plottitlesuffixes{widx} = thissuffix;


      % Walk through the datasets.

      emptysession = struct( 'dataseriesx', {{}}, 'dataseriesy', {{}}, ...
        'cidx', [], 'pidx', [], 'sidx', [], ...
        'sessiontitle', 'undefined' );

      thiswindatalist = struct('aggr', emptysession);
      thiswindatalist.('aggr').('sessiontitle') = 'Aggregate';
      thiswindatalist.('aggr').('sessionlabel') = 'aggr';

      for didx = 1:length(statsubset)

        % Make note of the session, case, and probe.

        thiscase = statsubset{didx}.caselabel;
        cidx = find(strcmp(thiscase, caselabels));
        thisprobe = statsubset{didx}.probelabel;
        pidx = find(strcmp(thisprobe, probelabels));
        thissession = statsubset{didx}.sessionlabel;
        sidx = find(strcmp(thissession, sessionlabels));

        casesplotted = unique([ casesplotted { thiscase } ]);
        probesplotted = unique([ probesplotted { thisprobe } ]);

        thissessionkey = sessionkeys{sidx};


        % If this is a new session, initialize its data.

        if ~isfield(thiswindatalist, thissessionkey)
          thiswindatalist.(thissessionkey) = emptysession;
          thiswindatalist.(thissessionkey).('sessiontitle') = ...
            statsubset{didx}.sessiontitle;
          thiswindatalist.(thissessionkey).('sessionlabel') = ...
            thissession;
        end


        % Figure out what our X and Y data series look like.

        % Tolerate columns (for single time windows) and matrices (for
        % multiple time windows).
        % NOTE - Single labels are parsed as vectors of chars. Detect these.

        thisxseries = statsubset{didx}.(thisdef.xaxis);
        if (~iscolumn(thisxseries)) && (~isempty(thisxseries)) ...
          && (~ischar(thisxseries))
          thisxseries = thisxseries(:,widx);
        end

        thisyseries = statsubset{didx}.(thisdef.yaxis);
        if (~iscolumn(thisyseries)) && (~isempty(thisyseries)) ...
          && (~ischar(thisyseries))
          thisyseries = thisyseries(:,widx);
        end


        % Store set data in both the per-session and aggregate arrays.


        recidx = length( thiswindatalist.(thissessionkey).pidx );
        recidx = recidx + 1;

        thiswindatalist.(thissessionkey).dataseriesx{recidx} = thisxseries;
        thiswindatalist.(thissessionkey).dataseriesy{recidx} = thisyseries;
        thiswindatalist.(thissessionkey).cidx(recidx) = cidx;
        thiswindatalist.(thissessionkey).pidx(recidx) = pidx;
        thiswindatalist.(thissessionkey).sidx(recidx) = sidx;


        recidx = length( thiswindatalist.aggr.pidx );
        recidx = recidx + 1;

        thiswindatalist.aggr.dataseriesx{recidx} = thisxseries;
        thiswindatalist.aggr.dataseriesy{recidx} = thisyseries;
        thiswindatalist.aggr.cidx(recidx) = cidx;
        thiswindatalist.aggr.pidx(recidx) = pidx;
        thiswindatalist.aggr.sidx(recidx) = sidx;

      end

      datalist{widx} = thiswindatalist;

    end



    %
    % FIXME - Kludge. Get whisker ranges for box plots to prevent outliers
    % from making the rest of the plot tiny.

    boxymin = inf;
    boxymax = -inf;

    if strcmp(thisdef.type, 'box')
      for widx = 1:wincount
        thiswindatalist = datalist{widx};
        sessionkeylist = fieldnames(thiswindatalist);
        if aggr_only
          sessionkeylist = { 'aggr' };
        end

        for kidx = 1:length(sessionkeylist)
          thissessionkey = sessionkeylist{kidx};
          thissessiondata = thiswindatalist.(thissessionkey);

          % We have dataseriesx, dataseriesy, cidx, pidx, and sidx arrays.
          reccount = length(thissessiondata.pidx);


          % NOTE - Check to see if we had data.

          haddata = false;
          for recidx = 1:reccount
            if ~isempty(thissessiondata.dataseriesx{recidx})
              haddata = true;
            end
          end

          if haddata
            % Box plots.

            % "bins" are the cases (usually; field is read from 'xaxis').
            % "datasetlabels" are probes.
            % We're collapsing sessions and channels.

            boxvalues = [];
            boxcases = {};
            boxprobes = {};

            for recidx = 1:reccount
              thisxseries = thissessiondata.dataseriesx{recidx};
              thisyseries = thissessiondata.dataseriesy{recidx};
              cidx = thissessiondata.cidx(recidx);
              pidx = thissessiondata.pidx(recidx);
              sidx = thissessiondata.sidx(recidx);
              thiscase = caselabels{cidx};
              thisprobe = probelabels{pidx};
              thissession = sessionlabels{sidx};


              % The Y series is data. The X series is a single label.
              thislabel = thisxseries;

              % Make the Y series a row vector and add it to the box data
              % series.
              if ~isrow(thisyseries)
                thisyseries = transpose(thisyseries);
              end
              boxvalues = [ boxvalues thisyseries ];

              % Record X series labels.
              scratch = cell(size(thisyseries));
              scratch(:) = { thislabel };
              boxcases = [ boxcases scratch ];

              % FIXME - Hard-code probes as dataset labels.
              scratch = cell(size(thisyseries));
              scratch(:) = { thisprobe };
              boxprobes = [ boxprobes scratch ];
            end

            % Use cases as "bins" and probes as "datasets".
            % These are both cell arrays of character vectors, so we can use
            % strcmp on them.

            % For each unique case/probe combination, get the data range.

            scratchcases = unique(boxcases);
            scratchprobes = unique(boxprobes);

            for cidx = 1:length(scratchcases)
              thiscase = scratchcases{cidx};
              casemask = strcmp(boxcases, thiscase);
              for pidx = 1:length(scratchprobes)
                thisprobe = scratchprobes{pidx};
                probemask = strcmp(boxprobes, thisprobe);

                thisdata = boxvalues(casemask & probemask);
                % This is the same outlier algorithm called by boxchart.
                outliermask = isoutlier(thisdata, 'quartile');
                thisdata = thisdata(~outliermask);

                boxymin = min(boxymin, min(thisdata));
                boxymax = max(boxymax, max(thisdata));
              end
            end

          end
        end
      end

      if (~isfinite(boxymin)) || (~isfinite(boxymax))
        boxymin = 0;
        boxymax = 1;
      end

      % Account for the cursor at y=1.
      boxymax = max(1,boxymax);
      boxymin = min(1,boxymin);

      boxyfloor = min(0,boxymin);
    end



    %
    % Second pass: Make plots that don't include time.

    for widx = 1:wincount
      thiswindatalist = datalist{widx};
      sessionkeylist = fieldnames(thiswindatalist);

      if aggr_only
        sessionkeylist = { 'aggr' };
      end

      for kidx = 1:length(sessionkeylist)
        thissessionkey = sessionkeylist{kidx};
        thissessiondata = thiswindatalist.(thissessionkey);
        thissessiontitle = thissessiondata.sessiontitle;
        thissessionlabel = thissessiondata.sessionlabel;

        % We have dataseriesx, dataseriesy, cidx, pidx, and sidx arrays.
        reccount = length(thissessiondata.pidx);


        % NOTE - Check to see if we had data.

        haddata = false;
        for recidx = 1:reccount
          if ~isempty(thissessiondata.dataseriesx{recidx})
            haddata = true;
          end
        end

        if ~haddata
          % thisdef.titleprefix and thissessiontitle are human-readable
          % but not particularly informative.
          % thisdef.label and thissessionlabel are filename labels that are
          % cryptic but more informative.
          disp([ '.. Skipping plots for "' thisdef.label '-' ...
            thissessionlabel '" (no data).' ]);
          continue;
        end


        if strcmp(thisdef.type, 'box')

          % Box plots.
          % Call the helper function for this.

          % "bins" are the cases (usually; field is read from 'xaxis').
          % "datasetlabels" are probes.
          % We're collapsing sessions and channels.

          boxvalues = [];
          boxcases = {};
          boxprobes = {};

          for recidx = 1:reccount
            thisxseries = thissessiondata.dataseriesx{recidx};
            thisyseries = thissessiondata.dataseriesy{recidx};
            cidx = thissessiondata.cidx(recidx);
            pidx = thissessiondata.pidx(recidx);
            sidx = thissessiondata.sidx(recidx);
            thiscase = caselabels{cidx};
            thisprobe = probelabels{pidx};
            thissession = sessionlabels{sidx};


            % The Y series is data. The X series is a single label.
            thislabel = thisxseries;

            % Make the Y series a row vector and add it to the box data series.
            if ~isrow(thisyseries)
              thisyseries = transpose(thisyseries);
            end
            boxvalues = [ boxvalues thisyseries ];

            % Record X series labels.
            scratch = cell(size(thisyseries));
            scratch(:) = { thislabel };
            boxcases = [ boxcases scratch ];

            % FIXME - Hard-code probes as dataset labels.
            scratch = cell(size(thisyseries));
            scratch(:) = { thisprobe };
            boxprobes = [ boxprobes scratch ];
          end

          % Use cases as "bins" and probes as "datasets".

          hcursorlist = {};
          if ismember('hunity', thisdef.decorations)
            hcursorlist = [ hcursorlist {{ 1, cols.gry, '' }} ];
          end
          if ismember('hzero', thisdef.decorations)
            hcursorlist = [ hcursorlist {{ 0, cols.gry, '' }} ];
          end

          % NOTE - We computed box-specific ranges that don't include
          % outliers.

          euPlot_plotMultipleBoxCharts( ...
            boxvalues, boxcases, boxprobes, ...
            'linear', 'linear', [], ...
            [ boxyfloor (boxyfloor + 1.2*(boxymax-boxyfloor)) ], ...
            thisdef.xtitle, thisdef.ytitle, false, 0.5, ...
            {}, hcursorlist, 'northeast', ...
            [ thisdef.titleprefix plottitlesuffixes{widx} ...
              ' - ' thissessiontitle ], ...
            [ fnameprefix '-' thisdef.label '-' thissessionlabel ...
              '-' timelabels{widx} '.png' ] );

        end
      end
    end



    % Finished making plots.

  end
end


% Dispose of the scratch figure.
close(thisfig);


% Done.
end


%
% This is the end of the file.
