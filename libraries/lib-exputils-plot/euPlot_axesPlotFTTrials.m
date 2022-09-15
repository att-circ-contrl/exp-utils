function euPlot_axesPlotFTTrials( thisax, ...
  wavedata_ft, wavedata_samprate, ...
  trialdefs, trialnames, trialdefs_samprate, ...
  chans_wanted, trials_wanted, plot_timerange, plot_yrange, ...
  events_codes, events_rwdA, events_rwdB, events_samprate, ...
  legendpos, figtitle )

% function euPlot_axesPlotFTTrials( thisax, ...
%   wavedata_ft, wavedata_samprate, ...
%   trialdefs, trialnames, trialdef_samprate, ...
%   chans_wanted, plot_timerange, plot_yrange, ...
%   events_codes, events_rwdA, events_rwdB, event_samprate, ...
%   legendpos, figtitle )
%
% This plots a series of stacked trial waveforms in the current axes.
% Events are rendered as cursors behind the waveforms.
%
% "thisax" is the "axes" object to render to.
% "wavedata_ft" is a Field Trip "datatype_raw" structure with the trial
%   data and metadata.
% "wavedata_samprate" is the sampling rate of "wavedata_ft".
% "trialdefs" is the Field Trip trial definition matrix or table that was
%   used to generate the trial data.
% "trialnames" is either a vector of trial numbers or a cell array of trial
%   labels, corresponding to the trials in "trialdefs". An empty vector or
%   cell array auto-generates labels.
% "trialdefs_samprate" is the sampling rate used when generating "trialdefs".
% "chans_wanted" is a cell array with channel names to plot. Pass an empty
%   cell array to plot all channels.
% "trials_wanted" is a cell array with labels of trials to plot. Pass an
%   empty cell array to plot all trials.
% "plot_timerange" [ min max ] is the time range (X range) of the plot axes.
%   Pass an empty range for auto-ranging.
% "plot_yrange" [ min max ] is the Y range of the plot axes.
%   Pass an empty range for auto-ranging.
% "events_codes" is a Field Trip event structure array or table with event
%   code events. This may be empty.
% "events_rwdA" is a Field Trip event structure array or table with reward
%   line A events. This may be empty.
% "events_rwdB" is a Field Trip event structure array or table with reward
%   line B events. This may be empty.
% "events_samprate" is the sampling rate used when reading events.
% "legendpos" is a position specifier to pass to the "legend" command, or
%   'off' to disable the plot legend. The legend lists channel labels.
% "figtitle" is the title to apply to the figure. Pass an empty character
%   array to disable the title.


% NOTE - For rendering, explicitly specify the axes to modify for each
% function call. Trying to select axes messes with child ordering.


% Get metadata.

chanlabels = wavedata_ft.label;
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

is_multichannel = (sum(chanmask) > 1);

trialcount = size(trialdefs);
trialcount = trialcount(1);


% Convert whatever we were given for trial names into text labels.
trialnames = euPlot_helperMakeTrialNames(trialnames, trialcount);


% Get trial timing information.
% NOTE - Get actual Y range here too, for cursor geometry.

% Get the trial trigger times.

trialstarts = trialdefs(:,1);
trialtriggers = trialdefs(:,3);

triggertimes_abs = (trialstarts - 1) - trialtriggers;
triggertimes_abs = triggertimes_abs / trialdefs_samprate;

% Process the trials themselves.

timeseries = {};
autotime_max = -inf;
autotime_min = inf;

true_ymax = -inf;
true_ymin = inf;

for tidx = 1:trialcount
  thiswavedata = wavedata_ft.trial{tidx};
  thistimeseries = wavedata_ft.time{tidx};

  thistimemax = max(thistimeseries);
  thistimemin = min(thistimeseries);
  autotime_max = max(autotime_max, thistimemax);
  autotime_min = min(autotime_min, thistimemin);

  thisymax = max(max(thiswavedata));
  thisymin = min(min(thiswavedata));
  true_ymax = max(true_ymax, thisymax);
  true_ymin = min(true_ymin, thisymin);
end

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


% Sanity check the trial selection.

if isempty(trials_wanted)
  trials_wanted = trialnames;
end


% Get event absolute times.

codetimes = [];
if ~isempty(events_codes)
  % This gives consistent output for struct arrays and for tables.
  codetimes = vertcat(events_codes.sample);
  codetimes = (codetimes - 1) / events_samprate;
end

rwdAtimes = [];
if ~isempty(events_rwdA)
  % This gives consistent output for struct arrays and for tables.
  rwdAtimes = vertcat(events_rwdA.sample);
  rwdAtimes = (rwdAtimes - 1) / events_samprate;
end

rwdBtimes = [];
if ~isempty(events_rwdB)
  % This gives consistent output for struct arrays and for tables.
  rwdBtimes = vertcat(events_rwdB.sample);
  rwdBtimes = (rwdBtimes - 1) / events_samprate;
end


% Dice the event list up so that we aren't plotting tens of thousands of
% events in each of thousands of trials.

codetrials = {};
rwdAtrials = {};
rwdBtrials = {};
for tidx = 1:trialcount
  thisevtimes = codetimes - triggertimes_abs(tidx);
  thisevmask = (thisevtimes >= autotime_min) & (thisevtimes <= autotime_max);
  codetrials{tidx} = thisevtimes(thisevmask);

  thisevtimes = rwdAtimes - triggertimes_abs(tidx);
  thisevmask = (thisevtimes >= autotime_min) & (thisevtimes <= autotime_max);
  rwdAtrials{tidx} = thisevtimes(thisevmask);

  thisevtimes = rwdBtimes - triggertimes_abs(tidx);
  thisevmask = (thisevtimes >= autotime_min) & (thisevtimes <= autotime_max);
  rwdBtrials{tidx} = thisevtimes(thisevmask);
end



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

% We need to be able to distinguish each _type_ of information as well as
% trials within each type. We probably won't be able to do the latter, but
% try.
% FIXME - Getting cursors to look non-ugly involves a lot of hand-tweaking.
% FIXME - Waveform palette depends on whether we have one channel or many.

cols = nlPlot_getColorPalette();

if is_multichannel
  palette_waves = nlPlot_getColorSpread(cols.grn, chancount, 180);
else
  palette_waves = nlPlot_getColorSpread(cols.grn, trialcount, 180);
end

% FIXME - We should colour event codes based on code type, but aren't.
palette_codes = nlPlot_getColorSpread(cols.cyn, trialcount, 20);
palette_rwdA = nlPlot_getColorSpread(cols.brn, trialcount, 30);
palette_rwdB = nlPlot_getColorSpread(cols.mag, trialcount, 60);



% Render event cursors first, so that they're behind the waves.

isfirstlabel = true;
for tidx = 1:trialcount
  if ismember(trialnames{tidx}, trials_wanted)

    thisevlist = codetrials{tidx};
    for eidx = 1:length(thisevlist)
      thistime = thisevlist(eidx);
      % FIXME - We should label and colour these with code types.
      if isfirstlabel
        plot( thisax, [ thistime thistime ], cursor_yrange, ...
          'Color', palette_codes{tidx}, 'DisplayName', 'EvCodes' );
        isfirstlabel = false;
      else
        plot( thisax, [ thistime thistime ], cursor_yrange, ...
          'Color', palette_codes{tidx}, 'HandleVisibility', 'off' );
      end
    end

  end
end

isfirstlabel = true;
for tidx = 1:trialcount
  if ismember(trialnames{tidx}, trials_wanted)

    thisevlist = rwdAtrials{tidx};
    for eidx = 1:length(thisevlist)
      thistime = thisevlist(eidx);
      if isfirstlabel
        plot( thisax, [ thistime thistime ], cursor_yrange, ...
          'Color', palette_rwdA{tidx}, 'DisplayName', 'Rwd A' );
        isfirstlabel = false;
      else
        plot( thisax, [ thistime thistime ], cursor_yrange, ...
          'Color', palette_rwdA{tidx}, 'HandleVisibility', 'off' );
      end
    end

  end
end

isfirstlabel = true;
for tidx = 1:trialcount
  if ismember(trialnames{tidx}, trials_wanted)

    thisevlist = rwdBtrials{tidx};
    for eidx = 1:length(thisevlist)
      thistime = thisevlist(eidx);
      if isfirstlabel
        plot( thisax, [ thistime thistime ], cursor_yrange, ...
          'Color', palette_rwdB{tidx}, 'DisplayName', 'Rwd B' );
        isfirstlabel = false;
      else
        plot( thisax, [ thistime thistime ], cursor_yrange, ...
          'Color', palette_rwdB{tidx}, 'HandleVisibility', 'off' );
      end
    end

  end
end



% Render trial waveforms next.

isfirsttrial = true;
for tidx = 1:trialcount
  if ismember(trialnames{tidx}, trials_wanted)

    thiswavedata = wavedata_ft.trial{tidx};
    thistimeseries = wavedata_ft.time{tidx};

    isfirstchan = true;
    for cidx = 1:chancount
      if chanmask(cidx)

        % FIXME - Palette depends on whether we have one channel or many.
        if is_multichannel
          wavecol = palette_waves{cidx};
        else
          wavecol = palette_waves{tidx};
        end

        thislabel = '';
        if is_multichannel || (trialcount < 2)
          % Use one legend line per channel.
          if isfirsttrial
            [ safechanlabel safechantitle ] = ...
              euUtil_makeSafeString( chanlabels{cidx} );
            thislabel = safechantitle;
          end
        else
          % Use one legend line per trial.
          if isfirstchan
            [ safetriallabel safetrialtitle ] = ...
              euUtil_makeSafeString( trialnames{tidx} );
            thislabel = safetrialtitle;
          end
        end

        if ~isempty(thislabel)
          plot( thisax, thistimeseries, thiswavedata(cidx,:), ...
            'Color', wavecol, 'DisplayName', thislabel );
        else
          plot( thisax, thistimeseries, thiswavedata(cidx,:), ...
            'Color', wavecol, 'HandleVisibility', 'off' );
        end

        isfirstchan = false;
      end
    end

    isfirsttrial = false;
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
