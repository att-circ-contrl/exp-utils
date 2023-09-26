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
%   "type" is 'xy', 'box', or 'line'.
%   "xaxis" is the statdata field to use for the X axis.
%   "xtitle" is the title to use for the X axis.
%   "yaxis" is the statdata field to use for the Y axis.
%   "ytitle" is the title to use for the Y axis.
%   "titleprefix" is a prefix to use when building plot titles.
%   "titlesuffixes" is a cell array which may include the following:
%     'before' emits "NN ms Before" in the title.
%     'after' emits "NN ms After" in the title.
%   "decorations" is a cell array which may include the following:
%     'diag' draws a diagonal line (typically for XY plots).
%     'hunity' draws a horizontal line at Y=1 (typically for relative data).
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



%
% Get metadata and annotation strings.

datameta = euChris_getResponseDataMetadata( statdata, ...
  { 'caselabel', 'probelabel', 'sessionlabel' } );

% Copy to local variables for convenience.

wincount = length(datameta.winafter);

notebefore = datameta.winbeforetext;
notesafter = datameta.winaftertext;
labelsafter = datameta.winafterlabels;

allcases = datameta.labelraw.caselabel;
allsessions = datameta.labelraw.sessionlabel;
allprobes = datameta.labelraw.probelabel;

casecount = length(allcases);
sessioncount = length(allsessions);
probecount = length(allprobes);

legendcasetext = datameta.labeltext.caselabel;
legendprobetext = datameta.labeltext.probelabel;

sessiontitletext = datameta.labeltext.sessionlabel;
sessionlabeltext = datameta.labelshort.sessionlabel;
sessionkeys = datameta.labelkey.sessionlabel;



%
% Build palette and line style lookup tables.

cols = nlPlot_getColorPalette();

% Use +1 so that we don't actually use the +360 case.
casecols = nlPlot_getColorSpread( cols.red, casecount + 1, 360 );

% Get per-probe styles.
[ probelines probemarks ] = nlPlot_getLineMarkStyleSpread( probecount );



%
% Get a scratch figure.

thisfig = figure();


%
% Walk through the requested plots.

% NOTE - We'll print per-session _and_ aggregated all-session plots.

for plotidx = 1:length(plotdefs)
  thisdef = plotdefs(plotidx);

  if ~ismember(thisdef.type, {'xy', 'box', 'line'})
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
    % Compute plot ranges.

    % Special-case the horizontal cursor at unit Y.
    extrayvals = [];
    if ismember('hunity', thisdef.decorations)
      extrayvals = [ 1 ];
    end

    [ minvalx maxvalx ] = euPlot_getStructureSeriesRange( ...
      statsubset, thisdef.xaxis, [ 0 1 ], [] );
    [ minvaly maxvaly ] = euPlot_getStructureSeriesRange( ...
      statsubset, thisdef.yaxis, [ 0 1 ], extrayvals );

    minvalxy = min(minvalx, minvaly);
    maxvalxy = max(maxvalx, maxvaly);


    %
    % First pass: Traverse the data records, filter them, sort them by
    % session, and store a serialized list.

    datalist = {};
    plottitlesuffixes = {};

    casesplotted = {};
    probesplotted = {};

    for widx = 1:wincount

      % Build this window's plot title.

      thissuffix = '';

      if ismember('before', thisdef.titlesuffixes)
        thissuffix = [ thissuffix ' ' notebefore ' Before' ];
      end

      if ismember('after', thisdef.titlesuffixes)
        if ismember('before', thisdef.titlesuffixes)
          thissuffix = [ thissuffix ' and' ];
        end
        thissuffix = [ thissuffix ' ' notesafter{widx} ' After' ];
      end

      plottitlesuffixes{widx} = thissuffix;


      % Walk through the datasets.

      emptysession = struct( 'dataseriesx', {{}}, 'dataseriesy', {{}}, ...
        'cidx', [], 'pidx', [], 'sidx', [], 'sessiontitle', 'undefined' );

      thiswindatalist = struct('aggr', emptysession);
      thiswindatalist.('aggr').('sessiontitle') = 'Aggregate';
      thiswindatalist.('aggr').('sessionlabel') = 'aggr';

      for didx = 1:length(statsubset)

        % Make note of the session, case, and probe.

        thiscase = statsubset{didx}.caselabel;
        cidx = find(strcmp(thiscase, allcases));
        thisprobe = statsubset{didx}.probelabel;
        pidx = find(strcmp(thisprobe, allprobes));
        thissession = statsubset{didx}.sessionlabel;
        sidx = find(strcmp(thissession, allsessions));

        casesplotted = unique([ casesplotted { thiscase } ]);
        probesplotted = unique([ probesplotted { thisprobe } ]);

        thissessionkey = sessionkeys{sidx};


        % If this is a new session, initialize its data.

        if ~isfield(thiswindatalist, thissessionkey)
          thiswindatalist.(thissessionkey) = emptysession;
          thiswindatalist.(thissessionkey).('sessiontitle') = ...
            sessiontitletext{sidx};
          thiswindatalist.(thissessionkey).('sessionlabel') = ...
            thissession;
        end


        % Figure out what our X and Y data series look like.

        % Tolerate columns (for single time windows) and matrices (for
        % multiple time windows).

        % Y axis series.

        thisxseries = statsubset{didx}.(thisdef.xaxis);
        if min(size(thisxseries)) > 1
          thisxseries = thisxseries(:,widx);
        end

        thisyseries = statsubset{didx}.(thisdef.yaxis);
        if min(size(thisyseries)) > 1
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
    % Second pass: Make plots.

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
            thiscase = allcases{cidx};
            thisprobe = allprobes{pidx};
            thissession = allsessions{sidx};


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
            hcursorlist = {{ 1, cols.gry, '' }};
          end

          % NOTE - We'd normally have the plot range up to 1.3 * maxvaly,
          % but since outliers aren't rendered, that's overkill here.

          euPlot_plotMultipleBoxCharts( ...
            boxvalues, boxcases, boxprobes, ...
            'linear', 'linear', [], [ 0 maxvaly ], ...
            thisdef.xtitle, thisdef.ytitle, false, 0.5, ...
            {}, hcursorlist, 'northeast', ...
            [ thisdef.titleprefix plottitlesuffixes{widx} ...
              ' - ' thissessiontitle ], ...
            [ fnameprefix '-' thisdef.label '-' thissessionlabel ...
              '-' labelsafter{widx} '.png' ] );

        else

          % XY plot or line plot.
          % A lot of code is common between these.

          figure(thisfig);
          clf('reset');

          hold on;

          % NOTE - Building the legend afterwards; plot without display names.

          for recidx = 1:reccount
            thisxseries = thissessiondata.dataseriesx{recidx};
            thisyseries = thissessiondata.dataseriesy{recidx};
            cidx = thissessiondata.cidx(recidx);
            pidx = thissessiondata.pidx(recidx);
            sidx = thissessiondata.sidx(recidx);
            thiscase = allcases{cidx};
            thisprobe = allprobes{pidx};
            thissession = allsessions{sidx};


            % The X series might be channel indices; that's ok.

            thiscolour = casecols{cidx};

            if strcmp(thisdef.type, 'xy')
              plot( thisxseries, thisyseries, 'Color', thiscolour, ...
                'LineStyle', 'none', 'Marker', probemarks{pidx}, ...
                'MarkerSize', markersize, 'HandleVisibility', 'off' );
            elseif strcmp(thisdef.type, 'line')
              plot( thisxseries, thisyseries, 'Color', thiscolour, ...
                'LineStyle', probelines{pidx}, 'Marker', probemarks{pidx}, ...
                'MarkerSize', markersize, 'HandleVisibility', 'off' );
            end
          end

          % Add decorations.

          if ismember('diag', thisdef.decorations)
            plot( [0 maxvalxy], [0 maxvalxy], ...
              'Color', cols.gry, 'HandleVisibility', 'off' );
          end

          if ismember('hunity', thisdef.decorations)
            plot( [minvalx maxvalx], [1 1], ...
              'Color', cols.gry, 'HandleVisibility', 'off' );
          end


          % Build the legend.
          % Doing this per pair gets too big to display, so show cases and
          % probes separately.

          for cidx = 1:length(allcases)
            if ismember(allcases{cidx}, casesplotted)
              plot( NaN, NaN, 'Color', casecols{cidx}, ...
                'DisplayName', legendcasetext{cidx} );
            end
          end

          for pidx = 1:length(allprobes)
            if ismember(allprobes{pidx}, probesplotted)
              if strcmp(thisdef.type, 'xy')
                % Just the marker.
                plot( NaN, NaN, 'Color', cols.blk, ...
                  'LineStyle', 'none', 'Marker', probemarks{pidx}, ...
                  'MarkerSize', markersize, ...
                  'DisplayName', legendprobetext{pidx} );
              else
                % Marker and line style.
                plot( NaN, NaN, 'Color', cols.blk, ...
                  'LineStyle', probelines{pidx}, ...
                  'Marker', probemarks{pidx}, 'MarkerSize', markersize, ...
                  'DisplayName', legendprobetext{pidx} );
              end
            end
          end


          % Add annotations.

          hold off;

          title( [ thisdef.titleprefix plottitlesuffixes{widx} ...
            ' - ' thissessiontitle ] );

          xlabel( thisdef.xtitle );
          ylabel( thisdef.ytitle );

          if strcmp(thisdef.type, 'xy')
            xlim([ 0 1.3*maxvalxy ]);
            ylim([ 0 maxvalxy ]);

            legend('Location', 'southeast');
          else
            xlim([ minvalx maxvalx ]);
            ylim([ minvaly 1.3*maxvaly ]);

            legend('Location', 'northeast');
          end

          saveas( thisfig, [ fnameprefix '-' thisdef.label ...
            '-' thissessionlabel '-' labelsafter{widx} '.png' ] );


          % Do this again for log XY plots.

          if strcmp(thisdef.type, 'xy')
            xlim([ 0.01*maxvalxy 4*maxvalxy ]);
            ylim([ 0.01*maxvalxy maxvalxy ]);
            set(gca, 'xscale', 'log');
            set(gca, 'yscale', 'log');

            hold on;
            if ismember('diag', thisdef.decorations)
              plot( [0.01*maxvalxy maxvalxy], [0.01*maxvalxy maxvalxy], ...
                'Color', cols.gry, 'HandleVisibility', 'off' );
            end
            if ismember('hunity', thisdef.decorations)
              plot( [0.01*maxvalxy 4*maxvalxy], [1 1], ...
                'Color', cols.gry, 'HandleVisibility', 'off' );
            end
            hold off;

            saveas( thisfig, [ fnameprefix '-' thisdef.label ...
              '-' thissessionlabel '-' labelsafter{widx} '-log.png' ] );
          end

        end
      end
    end
  end
end


% Dispose of the scratch figure.
close(thisfig);


% Done.
end


%
% This is the end of the file.
