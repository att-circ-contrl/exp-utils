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
% NOTE - Time ranges and decorations are hardcoded.
%
% This is a wrapper for euPlot_axesPlotFTTimelock().
%
% "timelockdata_ft" is a Field Trip structure produced by
%   ft_timelockanalysis().
% "bandsigma" is a scalar indicating where to draw confidence intervals.
%   This is a multiplier for the standard deviation.
% "plots_wanted" is a cell array containing zero or more of 'oneplot' and
%   'perchannel', controlling which plots are produced.
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


% Prune the channel list if we want fewer plots.
if chancount > max_count_per_size
  wantplot = euPlot_decimatePlotsBresenham(max_count_per_size, chanlist);
  chanlist = chanlist(wantplot);
end


% Generate the single-plot plot.

if ismember('oneplot', plots_wanted)

  legendpos = 'northeast';
  if chancount > maxlegendsize
    legendpos = 'off';
  end

  helper_plotAllZooms( thisfig, timelockdata_ft, {}, bandsigma, ...
    legendpos, [ figtitle ' - All' ], [ obase '-all' ], ...
    window_sizes_sec, size_labels );

end


% Generate the per-channel plots.

if ismember('perchannel', plots_wanted)

  for cidx = 1:chancount
    thischan = chanlist{cidx};
    [ thischanlabel thischantitle ] = euUtil_makeSafeString(chanlist{cidx});

    helper_plotAllZooms( thisfig, timelockdata_ft, ...
      { thischan }, bandsigma, ...
      'off', [ figtitle ' - ' thischantitle ], ...
      [ obase '-' thischanlabel ], window_sizes_sec, size_labels );
  end

end


% Finished with the scratch figure.
close(thisfig);


% Done.

end


%
% Helper Functions


function helper_plotAllZooms( thisfig, timelockdata_ft, ...
  chanlist, bandsigma, legendpos, titlebase, obase, zoomsizes, zoomlabels )

  for zidx = 1:length(zoomlabels)

    thiszlabel = zoomlabels{zidx};
    thiszoom = zoomsizes{zidx};

    figure(thisfig);
    clf('reset');
    thisax = gca();

    euPlot_axesPlotFTTimelock( thisax, timelockdata_ft, ...
      chanlist, bandsigma, thiszoom, [], ...
      legendpos, titlebase );

    saveas( thisfig, sprintf('%s-%s.png', obase, thiszlabel) );

  end

  % Done.
end



%
% This is the end of the file.
