% Field Trip sample script / test script - Epoched data processing.
% Written by Christopher Thomas.

% This reads data according to predefined trial definitions, processes and
% saves it trial by trial, and optionally displays it using FT's browser.
% FIXME - Doing this by reading and setting workspace variables directly.
%
% Variables that get set:
% FIXME - List goes here.


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
    trialsfirst = 1:trialsperbatch:trialcount;
    trialslast = min(( trialsfirst + trialsperbatch - 1), trialcount );
    for bidx = 1:length(trialsfirst)
      batchlabels{bidx} = sprintf('%s-batch%04d', thiscaselabel, bidx);
      batchtrialdefs{bidx} = thistrialdefs(trialsfirst:trialslast,:);
    end
  end


  %
  % Process this case's trial batches.

  for bidx = 1:length(batchlabels)

    thisbatchlabel = batchlabels{bidx};
    fname = [ datadir filesep 'trials-' thisbatchlabel '.mat' ];
    need_save = false;

    if want_cache_epoched && isfile(fname)

      %
      % Load the data we previously processed.

      disp([ '-- Loading batch "' thisbatchlabel '".' ]);
      load(fname);
      disp([ '-- Finished loading.' ]);

    else

      %
      % Rebuild data for this set of trials.

      disp([ '-- Reading recorder data for batch "' thisbatchlabel '".' ]);

      % Sample counts are fine as-is.
      preproc_config_rec.trl = thistrialdefs;
      % Turn off the progress bar.
      preproc_config_rec.feedback = 'no';

      if isempty(rec_channels_ephys)
      end
% FIXME - Recorder trial data NYI.

      disp([ '-- Reading stimulator data for batch "' thisbatchlabel '".' ]);

% FIXME - Stimulator trial data NYI.

      disp([ '-- Copying Unity data for batch "' thisbatchlabel '".' ]);

% FIXME - Unity trial data NYI.

      disp([ '-- Finished reading.' ]);

    end

  end


  % Finished with this alignment case.

end

% Banner.
disp('== Finished processing epoched trial data.');


%
% This is the end of the file.
