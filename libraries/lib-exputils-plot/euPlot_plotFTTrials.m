function euPlot_plotFTTrials( wavedata_ft, wavesamprate, ...
  trialdefs, trialnames, trialsamprate, evlists, evsamprate, ...
  plots_wanted, window_sizes, size_labels, max_count_per_size, ...
  figtitle, obase )

% function euPlot_plotFTTrials( wavedata_ft, wavesamprate, ...
%   trialdefs, trialnames, trialsamprate, evlists, evsamprate, ...
%   plots_wanted, window_sizes, size_labels, max_count_per_size, ...
%   figtitle, obase )
%
% This plots a series of stacked trial waveforms and saves the resulting
% plots. Plots may have all trials and channels stacked, or have all
% trials stacked and have one plot per channel, or have all channels
% stacked and have one plot per trial, or a combination of the above.
%
% NOTE - Decorations are hardcoded.
%
% This is a wrapper for euPlot_axesPlotFTTrials().
%
% "wavedata_ft" is a Field Trip "datatype_raw" structure with the trial data
%   and metadata.
% "wavesamprate" is the sampling rate of "wavedata_ft".
% "trialdefs" is the field trip trial definition matrix or table that was
%   used to generate the trial data. This is used to properly time-align
%   events. If this is [], event plotting is suppressed.
% "trialnames" is either a vector of trial numbers or a cell array of trial
%   labels, corresponding to the trials in "trialdefs". An empty vector or
%   cell array auto-generates labels.
% "trialsamprate" is the sampling rate used when generating "trialdefs".
%   If this is NaN, event plotting is suppressed.
% "evlists" is a structure containing event lists or tables, with one event
%   list or table per field. Fields tested for are 'cookedcodes', 'rwdA',
%   and 'rwdB'.
% "evsamprate" is the sampling rate used when reading events.
% "plots_wanted" is a cell array containing zero or more of 'oneplot',
%   'perchannel', 'pertrial', and 'stripchart', controlling which plots are
%   produced.
% "window_sizes" is a cell array. Each cell contains a plot time range
%   [ begin end ] in seconds, or [] for the full data extent.
% "size_labels" is a cell array containing filename-safe labels used when
%   creating filenames and annotating titles for plots of each window size.
% "max_count_per_size" is a scalar indicating the maximum number of plots
%   to emit at a given size level. Set to inf to not decimate plots.
% "figtitle" is the prefix used when generating figure titles.
% "obase" is the prefix used when generating output filenames.


% Magic number for pretty display.
maxlegendsize = 20;

% Get a scratch figure.
thisfig = figure();


% Extract event series.

evcodes = struct([]);
evrwdA = struct([]);
evrwdB = struct([]);

if isfield(evlists, 'cookedcodes')
  evcodes = evlists.cookedcodes;
end
if isfield(evlists, 'rwdA')
  evrwdA = evlists.rwdA;
end
if isfield(evlists, 'rwdB')
  evrwdB = evlists.rwdB;
end


% Get metadata.

chanlist = wavedata_ft.label;
chancount = length(chanlist);

trialcount = length(wavedata_ft.time);


% Convert whatever we were given for trial names into text labels.
trialnames = euPlot_helperMakeTrialNames(trialnames, trialcount);


% If we were passed an empty trial definition table, make one with bogus
% information.
% This is used to time-align events. Filling it with NaN is fine; events
% all fail their "is event visible" checks.

if isempty(trialdefs)
  trialdefs = nan( [ trialcount, 3 ] );
end


% Generate the single-plot plot.

if ismember('oneplot', plots_wanted)

  legendpos = 'northeast';
  if chancount > maxlegendsize
    legendpos = 'off';
  elseif (1 == chancount) && (trialcount > maxlegendsize)
    legendpos = 'off';
  end

  wantspread = false;

  helper_plotAllZooms( thisfig, wavedata_ft, wavesamprate, ...
    trialdefs, trialnames, trialsamprate, {}, {}, ...
    evcodes, evrwdA, evrwdB, evsamprate, ...
    wantspread, legendpos, [ figtitle ' - All' ], [ obase '-all' ], ...
    window_sizes, size_labels );

end


% Generate the per-channel plots.

if ismember('perchannel', plots_wanted)

  legendpos = 'northeast';
  if trialcount > maxlegendsize
    legendpos = 'off';
  end

  wantspread = false;

  % Get an acceptance mask for channels, in case there are too many.
  wantplot = nlProc_decimateBresenham(max_count_per_size, chanlist);

  for cidx = 1:chancount
    if wantplot(cidx)
      thischan = chanlist{cidx};
      [ thischanlabel thischantitle ] = euUtil_makeSafeString(chanlist{cidx});

      helper_plotAllZooms( thisfig, wavedata_ft, wavesamprate, ...
        trialdefs, trialnames, trialsamprate, { thischan }, {}, ...
        evcodes, evrwdA, evrwdB, evsamprate, wantspread, legendpos, ...
        [ figtitle ' - ' thischantitle ], [ obase '-' thischanlabel ], ...
        window_sizes, size_labels );
    end
  end

end


% Generate the per-trial plots.

if ismember('pertrial', plots_wanted)

  legendpos = 'northeast';
  if chancount > maxlegendsize
    legendpos = 'off';
  end

  wantspread = false;

  % Get an acceptance mask for trials, in case there are too many.
  wantplot = nlProc_decimateBresenham(max_count_per_size, trialnames);

  for tidx = 1:trialcount
    if wantplot(tidx)
      [ triallabel trialtitle ] = euUtil_makeSafeString( trialnames{tidx} );

      helper_plotAllZooms( thisfig, wavedata_ft, wavesamprate, ...
        trialdefs, trialnames, trialsamprate, {}, trialnames(tidx), ...
        evcodes, evrwdA, evrwdB, evsamprate, wantspread, legendpos, ...
        [ figtitle ' - ' trialtitle ], [ obase '-' triallabel ], ...
        window_sizes, size_labels );
    end
  end

end


% Generate strip-chart plots.
% Only do this if we have more than one channel.
% We have one plot per trial.

if ismember('stripchart', plots_wanted) ...
  && (length(wavedata_ft.label) > 1)

  % The strip chart annotates each wave with the channel name, so no legend.
  legendpos = 'off';

  wantspread = true;

  % Get an acceptance mask for trials, in case there are too many.
  wantplot = nlProc_decimateBresenham(max_count_per_size, trialnames);

  for tidx = 1:trialcount
    if wantplot(tidx)
      [ triallabel trialtitle ] = euUtil_makeSafeString( trialnames{tidx} );

      helper_plotAllZooms( thisfig, wavedata_ft, wavesamprate, ...
        trialdefs, trialnames, trialsamprate, {}, trialnames(tidx), ...
        evcodes, evrwdA, evrwdB, evsamprate, wantspread, legendpos, ...
        [ figtitle ' - ' trialtitle ], [ obase '-' triallabel ], ...
        window_sizes, size_labels );
    end
  end

end


% Finished with the scratch figure.
close(thisfig);


% Done.

end


%
% Helper Functions


function helper_plotAllZooms( thisfig, wavedata_ft, wavesamprate, ...
  trialdefs, trialnames, trialsamprate, chanlist, triallist, ...
  evcodes, evrwdA, evrwdB, evsamprate, ...
  wantspread, legendpos, titlebase, obase, zoomsizes, zoomlabels )

  figure(thisfig);
  clf('reset');


  % Adjust the figure size if we're making a strip-chart plot.

  oldpos = thisfig.Position;
  newpos = oldpos;

  spread_fraction = 0.5;

  if wantspread
    chancount = length(chanlist);
    if isempty(chanlist)
      chancount = length(wavedata_ft.label);
    end

    [ oldpos newpos ] = nlPlot_makeFigureTaller( thisfig, chancount, 8 );
  end


  % Call the plotting helper for each zoom level.

  for zidx = 1:length(zoomlabels)

    thiszlabel = zoomlabels{zidx};
    thiszoom = zoomsizes{zidx};

    clf('reset');
    thisfig.Position = newpos;
    thisax = gca();

    if wantspread

      % FIXME - Kludge. Call the timelock helper!

      % FIXME - Very messy kludge to extract the desired trials and make
      % them look like timelock output.

      thisname = triallist{1};
      trialmask = strcmp(trialnames, thisname);

      wavedata_ft.time = wavedata_ft.time(trialmask);
      wavedata_ft.time = wavedata_ft.time{1};
      wavedata_ft.trial = wavedata_ft.trial(trialmask);
      scratch = wavedata_ft.trial{1};
      wavedata.ft_trial = scratch;
      wavedata_ft.avg = scratch;
      wavedata_ft.var = nan(size(scratch));
      wavedata_ft.dof = ones(size(scratch));

      euPlot_axesPlotFTTimelock( thisax, wavedata_ft, ...
        chanlist, spread_fraction, NaN, thiszoom, [], legendpos, titlebase );

    else
      euPlot_axesPlotFTTrials( thisax, wavedata_ft, wavesamprate, ...
        trialdefs, trialnames, trialsamprate, ...
        chanlist, triallist, thiszoom, {}, ...
        evcodes, evrwdA, evrwdB, evsamprate, legendpos, titlebase );
    end

    saveas( thisfig, sprintf('%s-%s.png', obase, thiszlabel) );

  end


  % Restore the original figure size.
  clf('reset');
  thisfig.Position = oldpos;


  % Done.
end



%
% This is the end of the file.
