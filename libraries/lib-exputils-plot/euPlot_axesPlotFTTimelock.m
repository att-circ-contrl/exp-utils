function euPlot_axesPlotFTTimelock( thisax, ...
  timelockdata_ft, chans_wanted, bandsigma, plot_timerange, plot_yrange, ...
  legendpos, figtitle )

% function euPlot_axesPlotFTTimelock( thisax, ...
%   timelockdata_ft, chans_wanted, bandsigma, plot_timerange, plot_yrange, ...
%   legendpos, figtitle )
%
% This plots the mean and variance of one or more channel waveforms in the
% current axes. Events are rendered as cursors behind the waveforms.
%
% "thisax" is the "axes" object to render to.
% "timelockdata_ft" is a Field Trip structure produced by
%   ft_timelockanalysis().
% "chans_wanted" is a cell array with channel names to plot. Pass an empty
%   cell array to plot all channels.
% "bandsigma" is a scalar indicating where to draw confidence intervals.
%   This is a multiplier for the standard deviation.
% "plot_timerange" [ min max ] is the time range (X range) of the plot axes.
%   Pass an empty range for auto-ranging.
% "plot_yrange" [ min max ] is the Y range of the plot axes.
%   Pass an empty range for auto-ranging.
% "legendpos" is a position specifier to pass to the "legend" command, or
%   'off' to disable the plot legend. The legend lists channel labels.
% "figtitle" is the title to apply to the figure. Pass an empty character
%   array to disable the title.


% NOTE - For rendering, explicitly specify the axes to modify for each
% function call. Trying to select axes messes with child ordering.


%
% Get metadata.

chanlabels = timelockdata_ft.label;
chancount = length(chanlabels);

if isempty(chans_wanted)
  chanmask = true(size(chanlabels));
else
  chans_wanted = ft_channelselection( chans_wanted, chanlabels );
  chanmask = false(size(chanlabels));
  for cidx = 1:length(chans_wanted)
    chanmask(strcmp( chans_wanted{cidx}, chanlabels )) = true;
  end
end


%
% Get the time range.
% We have a sensible time axis in timelockdata_ft.time.

autotime_min = min(timelockdata_ft.time);
autotime_max = max(timelockdata_ft.time);


%
% Get our confidence interval from the variance. This may have NaNs.

confband = bandsigma * sqrt(timelockdata_ft.var);


%
% Get Y ranges. This tolerates NaN without trouble.

true_ymax = max(max( timelockdata_ft.avg + confband ));
true_ymin = min(min( timelockdata_ft.avg - confband ));

% Set the time range of interest if we don't have one.
if isempty(plot_timerange)
  plot_timerange = [ autotime_min, autotime_max ];
else
  plot_timerange = [ min(plot_timerange), max(plot_timerange) ];
end

% Set the cursor Y range.
cursor_yrange = [ true_ymin, true_ymax ];
if ~isempty(plot_yrange)
  cursor_yrange = [ min(plot_yrange), max(plot_yrange) ];
end


%
% Set up rendering.

xlim(thisax, plot_timerange);
if isempty(plot_yrange)
  ylim(thisax, 'auto');
else
  ylim(thisax, [ min(plot_yrange), max(plot_yrange) ]);
end

hold(thisax, 'on');



% Build a decent colour palette.
% This isn't expensive, so just do it here to avoid duplication.

% NOTE - Do this in a way that isn't hostile to overlaying event cursors.

cols = nlPlot_getColorPalette();

palette_waves = nlPlot_getColorSpread(cols.grn, chancount, 180);


% Render channel waveforms with confidence bands.

isfirstchan = true;
for cidx = 1:chancount
  if chanmask(cidx)

    % Get the colour for this channel.
    wavecol = palette_waves{cidx};

    % Get the legend label.
    [ safechanlabel safechantitle ] = ...
      euUtil_makeSafeString( chanlabels{cidx} );
    thislabel = safechantitle;

    % Get series.
    thistimeseries = timelockdata_ft.time;
    thisdata = timelockdata_ft.avg(cidx,:);
    thisconf = confband(cidx,:);

    % Render the confidence interval.
    plot( thisax, thistimeseries, thisdata + thisconf, ':', ...
      'Color', wavecol, 'HandleVisibility', 'off' );
    plot( thisax, thistimeseries, thisdata - thisconf, ':', ...
      'Color', wavecol, 'HandleVisibility', 'off' );

    % Render the wave.
    if ~isempty(thislabel)
      plot( thisax, thistimeseries, thisdata, '-', ...
        'Color', wavecol, 'DisplayName', thislabel );
    else
      plot( thisax, thistimeseries, thisdata, '-', ...
        'Color', wavecol, 'HandleVisibility', 'off' );
    end

    % Done.
    isfirstchan = false;
  end
end



% Finished rendering.
hold(thisax, 'off');



% Decorate the plot.

xlabel(thisax, 'Time (s)');
ylabel(thisax, 'Amplitude (a.u.)');

title(thisax, figtitle);

if strcmp('off', legendpos)
  legend(thisax, 'off');
else
  legend(thisax, 'Location', legendpos);
end



% Done.

end


%
% This is the end of the file.
