function euPlot_plotFTTimelock( timelockdata_ft, bandsigma, ...
  plots_wanted, window_sizes_ms, size_labels, max_count_per_size, ...
  figtitle, obase )

% function euPlot_plotFTTimelock( timelockdata_ft, bandsigma, ...
%   plots_wanted, window_sizes_ms, size_labels, max_count_per_size, ...
%   figtitle, obase )
%
% This plots a series of time-locked average waveforms and saves the
% resulting plots. Plots may have all channels stacked, or be per-channel,
% or a combination of the above.
%
% NOTE - Decorations are hardcoded.
%
% This is a wrapper for euPlot_axesPlotFTTimelock().
%
% "timelockdata_ft" is a Field Trip structure produced by
%   ft_timelockanalysis().
% "bandsigma" is a scalar indicating where to draw confidence intervals.
%   This is a multiplier for the standard deviation and for SEM.
% "plots_wanted" is a cell array containing zero or more of 'oneplot',
%   'perchannel', and 'stripchart', controlling which plots are produced.
% "window_sizes_ms" is a cell array. Each cell contains a plot time range
%   [ begin end ] in milliseconds, or [] for the full data extent.
% "size_labels" is a cell array containing filename-safe labels used when
%   creating filenames and annotating titles for plots of each window size.
% "max_count_per_size" is a scalar indicating the maximum number of plots
%   to emit at a given size level. Set to inf to not decimate plots.
% "figtitle" is the prefix used when generating figure titles.
% "obase" is the prefix used when generating output filenames.


% Convert time ranges to seconds.
window_sizes_sec = {};
for zidx = 1:length(window_sizes_ms)
  window_sizes_sec{zidx} = window_sizes_ms{zidx} * 0.001;
end

% Magic number for pretty display.
maxlegendsize = 20;


% Get a scratch figure.
thisfig = figure();


% Get metadata.

chanlist = timelockdata_ft.label;
chancount = length(chanlist);


% Generate the single-plot plot.

if ismember('oneplot', plots_wanted)

  legendpos = 'northeast';
  if chancount > maxlegendsize
    legendpos = 'off';
  end

  helper_plotAllZooms( thisfig, timelockdata_ft, {}, false, bandsigma, ...
    legendpos, [ figtitle ' - All' ], [ obase '-all' ], ...
    window_sizes_sec, size_labels );

end


% Prune the channel list if we want fewer per-channel plots.

if chancount > max_count_per_size
  wantplot = euPlot_decimatePlotsBresenham(max_count_per_size, chanlist);
  chanlist = chanlist(wantplot);
  chancount = length(chanlist);
end


% Generate the per-channel plots.

if ismember('perchannel', plots_wanted)

  for cidx = 1:chancount
    thischan = chanlist{cidx};
    [ thischanlabel thischantitle ] = euUtil_makeSafeString(chanlist{cidx});

    helper_plotAllZooms( thisfig, timelockdata_ft, ...
      { thischan }, false, bandsigma, ...
      'off', [ figtitle ' - ' thischantitle ], ...
      [ obase '-' thischanlabel ], window_sizes_sec, size_labels );
  end

end


% Generate the strip-chart plot.
% Only do this if we have more than one channel.

if ismember('stripchart', plots_wanted) ...
  && (length(timelockdata_ft.label) > 1)

  % Show a legend no matter how many channels we have; it's a tall plot.
  legendpos = 'northeast';

  % Don't print confidence bands for the strip charts.
  helper_plotAllZooms( thisfig, timelockdata_ft, {}, true, NaN, ...
    legendpos, [ figtitle ' - All' ], [ obase '-strip' ], ...
    window_sizes_sec, size_labels );

end


% Finished with the scratch figure.
close(thisfig);


% Done.

end


%
% Helper Functions


function helper_plotAllZooms( thisfig, timelockdata_ft, chanlist, ...
  wantspread, bandsigma, legendpos, titlebase, obase, zoomsizes, zoomlabels )

  figure(thisfig);
  clf('reset');


  % Make the figure larger if we're making a strip-chart plot.

  oldpos = thisfig.Position;
  newpos = oldpos;

  spread_fraction = 0;

  if wantspread
    spread_fraction = 0.5;

    chancount = length(chanlist);
    if isempty(chanlist)
      chancount = length(timelockdata_ft.label);
    end

    [ oldpos newpos ] = nlPlot_makeFigureTaller( thisfig, chancount, 8 );
  end


  % Make plots.

  for zidx = 1:length(zoomlabels)

    thiszlabel = zoomlabels{zidx};
    thiszoom = zoomsizes{zidx};

    clf('reset');
    thisfig.Position = newpos;
    thisax = gca();

    euPlot_axesPlotFTTimelock( thisax, timelockdata_ft, ...
      chanlist, spread_fraction, bandsigma, thiszoom, [], ...
      legendpos, titlebase );

    saveas( thisfig, sprintf('%s-%s.png', obase, thiszlabel) );

  end


  % Restore the original figure size.
  clf('reset');
  thisfig.Position = oldpos;


  % Done.
end



%
% This is the end of the file.
