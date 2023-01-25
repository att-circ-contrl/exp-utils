function euPlot_plotZoomedWaves( wave_list, flag_list, cursor_list, ...
  window_sizes, size_labels, max_count_per_size, ...
  legendpos, titlebase, fnamebase )

% function euPlot_plotZoomedWaves( wave_list, flag_list, cursor_list, ...
%   window_sizes, size_labels, max_count_per_size, ...
%   legendpos, titlebase, fnamebase )
%
% This generates a series of plots of multiple signals, stepping the plot
% window across the full time span, with multiple window sizes.
%
% Empty legend labels suppress rendering of that legend label.
%
% "wave_list" is a cell array. Each cell contains a cell array describing
%   the waves to plot: { time_series, wave_series, colour, legend_label }.
% "flag_list" is a cell array. Each cell contains a cell array describing
%   boolean data to plot: { time_series, flag_series, colour, legend_label }.
% "cursor_list" is a cell array. Each cell contains a cell array describing
%   events to plot: { event_times, colour, legend_label }.
% "window_sizes" is a vector containing plot durations in seconds, stepped
%   across the time series.
% "size_labels" is a filename-safe label used when creating filenames and
%   annotating titles for plots that use a given window size.
% "max_count_per_size" is a scalar indicating the maximum number of plots
%   to emit at a given size level. Plots are spaced evenly within and
%   centered on the full time span.
% "legendpos" is the legend location ('off' to disable).
% "titlebase" is a prefix to use when constructing human-readable titles.
% "fnamebase" is a prefix to use when constructing filenames.
%
% No return value.


% Figure out what the Y range is.

maxrange = 1.0;
wavecount = length(wave_list);
if ~isempty(wave_list)
  maxrange = max(abs( wave_list{1}{2} ));
  for widx = 2:wavecount
    thisrange = max(abs( wave_list{widx}{2} ));
    maxrange = max(maxrange, thisrange);
  end
end

% Convert boolean flags to signal values.

flagcount = length(flag_list);
for fidx = 1:flagcount
  thisflag = flag_list{fidx}{2};
  thisflag = (thisflag > 0.5);
  thisflag = (thisflag * 2 * maxrange) - maxrange;
end


% Get size multipliers for flag and cursor series.

cursorcount = length(cursor_list);
bothcount = flagcount + cursorcount;

flagsizes = [];
cursorsizes = [];

bothsizes = [];
if bothcount > 0
  bothsizes = linspace(0.8, 1.0, bothcount);
end

if flagcount > 0
  flagsizes = bothsizes(1:flagcount);
end

if cursorcount > 0
  cursorsizes = bothsizes((flagcount + 1):bothcount);
end


% Figure out what the full X range is.

mintime = inf;
maxtime = -inf;

for widx = 1:wavecount
  thismin = min(wave_list{widx}{1});
  thismax = max(wave_list{widx}{1});
  mintime = min(mintime, thismin);
  maxtime = max(maxtime, thismax);
end

for fidx = 1:flagcount
  thismin = min(flag_list{fidx}{1});
  thismax = max(flag_list{fidx}{1});
  mintime = min(mintime, thismin);
  maxtime = max(maxtime, thismax);
end

for cidx = 1:cursorcount
  thismin = min(cursor_list{cidx}{1});
  thismax = max(cursor_list{cidx}{1});
  mintime = min(mintime, thismin);
  maxtime = max(maxtime, thismax);
end



% Render the plots.

thisfig = figure;

for sizeidx = 1:length(window_sizes)

  thiswinsize = window_sizes(sizeidx);
  thiswinsizelabel = size_labels{sizeidx};

  % Get window locations.

  fullsize = maxtime - mintime;
  wincount = floor(fullsize / thiswinsize);
  wincount = min(wincount, max_count_per_size);

  % Plots are centered in N segments, not spanning all the way to the ends.
  winpitch = fullsize / wincount;
  winfirsttime = 0.5 * (winpitch - thiswinsize);


  % Walk through the window locations, generating plots.

  for winidx = 1:wincount

    thisstarttime = winfirsttime + (winidx - 1) * winpitch;
    thisendtime = thisstarttime + thiswinsize;

    figure(thisfig);
    clf('reset');

    hold on;

    for widx = 1:wavecount
      thistime = wave_list{widx}{1};
      thiswave = wave_list{widx}{2};
      thiscol = wave_list{widx}{3};
      thislabel = wave_list{widx}{4};

      thismask = (thistime >= thisstarttime) & (thistime <= thisendtime);
      thistime = thistime(thismask);
      thiswave = thiswave(thismask);

      if ~isempty(thislabel)
        plot(thistime, thiswave, 'Color', thiscol, 'DisplayName', thislabel);
      else
        plot(thistime, thiswave, 'Color', thiscol, 'HandleVisibility', 'off');
      end
    end

    for fidx = 1:flagcount
      thistime = flag_list{fidx}{1};
      thiswave = flag_list{fidx}{2};
      thiscol = flag_list{fidx}{3};
      thislabel = flag_list{fidx}{4};

      thismask = (thistime >= thisstarttime) & (thistime <= thisendtime);
      thistime = thistime(thismask);
      thiswave = thiswave(thismask);

      thiswave = thiswave * flagsizes(fidx) * maxrange;

      if ~isempty(thislabel)
        plot(thistime, thiswave, 'Color', thiscol, 'DisplayName', thislabel);
      else
        plot(thistime, thiswave, 'Color', thiscol, 'HandleVisibility', 'off');
      end
    end

    for cidx = 1:cursorcount
      thistime = cursor_list{cidx}{1};
      thiscol = cursor_list{cidx}{3};
      thislabel = cursor_list{cidx}{4};

      thismask = (thistime >= thisstarttime) & (thistime <= thisendtime);
      thistime = thistime(thismask);
      thisamp = cursorsizes(cidx) * maxrange;

      for tidx = 1:length(thistime)
        if (tidx == 1) && (~isempty(thislabel))
          plot([ thistime(tidx) thistime(tidx) ], [ thisamp thisamp ], ...
            'Color', thiscol, 'DisplayName', thislabel);
        else
          plot([ thistime(tidx) thistime(tidx) ], [ thisamp thisamp ], ...
            'Color', thiscol, 'HandleVisibility', 'off');
        end
      end
    end

    ylim([ -1.1 * maxrange, 1.1 * maxrange ]);

    xlabel('Time (s)');
    ylabel('Amplitude (a.u.)');

    if strcmp(legendpos, 'off')
      legend('off');
    else
      legend('Location', legendpos);
    end

    title( sprintf('%s (%s) - %04d', titlebase, thiswinsizelabel, winidx) );

    saveas( thisfig, ...
      sprintf( '%s-%s-%04d.png', fnamebase, thiswinsizelabel, winidx ) );

  end

end

close(thisfig);


% Done.
end


%
% This is the end of the file.
