function doPlotBatchTrials( obase, batchlabel, batchtrialtable, ...
  ft_rec_wb, ft_rec_lfp, ft_rec_spike, ft_rec_rect, ...
  ft_stim_wb, ft_stim_lfp, ft_stim_spike, ft_stim_rect, ...
  events_codes, events_rwdA, events_rwdB )

% function doPlotBatchTrials( obase, batchlabel, batchtrialtable, ...
%   ft_rec_wb, ft_rec_lfp, ft_rec_spike, ft_rec_rect, ...
%   ft_stim_wb, ft_stim_lfp, ft_stim_spike, ft_stim_rect, ...
%   events_codes, events_rwdA, events_rwdB )
%
% This generates stacked plots for a batch of trials.
%
% "obase" is the prefix to use when building filenames.
% "batchlabel" is a filename-safe string identifying this batch of trials.
% "batchtrialtable" is a table providing trial definitions for the trials in
%   this batch. Relevant columns are "trialindex", "trialnum",
%   "rectimestart", "rectimeend", and "rectimeevent".
% "ft_rec_wb" is a Field Trip raw data structure with wideband waveforms from
%   the ephys recorder.
% "ft_rec_lfp" is a Field Trip raw data structure with LFP waveforms from
%   the ephys recorder.
% "ft_rec_spike" is a Field Trip raw data structure with high-pass waveforms
%   from the ephys recorder.
% "ft_rec_rect" is a Field Trip raw data structure with rectified activity
%   waveforms from the ephys recorder.
% "ft_stim_wb" is a Field Trip raw data structure with wideband waveforms from
%   the ephys stimulator.
% "ft_stim_lfp" is a Field Trip raw data structure with LFP waveforms from
%   the ephys stimulator.
% "ft_stim_spike" is a Field Trip raw data structure with high-pass waveforms
%   from the ephys stimulator.
% "ft_stim_rect" is a Field Trip raw data structure with rectified activity
%   waveforms from the ephys stimulator.
% "events_codes" is a table containing event codes for each trial's span.
% "events_rwdA" is a table containing "reward A" events for each trial's span.
% "events_rwdB" is a table containing "reward B" events for each trial's span.


% FIXME - Hardcoding Y range to fit the datasets we have.
ymax_wb = 600;
ymax_lfp = 200;
ymax_hp = 300;
ymax_rect = 50;


% FIXME - Hardcoding time ranges to get readable plots.

rangeclose = [ -0.2 0.4 ];
rangedetail = [ -0.1 0.1 ];
rangefine = [ -0.01 0.01 ];


% For wideband, we just want "wide" and "detail".
% Most of what we're seeing is noise, and the fact that spikes exist.
timeranges = ...
  struct( 'wide', 'auto', 'detail', rangedetail );

helper_plotStack( [ obase '-rec-wb' ], ...
  sprintf( 'Trials - %s - Rec Wideband', batchlabel ), ...
  batchtrialtable, ymax_wb, timeranges, ...
  ft_rec_wb, events_codes, events_rwdA, events_rwdB );

helper_plotStack( [ obase '-stim-wb' ], ...
  sprintf( 'Trials - %s - Stim Wideband', batchlabel ), ...
  batchtrialtable, ymax_wb, timeranges, ...
  ft_stim_wb, events_codes, events_rwdA, events_rwdB );


% For LFP and rectified activity, add "close".
% This is a wide enough range that we can see response to cues.
timeranges.('close') = rangeclose;

helper_plotStack( [ obase '-rec-lfp' ], ...
  sprintf( 'Trials - %s - Rec LFP', batchlabel ), ...
  batchtrialtable, ymax_lfp, timeranges, ...
  ft_rec_lfp, events_codes, events_rwdA, events_rwdB );

helper_plotStack( [ obase '-stim-lfp' ], ...
  sprintf( 'Trials - %s - Stim LFP', batchlabel ), ...
  batchtrialtable, ymax_lfp, timeranges, ...
  ft_stim_lfp, events_codes, events_rwdA, events_rwdB );

helper_plotStack( [ obase '-rec-rect' ], ...
  sprintf( 'Trials - %s - Rec Activity', batchlabel ), ...
  batchtrialtable, ymax_rect, timeranges, ...
  ft_rec_rect, events_codes, events_rwdA, events_rwdB );

helper_plotStack( [ obase '-stim-rect' ], ...
  sprintf( 'Trials - %s - Stim Activity', batchlabel ), ...
  batchtrialtable, ymax_rect, timeranges, ...
  ft_stim_rect, events_codes, events_rwdA, events_rwdB );


% For spikes, add "fine", so that we can see spike waveforms.
timeranges.('fine') = rangefine;

helper_plotStack( [ obase '-rec-hp' ], ...
  sprintf( 'Trials - %s - Rec High-Pass', batchlabel ), ...
  batchtrialtable, ymax_hp, timeranges, ...
  ft_rec_spike, events_codes, events_rwdA, events_rwdB );

helper_plotStack( [ obase '-stim-hp' ], ...
  sprintf( 'Trials - %s - Stim High-Pass', batchlabel ), ...
  batchtrialtable, ymax_hp, timeranges, ...
  ft_stim_spike, events_codes, events_rwdA, events_rwdB );


% Done.

end


%
% Helper functions.


% This plots sets of stacked trial waveforms for a given filter case.
% FIXME - This hard-codes a lot of fragile appearance information.

function helper_plotStack( ...
  fbase, figtitle, batchdefs, maxyval, timeranges, ...
  ft_wavedata, events_codes, events_rwdA, events_rwdB )

  %
  % Extract selected metadata.

  trialcount = height(batchdefs);
  firsttimes = [];
  lasttimes = [];
  reftimes = [];
  if ~isempty(batchdefs)
    firsttimes = batchdefs.rectimestart;
    lasttimes = batchdefs.rectimeend;
    reftimes = batchdefs.rectimeevent;
  end

  waverate = 1000;
  wavechans = 0;

  if ~isempty(ft_wavedata)
    waverate = ft_wavedata.fsample;
    wavechans = length(ft_wavedata.label);
  end

  timelabels = fieldnames(timeranges);

  plotyrange = [ -maxyval maxyval ];


  %
  % Build a decent colour palette.

  % We need to be able to distinguish each _type_ of information as well as
  % trials within each type. We probably won't be able to do the latter,
  % but try.

  cols = nlPlot_getColorPalette();

  palette_waves = nlPlot_getColorSpread(cols.grn, trialcount, 180);

  % These are cursors, so making them visually distinct from each other is
  % more important than making them visually distinct from the waveforms.
  % There are a lot of event codes per frame, so make them a fainter colour.
  % FIXME - Getting this to look not-ugly involves a lot of hand-tweaking.
  palette_codes = nlPlot_getColorSpread(cols.cyn, trialcount, 20);
  palette_rwdA = nlPlot_getColorSpread(cols.brn, trialcount, 30);
  palette_rwdB = nlPlot_getColorSpread(cols.mag, trialcount, 60);


  %
  % Render the figures and save them.

  thisfig = figure();

  % One output figure per channel.
  for cidx = 1:wavechans

    % We only need to plot the figure once; we'll call "xlim" for each
    % zoom level.

    figure(thisfig);
    clf('reset');

    thislabelraw = ft_wavedata.label{cidx};
    thislabel = strrep(thislabelraw, '_', ' ');
    title(sprintf( '%s - %s', figtitle, thislabel ));

    ylim( plotyrange );
    xlabel('Time (s)');
    ylabel('Amplitude (a.u.)');

    hold on;

    % Render event cursors first, so that they're behind the waves.

    for tidx = 1:trialcount
      thistable = events_codes{tidx};
      for eidx = 1:height(thistable)
        thistime = thistable.recTime(eidx) - reftimes(tidx);
        plot( [ thistime thistime ], plotyrange, ...
          'Color', palette_codes{tidx}, ...
          'DisplayName', sprintf('trial %d codes', tidx) );
      end
    end

    for tidx = 1:trialcount
      thistable = events_rwdA{tidx};
      for eidx = 1:height(thistable)
        thistime = thistable.recTime(eidx) - reftimes(tidx);
        plot( [ thistime thistime ], plotyrange, ...
          'Color', palette_rwdA{tidx}, ...
          'DisplayName', sprintf('trial %d rwdA', tidx) );
      end
    end

    for tidx = 1:trialcount
      thistable = events_rwdB{tidx};
      for eidx = 1:height(thistable)
        thistime = thistable.recTime(eidx) - reftimes(tidx);
        plot( [ thistime thistime ], plotyrange, ...
          'Color', palette_rwdB{tidx}, ...
          'DisplayName', sprintf('trial %d rwdB', tidx) );
      end
    end

    % Now render the waves.

    for tidx = 1:trialcount
      thiswave = ft_wavedata.trial{tidx}(cidx,:);
      sampcount = length(thiswave);
      thistimes = 0:(sampcount-1);
      thistimes = (thistimes / waverate) + firsttimes(tidx);
      thistimes = thistimes - reftimes(tidx);

      plot( thistimes, thiswave, 'Color', palette_waves{tidx}, ...
        'DisplayName', sprintf('trial %d', tidx) );
    end

    hold off;

    % Iterate zoom ranges, saving one figure per zoom level.
    for zidx = 1:length(timelabels)
      thiszoom = timelabels{zidx};

      xlim( timeranges.(thiszoom) );

      % NOTE - Use the channel label, not the index, for readability.
%      saveas(thisfig, sprintf('%s-%s-ch%04d.png', fbase, thiszoom, cidx));
      saveas(thisfig, sprintf('%s-%s-%s.png', fbase, thiszoom, thislabelraw));
    end
  end

  % Reset before closing, just in case of memory leaks.
  figure(thisfig);
  clf('reset');

  close(thisfig);

end



%
% This is the end of the file.
