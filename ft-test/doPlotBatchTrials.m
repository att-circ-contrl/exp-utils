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
timeranges = struct( 'wide', 'auto', 'detail', [ -0.1 0.1 ] );

helper_plotStack( [ obase '-lfp' ], ...
  sprintf( 'Trials - %s - LFP', batchlabel ), ...
  batchtrialtable, ymax_lfp, timeranges, ...
  ft_rec_lfp, ft_stim_lfp, events_codes, events_rwdA, events_rwdB );

helper_plotStack( [ obase '-rect' ], ...
  sprintf( 'Trials - %s - Activity', batchlabel ), ...
  batchtrialtable, ymax_rect, timeranges, ...
  ft_rec_rect, ft_stim_rect, events_codes, events_rwdA, events_rwdB );

% Add a third zoom level for high-pass and wideband.
% Wideband won't benefit from it, due to 60 Hz noise, but do it anyways.
timeranges.('fine') = [ -0.01 0.01 ];

helper_plotStack( [ obase '-wb' ], ...
  sprintf( 'Trials - %s - Wideband', batchlabel ), ...
  batchtrialtable, ymax_wb, timeranges, ...
  ft_rec_wb, ft_stim_wb, events_codes, events_rwdA, events_rwdB );

helper_plotStack( [ obase '-hp' ], ...
  sprintf( 'Trials - %s - High-Pass', batchlabel ), ...
  batchtrialtable, ymax_hp, timeranges, ...
  ft_rec_spike, ft_stim_spike, events_codes, events_rwdA, events_rwdB );


% Done.

end


%
% Helper functions.


% This plots sets of stacked trial waveforms for a given filter case.
% FIXME - This hard-codes a lot of fragile appearance information.

function helper_plotStack( ...
  fbase, figtitle, batchdefs, maxyval, timeranges, ...
  ft_recdata, ft_stimdata, events_codes, events_rwdA, events_rwdB )

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

  recrate = 1000;
  stimrate = 1000;

  recchans = 0;
  stimchans = 0;

  if ~isempty(ft_recdata)
    recrate = ft_recdata.fsample;
    recchans = length(ft_recdata.label);
  end

  if ~isempty(ft_stimdata)
    stimrate = ft_stimdata.fsample;
    stimchans = length(ft_stimdata.label);
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
  palette_codes = nlPlot_getColorSpread(cols.red, trialcount, 40);
  palette_rwdA = nlPlot_getColorSpread(cols.brn, trialcount, 40);
  palette_rwdB = nlPlot_getColorSpread(cols.mag, trialcount, 40);


  %
  % Render the figures and save them.

  thisfig = figure();

  % One output figure per recording channel.
  for cidx = 1:recchans
    for zidx = 1:length(timelabels)

      thiszoom = timelabels{zidx};

      figure(thisfig);
      clf('reset');

      thislabel = ft_recdata.label{cidx};
      thislabel = strrep(thislabel, '_', ' ');
      title(sprintf( '%s - %s', figtitle, thislabel ));

      xlim( timeranges.(thiszoom) );
      ylim( plotyrange );
      xlabel('Time (s)');
      ylabel('Amplitude (a.u.)');

      hold on;

      for tidx = 1:trialcount
        thiswave = ft_recdata.trial{tidx}(cidx,:);
        sampcount = length(thiswave);
        thistimes = 0:(sampcount-1);
        thistimes = (thistimes / recrate) + firsttimes(tidx) - reftimes(tidx);

        plot( thistimes, thiswave, 'Color', palette_waves{tidx}, ...
          'DisplayName', sprintf('trial %d', tidx) );
      end

      hold off;

      saveas(thisfig, sprintf('%s-%s-ch%04d.png', fbase, thiszoom, cidx));

    end
  end

  close(thisfig);

end



%
% This is the end of the file.
