% Field Trip sample script / test script - Epoched data processing.
% Written by Christopher Thomas.

% This reads data according to predefined trial definitions, processes and
% saves it trial by trial, and optionally displays it using FT's browser.
% FIXME - Doing this by reading and setting workspace variables directly.
%
% NOTE - Most data is computed per-batch and saved to per-batch files,
% rather than saved in workspace variables.
%
%
% Data that persists in workspace variables:
%
% trialbatchmeta
%
%
% Variables saved per-batch:
%
% thisbatchlabel
% thisbatchtrials_rec
% thisbatchtrials_stim  (only the three mandatory columns)
% thisbatchtrials_gaze  (only the three mandatory columns)
% thisbatchtable_rec  (same as trials_rec but with column headings)
% trialdefcolumns
%
% have_batchdata_rec
% batchdata_rec_wb
% batchdata_rec_lfp
% batchdata_rec_spike
% batchdata_rec_rect
%
% have_batchdata_stim
% batchdata_stim_wb
% batchdata_stim_lfp
% batchdata_stim_spike
% batchdata_stim_rect
%
% batchevents_codes
% batchevents_rwdA
% batchevents_rwdB
%
% batchrows_gaze
% batchrows_frame
%
% batchdata_gaze


%
% Load cached data if we don't already have it.

% Trial definitions.

if ~exist('trialdefs', 'var')
  fname_trialdefs = [ datadir filesep 'trialmetadata.mat' ];
  if ~isfile(fname_trialdefs)
    error('Can''t process trials without trial definitions.');
  else
    disp('-- Loading trial definitions.');
    load(fname_trialdefs);
    disp('-- Finished loading.');
  end
end

% "Game" event lists and recorder/stimulator time translation table.

if (~exist('gamecodes', 'var')) ...
  || (~exist('times_recorder_stimulator', 'var'))

  fname_events = [ datadir filesep 'events_aligned.mat' ];

  if ~isfile(fname_events)
    % We can live without events, but we need the alignment tables.
    error('Can''t process trials without recorder/stimulator alignment.');
  else
    disp('-- Loading time-aligned Unity events and alignment tables.');
    load(fname_events);
    disp('-- Finished loading.');
  end

end

% Get frame and gaze data tables.

if ~exist('gamegaze_raw', 'var')
  fname_gaze = [ datadir filesep 'gaze_aligned.mat' ];
  if ~isfile(fname_gaze)
    error('Can''t find gaze data for creating trials.');
  else
    disp('-- Loading time-aligned gaze data.');
    load(fname_gaze);
    disp('-- Finished loading.');
  end
end

if ~exist('gameframedata_raw', 'var')
  fname_frame = [ datadir filesep 'frame_aligned.mat' ];
  if ~isfile(fname_frame)
    error('Can''t find frame data for creating trials.');
  else
    disp('-- Loading time-aligned frame data.');
    load(fname_frame);
    disp('-- Finished loading.');
  end
end


% Extract various fields we'd otherwise have to keep looking up.

% FIXME - Tolerate failure to align recorder and stimulator.
if ~isempty(times_recorder_stimulator)
  times_recstim_rec = times_recorder_stimulator.recTime;
  times_recstim_stim = times_recorder_stimulator.stimTime;
end

gamecoderectime = [];
gamerwdArectime = [];
gamerwdBrectime = [];
if ~isempty(gamecodes) ; gamecoderectime = gamecodes.recTime ; end
if ~isempty(gamerwdA)  ; gamerwdArectime = gamerwdA.recTime  ; end
if ~isempty(gamerwdB)  ; gamerwdBrectime = gamerwdB.recTime  ; end

gamegazerectime = [];
gameframerectime = [];
if ~isempty(gamegaze_raw) ; gamegazerectime = gamegaze_raw.recTime ; end
if ~isempty(gameframedata_raw)
  gameframerectime = gameframedata_raw.recTime;
end


% Set up the table reader to read from FrameData.

% FIXME - Windows get clamped to the time ranges specified here, so the time
% range given here matters. We should calculate the maximum recTime timestamp
% we'd have in the ephys data, but instead just pad the last gaze recTime by
% 10 seconds.

maxgameframerectime = 10.0;
if ~isempty(gameframerectime)
  maxgameframerectime = max(gameframerectime) + 10.0;
end
nlFT_initReadTable( gameframedata_raw, frame_gaze_cols, 'recTime', ...
  0.0, maxgameframerectime, gaze_rate, gaze_rate );


%
% Process trials.

% Banner.
disp('== Processing epoched trial data.');

trialcases = fieldnames(trialdefs);
trialbatchmeta = struct();

for caseidx = 1:length(trialcases)

  % Get alignment case metadata.

  thiscaselabel = trialcases{caseidx};
  thistrialdefs = trialdefs.(thiscaselabel);
  thistrialdeftable = trialdeftables.(thiscaselabel);


  % Split this case's trials into batches small enough to process.

  % Default to monolithic.

  trialcount = size(thistrialdefs);
  trialcount = trialcount(1);

  batchlabels = { thiscaselabel };
  batchtrialdefs = { thistrialdefs };
  batchtrialdeftables = { thistrialdeftable };

  % If we have too many trials, break it into batches.

  if trialcount > trials_per_batch
    batchlabels = {};
    batchtrialdefs = {};
    trialsfirst = 1:trials_per_batch:trialcount;
    trialslast = min(( trialsfirst + trials_per_batch - 1), trialcount );

    for bidx = 1:length(trialsfirst)
      thistrialfirst = trialsfirst(bidx);
      thistriallast = trialslast(bidx);

      batchlabels{bidx} = sprintf('%s-batch%04d', thiscaselabel, bidx);
      batchtrialdefs{bidx} = ...
        thistrialdefs(thistrialfirst:thistriallast,:);
      batchtrialdeftables{bidx} = ...
        thistrialdeftable(thistrialfirst:thistriallast,:);
    end
  end


  % Identify certain special batches, for debugging.

  earlybatch = round(1 + 0.2 * length(batchlabels));
  earlybatch = min(earlybatch, length(batchlabels));
  middlebatch = round(1 + 0.5 * length(batchlabels));
  middlebatch = min(middlebatch, length(batchlabels));
  latebatch = round(1 + 0.8 * length(batchlabels));
  latebatch = min(latebatch, length(batchlabels));


  %
  % Process this case's trial batches.

  % NOTE - There's a debug switch to process only a single batch, for testing.

  batchspan = 1:length(batchlabels);
  if want_one_batch
    batchspan = middlebatch:middlebatch;
  end

  plotbatches = [ earlybatch middlebatch latebatch ];

  for bidx = batchspan

    thisbatchlabel = batchlabels{bidx};
    thisbatchtrials_rec = batchtrialdefs{bidx};
    % This has the same information as "trials", but has column labels.
    thisbatchtable_rec = batchtrialdeftables{bidx};

    fname_batch = [ datadir filesep 'trials-' thisbatchlabel '.mat' ];
    need_save = false;

    if want_cache_epoched && isfile(fname_batch)

      %
      % Load the data we previously processed.

      disp([ '.. Loading batch "' thisbatchlabel '".' ]);
      load(fname_batch);
      disp([ '.. Finished loading.' ]);

    else

      %
      % Rebuild data for this set of trials.


      disp([ '.. Reading recorder data for batch "' thisbatchlabel '".' ]);

      % Read and process recorder trials.
      % Sample counts are fine as-is.

      preproc_config_rec.trl = thisbatchtrials_rec;

      % Turn off the progress bar.
      preproc_config_rec.feedback = 'no';

      have_batchdata_rec = false;

      batchdata_rec_wb = struct([]);
      batchdata_rec_lfp = struct([]);
      batchdata_rec_spike = struct([]);
      batchdata_rec_rect = struct([]);

      if ~isempty(rec_channels_ephys)
        preproc_config_rec.channel = rec_channels_ephys;
        batchdata_rec_wb = ft_preprocessing(preproc_config_rec);
        have_batchdata_rec = true;

        % De-trend and remove power line noise.
        extra_notches = [];
        if isfield( thisdataset, 'extra_notches' )
          extra_notches = thisdataset.extra_notches;
        end
        batchdata_rec_wb = doSignalConditioning( batchdata_rec_wb, ...
          power_freq, power_filter_modes, extra_notches );

        % Extract processed signals of interest.
        [ batchdata_rec_lfp batchdata_rec_spike batchdata_rec_rect ] = ...
          euFT_getDerivedSignals( batchdata_rec_wb, ...
            lfp_corner, lfp_rate, spike_corner, ...
            rect_corners, rect_lowpass, rect_rate );

        if want_reref && isfield( thisdataset, 'commonrefs_rec' )
          batchdata_rec_lfp = doCommonAverageReference( ...
            batchdata_rec_lfp, thisdataset.commonrefs_rec );
        end
      end


      disp([ '.. Reading stimulator data for batch "' thisbatchlabel '".' ]);

      % Convert recorder trial definition samples to stimulator samples.
      % Remember that sample indices are 1-based.

      thisstart = thisbatchtrials_rec(:,1);
      thisend = thisbatchtrials_rec(:,2);
      thisoffset = thisbatchtrials_rec(:,3);

      % FIXME - Tolerate failure to align recorder and stimulator.
      if ~isempty(times_recorder_stimulator)
        thisstart = (thisstart - 1) / rechdr.Fs;
        thisstart = nlProc_interpolateSeries( ...
          times_recstim_rec, times_recstim_stim, thisstart );
        thisstart = 1 + round(thisstart * stimhdr.Fs);

        thisend = (thisend - 1) / rechdr.Fs;
        thisend = nlProc_interpolateSeries( ...
          times_recstim_rec, times_recstim_stim, thisend );
        thisend = 1 + round(thisend * stimhdr.Fs);
      end

      thisoffset = 1 + round((thisoffset - 1) * stimhdr.Fs / rechdr.Fs);

      thisbatchtrials_stim = [];
      thisbatchtrials_stim(:,1) = thisstart;
      thisbatchtrials_stim(:,2) = thisend;
      thisbatchtrials_stim(:,3) = thisoffset;

      % Read and process stimulator trials.

      preproc_config_stim.trl = thisbatchtrials_stim;

      % Turn off the progress bar.
      preproc_config_stim.feedback = 'no';

      have_batchdata_stim = false;

      batchdata_stim_wb = struct([]);
      batchdata_stim_lfp = struct([]);
      batchdata_stim_spike = struct([]);
      batchdata_stim_rect = struct([]);

      if ~isempty(stim_channels_ephys)
        preproc_config_stim.channel = stim_channels_ephys;
        batchdata_stim_wb = ft_preprocessing(preproc_config_stim);
        have_batchdata_stim = true;

        % De-trend and remove power line noise.
        extra_notches = [];
        if isfield( thisdataset, 'extra_notches' )
          extra_notches = thisdataset.extra_notches;
        end
        batchdata_stim_wb = doSignalConditioning( batchdata_stim_wb, ...
          power_freq, power_filter_modes, extra_notches );

        % Extract processed signals of interest.
        [ batchdata_stim_lfp batchdata_stim_spike batchdata_stim_rect ] = ...
          euFT_getDerivedSignals( batchdata_stim_wb, ...
            lfp_corner, lfp_rate, spike_corner, ...
            rect_corners, rect_lowpass, rect_rate );

        if want_reref && isfield( thisdataset, 'commonrefs_stim' )
          batchdata_stim_lfp = doCommonAverageReference( ...
            batchdata_stim_lfp, thisdataset.commonrefs_stim );
        end
      end


      disp([ '.. Copying Unity event data for batch "' thisbatchlabel '".' ]);

      % NOTE - We've loaded "events_aligned.mat" when building trial
      % definitions. This gives us "gamecodes", "gamerwdA", and "gamerwdB",
      % among other things. Those are the events that we care about.

      % We always "have" event data, but a batch or a trial may have 0 events.

      batchevents_codes = {};
      batchevents_rwdA = {};
      batchevents_rwdB = {};

      for tidx = 1:height(thisbatchtable_rec)
        thisrectimestart = thisbatchtable_rec.timestart(tidx);
        thisrectimeend = thisbatchtable_rec.timeend(tidx);

        thistrial_codes = table();
        thistrial_rwdA = table();
        thistrial_rwdB = table();

        if ~isempty(gamecodes)
          thismask = (gamecoderectime >= thisrectimestart) ...
            & (gamecoderectime <= thisrectimeend);
          thistrial_codes = gamecodes( thismask, : );
        end

        if ~isempty(gamerwdA)
          thismask = (gamerwdArectime >= thisrectimestart) ...
            & (gamerwdArectime <= thisrectimeend);
          thistrial_rwdA = gamerwdA( thismask, : );
        end

        if ~isempty(gamerwdB)
          thismask = (gamerwdBrectime >= thisrectimestart) ...
            & (gamerwdBrectime <= thisrectimeend);
          thistrial_rwdB = gamerwdB( thismask, : );
        end

        batchevents_codes{tidx} = thistrial_codes;
        batchevents_rwdA{tidx} = thistrial_rwdA;
        batchevents_rwdB{tidx} = thistrial_rwdB;
      end


      disp([ ...
  '.. Copying Unity "FrameData" and "GazeData" rows for batch "' ...
        thisbatchlabel '".' ]);

      batchrows_gaze = {};
      batchrows_frame = {};

      for tidx = 1:height(thisbatchtable_rec)
        thisrectimestart = thisbatchtable_rec.timestart(tidx);
        thisrectimeend = thisbatchtable_rec.timeend(tidx);

        thistrial_gaze = table();
        thistrial_frame = table();

        if ~isempty(gamegaze_raw)
          thismask = (gamegazerectime >= thisrectimestart) ...
            & (gamegazerectime <= thisrectimeend);
          thistrial_gaze = gamegaze_raw( thismask, : );
        end

        if ~isempty(gameframedata_raw)
          thismask = (gameframerectime >= thisrectimestart) ...
            & (gameframerectime <= thisrectimeend);
          thistrial_frame = gameframedata_raw( thismask, : );
        end

        batchrows_gaze{tidx} = thistrial_gaze;
        batchrows_frame{tidx} = thistrial_frame;
      end


      disp( '.. Converting cooked gaze coordinates to waveforms.' );

      % NOTE - The raw gaze information in "gamegaze_raw" is in three
      % different eye-tracker-specific coordinate systems. We're not going
      % to deal with that headache here. There's cooked gaze information in
      % "framedata_raw", which should be adequate for this script.

      % If you need to process the original high-sampling-rate raw data,
      % the same function calls used here should work for converting it to
      % Field Trip format.


      % We're calling ft_read_header() and ft_read_data() with LoopUtil
      % hooks that make it read from tabular data in memory.

      % FIXME - Check for an empty table. FT really doesn't like that.
      if ~isempty(gameframedata_raw)

        % Read the header. Among other things this gives use the sampling
        % rate (that we set earlier).
        % NOTE - Field Trip tests that the file exists, so give it the
        % Unity folder, even though we're reading from a table in memory.
        gazehdr = ft_read_header( thisdataset.unityfile, ...
          'headerformat', 'nlFT_readTableHeader' );


        % Convert recorder trial definition samples to gaze samples.
        % These are already aligned to recTime 0 (sample 1); just rescale.

        thisbatchtrials_gaze = euFT_resampleTrialDefs( ...
          thisbatchtrials_rec, rechdr.Fs, gazehdr.Fs );


        % Read and process gaze trials.

        % NOTE - Field Trip tests that the file exists, so give it the
        % Unity folder.
        preproc_config_gaze = struct( ...
          'headerfile', thisdataset.unityfile, ...
          'datafile', thisdataset.unityfile, ...
          'headerformat', 'nlFT_readTableHeader', ...
          'dataformat', 'nlFT_readTableData', ...
          'trl', thisbatchtrials_gaze );

        % Turn off the progress bar.
        preproc_config_gaze.feedback = 'no';

        % Select channels.
        preproc_config_gaze.channel = ...
          ft_channelselection( frame_gaze_cols, gazehdr.label, {} );

        % Read the gaze data out of the table.
        batchdata_gaze = ft_preprocessing(preproc_config_gaze);

      else
        % We didn't have gaze data.
        thisbatchtrials_gaze = [];
        batchdata_gaze = struct([]);
      end

      %
      % Save this batch of trial data.

      disp([ '.. Saving trial batch "' thisbatchlabel '".' ]);


% NOTE - Variables being saved per batch.
%
% thisbatchlabel
% thisbatchtrials_rec
% thisbatchtrials_stim  (only the three mandatory columns)
% thisbatchtrials_gaze  (only the three mandatory columns)
% thisbatchtable_rec  (same as trials_rec but with column headings)
% trialdefcolumns
%
% have_batchdata_rec
% batchdata_rec_wb
% batchdata_rec_lfp
% batchdata_rec_spike
% batchdata_rec_rect
%
% have_batchdata_stim
% batchdata_stim_wb
% batchdata_stim_lfp
% batchdata_stim_spike
% batchdata_stim_rect
%
% batchevents_codes
% batchevents_rwdA
% batchevents_rwdB
%
% batchrows_gaze
% batchrows_frame
%
% batchdata_gaze

      save( fname_batch, ...
        'thisbatchlabel', 'thisbatchtrials_rec', 'thisbatchtable_rec', ...
        'trialdefcolumns', 'thisbatchtrials_stim', 'thisbatchtrials_gaze', ...
        'have_batchdata_rec', 'batchdata_rec_wb', 'batchdata_rec_lfp', ...
        'batchdata_rec_spike', 'batchdata_rec_rect', ...
        'have_batchdata_stim', 'batchdata_stim_wb', 'batchdata_stim_lfp', ...
        'batchdata_stim_spike', 'batchdata_stim_rect', ...
        'batchevents_codes', 'batchevents_rwdA', 'batchevents_rwdB', ...
        'batchrows_gaze', 'batchrows_frame', 'batchdata_gaze', ...
        '-v7.3' );

      disp([ '.. Finished saving.' ]);
    end


    % Generate plots for this batch, if appropriate.

    if want_plots && ismember(bidx, plotbatches)

      disp([ '.. Plotting trial batch "' thisbatchlabel '".' ]);

      fbase_plot = [ plotdir filesep 'trials' ];

      doPlotBatchTrials( fbase_plot, thisbatchlabel, thisbatchtable_rec, ...
        batchdata_rec_wb, batchdata_rec_lfp, batchdata_rec_spike, ...
        batchdata_rec_rect, batchdata_stim_wb, batchdata_stim_lfp, ...
        batchdata_stim_spike, batchdata_stim_rect, batchdata_gaze, ...
        batchevents_codes, batchevents_rwdA, batchevents_rwdB );

      close all;

      disp([ '.. Finished plotting.' ]);

    end


    % If this is the batch we want to display, display it.

    if want_browser && (bidx == middlebatch)

      disp([ '-- Rendering waveforms for batch "' thisbatchlabel '".' ]);

      doBrowseFiltered( 'Rec', batchdata_rec_wb, batchdata_rec_lfp, ...
        batchdata_rec_spike, batchdata_rec_rect );
      doBrowseFiltered( 'Stim', batchdata_stim_wb, batchdata_stim_lfp, ...
        batchdata_stim_spike, batchdata_stim_rect );

      % FIXME - Not browsing event data or frame table data or gaze table data.

      % Do browse gaze _waveform_ data.
      doBrowseWave( batchdata_gaze, 'Gaze' );

      disp('-- Press any key to continue.');
      pause;

      close all;

    end

  end


  % Record batch metadata.

  % Remember to wrap cell arrays in {}.
  trialbatchmeta.(thiscaselabel) = struct( ...
    'batchlabels', { batchlabels }, 'batchtrialdefs', { batchtrialdefs }, ...
    'batchtrialdeftables', { batchtrialdeftables } );


  % Finished with this alignment case.

end


% Release memory taken up by the table reader.
nlFT_initReadTable( table(), {}, 'recTime', 0.0, 1.0, gaze_rate, gaze_rate );


% Save batch metadata.

fname = [ datadir filesep 'batchmetadata.mat' ];
save( fname, 'trialbatchmeta', '-v7.3' );


% Banner.
disp('== Finished processing epoched trial data.');


%
% This is the end of the file.
