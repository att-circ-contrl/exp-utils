function euPlot_plotEventAlignedWaves( ...
  evtimes, time_before_trig_ms, time_after_trig_ms, time_after_last_ms, ...
  max_train_gap_ms, wave_sets, legendpos, max_plot_count, fnamebase )

% function euPlot_plotEventAlignedWaves( ...
%   evtimes, time_before_trig_ms, time_after_trig_ms, time_after_last_ms, ...
%   max_train_gap_ms, wave_sets, legendpos, max_plot_count, fnamebase )
%
% This renders multi-panels plot of several waveforms during time windows
% around a triggering event. Only the first event of a train of events is
% used as a trigger.
%
% If both "time_after_trig" and "time_after_last" are given, the longer of
% the two durations is used. If one is NaN, the other is used alone.
%
% Empty legend labels suppress rendering of that legend label.
%
% "evtimes" is a vector containing event timestamps (in seconds).
% "time_before_trig_ms" is the number of milliseconds to extend the plot
%   before the trigger event.
% "time_after_trig_ms" is the number of milliseconds to extend the plot
%   after the trigger event (first event in a train).
% "time_after_last_ms" is the number of milliseconds to extend the plot
%   after the last event in a train.
% "max_train_gap_ms" is the maximum number of milliseconds between successive
%   events for the events to still be considered part of one event train
%   (only the first event in a train is used as a plot trigger).
% "wave_sets" is a cell array containing subplot definitions. Each subplot
%   definition is itself a cell array with the following content:
%   { subplot_title, wave_list, vert_cursor_list, horiz_cursor_list }
%   "subplot_title" is a prefix to use when building human-readable titles.
%   "wave_list" is a cell array describing a wave to plot:
%     { time_series, wave_series, colour, legend_label }
%   "vert_cursor_list" is a cell array describing vertical cursor lines to
%     plot: { cursor_times, colour, legend_label }
%   "horiz_cursor_list" is a cell array describing horizontal cursor lines
%     to plot: { cursor_yvals, colour, legend_label }
% "legendpos" is the legend location ('off' to disable).
% "max_plot_count" is a scalar indicating the maximum number of plots to
%   emit. If this is smaller than the number of plot trigger events, the
%   list of plot trigger events is decimated to reduce the number of plots.
% "fnamebase" is a prefix to use when constructing filenames.
%
% No return value.


% Translate millisecond times into second times.

time_before_trig = 0.001 * time_before_trig_ms;
time_after_trig = 0.001 * time_after_trig_ms;
time_after_last = 0.001 * time_after_last_ms;
max_train_gap = 0.001 * max_train_gap_ms;

% Force sanity.

if isnan(time_before_trig)
  time_before_trig = 0.1;
end

if isnan(time_after_trig) && isnan(time_after_last)
  time_after_last = 0.1;
end

if isnan(max_train_gap)
  max_train_gap = 0.1;
end


%
% Figure out what time spans we want to plot.

trigtimes = [];
starttimes = [];
endtimes = [];
trigcount = 0;

prevtime = NaN;

for eidx = 1:length(evtimes)

  thistime = evtimes(eidx);

  want_new_train = false;
  end_old_train = false;

  if isnan(prevtime)

    % Start a new train.
    want_new_train = true;

  elseif (thistime - prevtime) > max_train_gap

    % End this train and start a new train.
    end_old_train = true;
    want_new_train = true;

  end

  if end_old_train
    end_trig = trigtimes(trigcount) + time_after_trig;
    end_last = prevtime + time_after_last;
    if isnan(end_trig)
      endtimes(trigcount) = end_last;
    elseif isnan(end_last)
      endtimes(trigcount) = end_trig;
    else
      endtimes(trigcount) = max([ end_trig, end_last ]);
    end
  end

  if want_new_train
    trigcount = trigcount + 1;
    trigtimes(trigcount) = thistime;
    starttimes(trigcount) = thistime - time_before_trig;
  end

  prevtime = thistime;

end

% If we had any events at all, end the train we're in the middle of.
if ~isnan(prevtime)
  end_trig = trigtimes(trigcount) + time_after_trig;
  end_last = prevtime + time_after_last;
  if isnan(end_trig)
    endtimes(trigcount) = end_last;
  elseif isnan(end_last)
    endtimes(trigcount) = end_trig;
  else
    endtimes(trigcount) = max([ end_trig, end_last ]);
  end
end


%
% Prune the plot list.

% This works fine if we already have fewer than the desired number.
wantplot = euPlot_decimatePlotsBresenham( max_plot_count, trigtimes );


%
% Generate plots.

rowcount = length(wave_sets);


% Figure out the Y range for each plot.

maxranges = [];

for ridx = 1:rowcount

  thismax = -inf;
  thiswavelist = wave_sets{ridx}{2};

  for widx = 1:length(thiswavelist)
    thisrange = max(abs( thiswavelist{widx}{2} ));
    thismax = max(thismax, thisrange);
  end

  if ~isfinite(thismax)
    thismax = 1.0;
  end

  maxranges(ridx) = thismax;

end


% Plot.

thisfig = figure;

for tidx = 1:trigcount

  thisstarttime = starttimes(tidx);
  thisendtime = endtimes(tidx);

  if wantplot(tidx)

    figure(thisfig);
    clf('reset');

    for ridx = 1:rowcount

      thisset = wave_sets{ridx};

      thistitlebase = thisset{1};
      thiswavelist = thisset{2};
      thisvertcursorlist = thisset{3};
      thishorizcursorlist = thisset{4};

      subplot(rowcount, 1, ridx);

      hold on;

      % Waves.

      for widx = 1:length(thiswavelist)
        thistime = thiswavelist{widx}{1};
        thiswave = thiswavelist{widx}{2};
        thiscol = thiswavelist{widx}{3};
        thislabel = thiswavelist{widx}{4};

        thismask = (thistime >= thisstarttime) & (thistime <= thisendtime);
        thistime = thistime(thismask);
        thiswave = thiswave(thismask);

        if ~isempty(thislabel)
          plot( thistime, thiswave, ...
            'Color', thiscol, 'DisplayName', thislabel );
        else
          plot( thistime, thiswave, ...
            'Color', thiscol, 'HandleVisibility', 'off' );
        end
      end

      % Cursors.

      vertsizes = [];
      if length(thisvertcursorlist) > 0
        vertsizes = linspace( 0.8, 1.0, length(thisvertcursorlist) );
      end

      for cidx = 1:length(thisvertcursorlist)
        thistime = thisvertcursorlist{cidx}{1};
        thiscol = thisvertcursorlist{cidx}{2};
        thislabel = thisvertcursorlist{cidx}{3};

        thismask = (thistime >= thisstarttime) & (thistime <= thisendtime);
        thistime = thistime(thismask);

        thisamp = vertsizes(cidx) * maxranges(ridx);

        for xidx = 1:length(thistime)
          if (xidx == 1) && (~isempty(thislabel))
            plot( ...
              [ thistime(xidx) thistime(xidx) ], [ (-thisamp) thisamp ], ...
              '-o', 'Color', thiscol, 'DisplayName', thislabel );
          else
            plot( ...
              [ thistime(xidx) thistime(xidx) ], [ (-thisamp) thisamp ], ...
              '-o', 'Color', thiscol, 'HandleVisibility', 'off' );
          end
        end
      end

      for cidx = 1:length(thishorizcursorlist)
        thislevel = thishorizcursorlist{cidx}{1};
        thiscol = thishorizcursorlist{cidx}{2};
        thislabel = thishorizcursorlist{cidx}{3};

        for yidx = 1:length(thislevel)
          if (yidx == 1) && (~isempty(thislabel))
            plot( [ thisstarttime thisendtime ], ...
              [ thislevel(yidx) thislevel(yidx) ], ...
              'Color', thiscol, 'DisplayName', thislabel );
          else
            plot( [ thisstarttime thisendtime ], ...
              [ thislevel(yidx) thislevel(yidx) ], ...
              'Color', thiscol, 'HandleVisibility', 'off' );
          end
        end
      end

      % Finished with this subplot.

      hold off;

      xlabel('Time (s)');
      ylabel('Amplitude (a.u.)');

      if strcmp(legendpos, 'off')
        legend('off');
      else
        legend('Location', legendpos);
      end

      title( sprintf('%s - %04d', thistitlebase, tidx) );

    end

    saveas( thisfig, sprintf('%s-%04d.png', fnamebase, tidx) );

  end
end

close(thisfig);


% Done.

end


%
% This is the end of the file.
