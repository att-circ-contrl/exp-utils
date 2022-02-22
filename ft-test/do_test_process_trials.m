% Field Trip sample script / test script - Epoched data processing.
% Written by Christopher Thomas.

% This reads data according to predefined trial definitions, processes and
% saves it trial by trial, and optionally displays it using FT's browser.
% FIXME - Doing this by reading and setting workspace variables directly.
%
% Variables that get set:
% FIXME - List goes here.


% Extract various fields we'd otherwie have to keep looking up.

times_recstim_rec = times_recorder_stimulator.recTime;
times_recstim_stim = times_recorder_stimulator.stimTime;

gamecoderectime = [];
gamerwdArectime = [];
gamerwdBrectime = [];
if ~isempty(gamecodes) ; gamecoderectime = gamecodes.recTime ; end
if ~isempty(gamerwdA)  ; gamerwdArectime = gamerwdA.recTime  ; end
if ~isempty(gamerwdB)  ; gamerwdBrectime = gamerwdB.recTime  ; end


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

        [ batchdata_rec_lfp batchdata_rec_spike batchdata_rec_rect ] = ...
          doFeatureFiltering( batchdata_rec_wb, ...
            lfp_corner, lfp_rate, spike_corner, ...
            rect_corners, rect_lowpass, rect_rate );

        if want_reref && isfield( thisdataset, 'commonrefs_rec' )
          batchdata_rec_lfp = doCommonAverageReference( ...
            batchdata_rec_lfp, thisdataset.commonrefs_rec );
        end
      end


      disp([ '.. Reading stimulator data for batch "' thisbatchlabel '".' ]);

      % Convert trial definition samples to stimulator samples.

      thisstart = thisbatchtrials_rec(:,1);
      thisend = thisbatchtrials_rec(:,2);
      thisoffset = thisbatchtrials_rec(:,3);

      thisstart = thisstart / rechdr.Fs;
      thisstart = euAlign_interpolateSeries( ...
        times_recstim_rec, times_recstim_stim, thisstart );
      thisstart = round(thisstart * stimhdr.Fs);

      thisend = thisend / rechdr.Fs;
      thisend = euAlign_interpolateSeries( ...
        times_recstim_rec, times_recstim_stim, thisend );
      thisend = round(thisend * stimhdr.Fs);

      thisoffset = round(thisoffset * stimhdr.Fs / rechdr.Fs);

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

        [ batchdata_stim_lfp batchdata_stim_spike batchdata_stim_rect ] = ...
          doFeatureFiltering( batchdata_stim_wb, ...
            lfp_corner, lfp_rate, spike_corner, ...
            rect_corners, rect_lowpass, rect_rate );

        if want_reref && isfield( thisdataset, 'commonrefs_stim' )
          batchdata_stim_lfp = doCommonAverageReference( ...
            batchdata_stim_lfp, thisdataset.commonrefs_stim );
        end
      end


      disp([ '.. Copying Unity data for batch "' thisbatchlabel '".' ]);

      % NOTE - We've loaded "events_aligned.mat" when building trial
      % definitions. This gives us "gamecodes", "gamerwdA", and "gamerwdB",
      % among other things. Those are the events that we care about.

      % We always "have" event data, but a batch or a trial may have 0 events.

      batchevents_codes = {};
      batchevents_rwdA = {};
      batchevents_rwdB = {};

      for tidx = 1:height(thisbatchtable_rec)
        thisrectimestart = thisbatchtable_rec.rectimestart(tidx);
        thisrectimeend = thisbatchtable_rec.rectimeend(tidx);

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

% FIXME - Unity frame data NYI. Need to load this.
% FIXME - Unity gaze data NYI. Need to load this.

      %
      % Save this batch of trial data.

      disp([ '.. Saving trial batch "' thisbatchlabel '".' ]);


% NOTE - Variables being saved per batch.
%
% thisbatchlabel
% thisbatchtrials_rec
% thisbatchtrials_stim  (only the three mandatory columns)
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

      save( fname_batch, ...
        'thisbatchlabel', 'thisbatchtrials_rec', 'thisbatchtable_rec', ...
        'trialdefcolumns', 'thisbatchtrials_stim', ...
        'have_batchdata_rec', 'batchdata_rec_wb', 'batchdata_rec_lfp', ...
        'batchdata_rec_spike', 'batchdata_rec_rect', ...
        'have_batchdata_stim', 'batchdata_stim_wb', 'batchdata_stim_lfp', ...
        'batchdata_stim_spike', 'batchdata_stim_rect', ...
        'batchevents_codes', 'batchevents_rwdA', 'batchevents_rwdB', ...
        '-v7.3' );

      disp([ '.. Finished saving.' ]);
    end


    % Generate plots for this batch, if appropriate.

    if want_plots && ismember(bidx, plotbatches)

      disp([ '.. Plotting trial batch "' thisbatchlabel '".' ]);

      fbase_plot = [ plotdir filesep 'trials' ];

      % FIXME - Omitting gaze data for now.
      doPlotBatchTrials( fbase_plot, thisbatchlabel, thisbatchtable_rec, ...
        batchdata_rec_wb, batchdata_rec_lfp, batchdata_rec_spike, ...
        batchdata_rec_rect, batchdata_stim_wb, batchdata_stim_lfp, ...
        batchdata_stim_spike, batchdata_stim_rect, ...
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

      % FIXME - Not browsing event data or frame data or gaze data.

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


% Save batch metadata.

fname = [ datadir filesep 'batchmetadata.mat' ];
save( fname, 'trialbatchmeta', '-v7.3' );


% Banner.
disp('== Finished processing epoched trial data.');


%
% This is the end of the file.
