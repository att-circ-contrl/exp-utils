function euPlot_hlevPlotStatTimeHeatmap( plotdata, ...
  timerange, indeprange, zrange, timeloglin, indeploglin, zloglin, ...
  figtitle, timetitle, indeptitle, ztitle, outfile )

% function euPlot_hlevPlotStatTimeHeatmap( plotdata, ...
%   timerange, indeprange, zrange, timeloglin, indeploglin, zloglin, ...
%   figtitle, timetitle, indeptitle, ztitle, outfile )
%
% This renders cooked plot data to a heatmap with time as the X axis.
%
% NOTE - If the independent variable contains labels rather than numeric data,
% its axis will be arranged in lexical order.
% NOTE - The dependent variable (heat value) must be numeric.
%
% NOTE - Multiple entries with the same independent and time bin values will
% conflict with each other! Only the last entry will be plotted in these
% cases. Merge records like that before calling this function.
%
% Plotted X coordinates are the data's time values.
% Plotted Y coordinates are the data's X values (independent variable).
% Plotted heat coordinates are the data's Y values (dependent variable).
%
% "plotdata" is cooked statistics plot data, per PLOTDATACOOKED.txt.
% "timerange" [ min max ] specifies the time axis range, or [] to auto-range.
% "indeprange" [ min max ] specifies the independent variable axis range,
%   or [] to auto-range.
% "zrange" [ min max ] specifies the heat-map Z range (clim range), or [] to
%   auto-range.
% "timeloglin" is 'log' or 'linear', applying to the time axis.
% "indeploglin" is 'log' or 'linear', applying to the independent variable
%   axis.
% "zloglin" is 'log' or 'linear', applying to the heat axis.
% "figtitle" is the title to use for the figure.
% "timetitle" is the title to use for the time axis.
% "indeptitle" is the title to use for the independent variable axis.
% "ztitle" is the title to use for the heat axis.
% "outfile" is the name of the file to write to.
%
% No return value.


%
% Bail out if we have no data.

if isempty(plotdata)
  return;
end



%
% Get ranges, log/linaer flags, and tic labels for label data.

% NOTE - Heat values and time values should be numeric!

[ minvaltime maxvaltime ticlabelstime want_time_log ] = ...
  euPlot_hlevHelperGetRangeAndTics( ...
    [ plotdata.timevaluems ], [], timeloglin, timerange );

[ minvalindep maxvalindep ticlabelsindep want_indep_log ] = ...
  euPlot_hlevHelperGetRangeAndTics( ...
    nlUtil_extractStructureSeries( plotdata, 'dataseriesx' ), ...
    [], indeploglin, indeprange );

[ minvalheat maxvalheat ticlabelsheat want_heat_log ] = ...
  euPlot_hlevHelperGetRangeAndTics( ...
    nlUtil_extractStructureSeries( plotdata, 'dataseriesy' ), ...
    [], zloglin, zrange );



%
% Preprocess the time and independent axes.

% Get a list of time bin labels and a lookup table of time values.

timelabelsraw = { plotdata.timelabel };
timevaluesraw = [ plotdata.timevaluems ];

timelutlabels = unique(timelabelsraw);
timelutvalues = [];
for tidx = 1:length(timelutlabels)
  validx = min(find(strcmp( timelutlabels{tidx}, timelabelsraw )));
  timelutvalues(tidx) = timevaluesraw(validx);
end

% Shuffle this so that it's sorted in numeric order, not lexical.
[ timelutvalues, sortidx ] = sort(timelutvalues);
timelutlabels = timelutlabels(sortidx);


% Figure out what the maximum number of independent data elements is.

if isempty(ticlabelsindep)
  % Numeric data.
  % This _should_ be consistent, but tolerate inconsistent lengths.

  datamaxlength = 0;
  for recidx = 1:length(plotdata)
    datamaxlength = max( datamaxlength, ...
      length(plotdata(recidx).dataseriesx) );
  end
else
  % Label data.
  datamaxlength = length(ticlabelsindep);
end



%
% Build the data matrix. Anything missing defaults to NaN.

yxdata = nan( datamaxlength, length(timelutvalues) );
yxindepvals = nan( datamaxlength, 1);
yxtimevals = timelutvalues;

for recidx = 1:length(plotdata)

  thisrec = plotdata(recidx);


  % Index time by label, not time value, for consistency.
  thistimeidx = min(find(strcmp( thisrec.timelabel, timelutlabels )));


  % Get data series.
  thisheatseries = thisrec.dataseriesy;
  thisindepseries = thisrec.dataseriesx;


  % Index the independent series by label if it's labels. This tolerates
  % records containing only some label values, and also handles sorting.
  % For numeric independent series, index by position.
  % FIXME - Blithely assume that numeric independent variable values are
  % consistent between records and already sorted or in sensible order.

  if isempty(ticlabelsindep)
    % Numeric data.
    thisindepindices = 1:length(thisindepseries);
  else
    % Label data.

    thisindepindices = [];
    for didx = 1:length(thisindepseries)
      thisindepindices(didx) = ...
        min(find(strcmp( thisindepseries(didx), ticlabelsindep )));
    end

    % For plotting, store indices rather than labels.
    thisindepseries = thisindepindices;
  end


  % Store this data slice and update the list of independent values.
  yxdata(thisindepindices, thistimeidx) = thisheatseries;
  yxindepvals(thisindepindices) = thisindepseries;

end


% Pad out discontinuous ranges so that they render properly.
% FIXME - This doesn't tolerate log data yet!
% To tolerate it, transform the relevant axes, call it, then un-transform.

[ yxdata yxtimevals yxindepvals ] = ...
  nlProc_padHeatmapGaps( yxdata, yxtimevals, yxindepvals );



%
% Plot the data.

thisfig = figure();

figure(thisfig);
clf('reset');

hold on;

timelogswitch = 'linear';
if want_time_log ; timelogswitch = 'log'; end

indeplogswitch = 'linear';
if want_indep_log ; indeplogswitch = 'log'; end

heatlogswitch = 'linear';
if want_heat_log ; heatlogswitch = 'log'; end

% FIXME - Ignore our ranges and let it auto-range.
% It needs to do that to properly cover the full bin widths.
%  [ minvaltime maxvaltime ], [ minvalindep maxvalindep ], ...
nlPlot_axesPlotSurface2D( gca, yxdata, yxtimevals, yxindepvals, ...
  [], [], ...
  timelogswitch, indeplogswitch, heatlogswitch, ...
  timetitle, indeptitle, figtitle );

thiscol = colorbar;
thiscol.Label.String = ztitle;

clim([ minvalheat maxvalheat ]);

if want_heat_log
  set(gca, 'ColorScale', 'log');
end

% Convert the independent axis to labels if appropriate.
if ~isempty(ticlabelsindep)
  [ scratch ticlabelsindep ] = euUtil_makeSafeStringArray( ticlabelsindep );
  set( gca, ...
    'YTick', 1:length(ticlabelsindep), 'YTickLabels', ticlabelsindep );
end

saveas(thisfig, outfile);

close(thisfig);



% Done.
end

%
% This is the end of the file.
