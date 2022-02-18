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


% Banner.
disp('== Processing epoched trial data.');

trialcases = fieldnames(trialdefs);

for caseidx = 1:length(trialcases)

  % Get alignment case metadata.

  thiscaselabel = trialcases{caseidx};
  thistrialdefs = trialdefs.(thiscaselabel);


  % Split this case's trials into batches small enough to process.

  trialcount = size(thistrialdefs);
  trialcount = trialcount(1);

  batchlabels = { thiscaselabel };
  batchtrialdefs = { thistrialdefs };

  if trialcount > trials_per_batch
    batchlabels = {};
    batchtrialdefs = {};
    trialsfirst = 1:trials_per_batch:trialcount;
    trialslast = min(( trialsfirst + trials_per_batch - 1), trialcount );
    for bidx = 1:length(trialsfirst)
      batchlabels{bidx} = sprintf('%s-batch%04d', thiscaselabel, bidx);
      batchtrialdefs{bidx} = thistrialdefs(trialsfirst:trialslast,:);
    end
  end


  %
  % Process this case's trial batches.

  middlebatch = round(1 + 0.5 * length(batchlabels));
  middlebatch = min(middlebatch, length(batchlabels));

% FIXME - Test only the middle batch.
  for bidx = middlebatch:middlebatch
%  for bidx = 1:length(batchlabels)

    thisbatchlabel = batchlabels{bidx};
    thisbatchtrials_rec = batchtrialdefs{bidx};

    fname = [ datadir filesep 'trials-' thisbatchlabel '.mat' ];
    need_save = false;

    if want_cache_epoched && isfile(fname)

      %
      % Load the data we previously processed.

      disp([ '.. Loading batch "' thisbatchlabel '".' ]);
      load(fname);
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
      if ~isempty(rec_channels_ephys)
        preproc_config_rec.channel = rec_channels_ephys;
        batchdata_rec_wb = ft_preprocessing(preproc_config_rec);
        have_batchdata_rec = true;

        [ batchdata_rec_lfp batchdata_rec_spike batchdata_rec_rect ] = ...
          doFeatureFiltering( batchdata_rec_wb, ...
            lfp_corner, lfp_rate, spike_corner, ...
            rect_corners, rect_lowpass, rect_rate );
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
      if ~isempty(stim_channels_ephys)
        preproc_config_stim.channel = stim_channels_ephys;
        batchdata_stim_wb = ft_preprocessing(preproc_config_stim);
        have_batchdata_stim = true;

        [ batchdata_stim_lfp batchdata_stim_spike batchdata_stim_rect ] = ...
          doFeatureFiltering( batchdata_stim_wb, ...
            lfp_corner, lfp_rate, spike_corner, ...
            rect_corners, rect_lowpass, rect_rate );
      end


      disp([ '.. Copying Unity data for batch "' thisbatchlabel '".' ]);

% FIXME - Unity trial data NYI.

      disp([ '.. Finished reading.' ]);

      %
      % Save this batch of trial data.

    end


    % FIXME - Batch plotting NYI.


    % If this is the batch we want to display, display it.

    if want_browser && (bidx == middlebatch)

      disp([ '-- Rendering waveforms for batch "' thisbatchlabel '".' ]);

% FIXME - Data browser NYI.
      doBrowseFiltered( 'Rec', batchdata_rec_wb, batchdata_rec_lfp, ...
        batchdata_rec_spike, batchdata_rec_rect );
      doBrowseFiltered( 'Stim', batchdata_stim_wb, batchdata_stim_lfp, ...
        batchdata_stim_spike, batchdata_stim_rect );

      disp('-- Press any key to continue.');
      pause;

      close all;

    end

  end


  % Finished with this alignment case.

end

% Banner.
disp('== Finished processing epoched trial data.');


%
% This is the end of the file.
