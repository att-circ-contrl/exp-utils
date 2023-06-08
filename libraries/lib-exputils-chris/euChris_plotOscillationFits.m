function euChris_plotOscillationFits( ...
  oscfitdata, oscparams, trialtimes, trialwaves, ...
  window_sizes, size_labels, max_count_per_size, titleprefix, fnameprefix )

% function euChris_plotOscillationFits( ...
%   oscfitdata, oscparams, trialtimes, trialwaves, ...
%   window_sizes, size_labels, max_count_per_size, titleprefix, fnameprefix )
%
% This generates waveform plots of stimulation events and oscillation fits
% near those events.
%
% "oscfitdata" is a cell array with one entry per trial. Each cell contains
%   a structure with detected oscillation features, per CHRISOSCFEATURES.txt.
%   If the "chanlabels" field is present, it's used.
% "oscparams" is a structure containing oscillation fit parameters, per
%   CHRISOSCPARAMS.txt.
% "trialtimes" is a cell array with one entry per trial, containing the
%   timestamp series for each trial.
% "trialwaves" is a cell array with one entry per trial. Each cell contains
%   a Nchans x Nsamples matrix with waveform data.
% "window_sizes" is a cell array. Each cell contains a plot time range
%   [ begin end ] in seconds, or [] for the full data extent.
% "size_labels" is a cell array containing filename-safe labels used when
%   creating filenames and annotating titles for plots of each window size.
% "max_count_per_size" is a scalar indicating the maximum number of plots
%   to emit at a given size level. Set to inf to not decimate plots.
% "titleprefix" is the prefix used when generating figure titles.
% "fnameprefix" is the prefix used when generating output filenames.


% Prune the zoom list, so that we're getting all of the detection windows.
% Failing that, keep the biggest zoom setting we had.

zoommask = false(size(window_sizes));
biggestzoom = -inf;
biggestzidx = 1;

for zidx = 1:length(window_sizes)
  if isempty(window_sizes{zidx})
    % This is the "entire waveform" case. It's the biggest by fiat.
    biggestzoom = inf;
    biggestzidx = zidx;
  else
    % This is a user-defined time range.
    thisstart = min(window_sizes{zidx});
    thisend = max(window_sizes{zidx});

    thissize = thisend - thisstart;
    if thissize > biggestzoom
      biggestzoom = thissize;
      biggestzidx = zidx;
    end

    if (thisstart < oscparams.time_before) ...
      && (thisend > max(oscparams.timelist_after))
      % The oscillation test windows fit in this zoom window.
      zoommask(zidx) = true;
    end
  end
end

% Keep the biggest window no matter what.
zoommask(biggestzidx) = true;

% Prune the zoom list.
window_sizes = window_sizes(zoommask);
size_labels = size_labels(zoommask);



% Mask off trials to get the desired number of plots.

trialmask = euPlot_decimatePlotsBresenham( max_count_per_size, trialtimes );



% FIXME - Mangle this into something that euPlot_plotFTTrials() will take.
% We're turning each curve fit trial into a set of trials representing the
% different fit waveforms.

for tidx = 1:length(trialmask)
  if trialmask(tidx)

    % Make a title/file prefix extension. If we only have one trial, this
    % can be empty.

    tidxtitle = '';
    tidxlabel = '';
    if sum(trialmask) > 1
      tidxtitle = sprintf(' - Tr %04d', tidx);
      tidxlabel = sprintf('-tr%04d', tidx);
    end

    % Get trial data.

    thistimeseries = trialtimes{tidx};
    thistrialwaves = trialwaves{tidx};
    thisoscfit = oscfitdata{tidx};


    % Get derived metadata.

    samprate = (length(thistimeseries) - 1) ...
      / (max(thistimeseries) - min(thistimeseries));

    chancount = size(thistrialwaves);
    chancount = chancount(1);

    chanlabels = {};
    if isfield(thisoscfit, 'chanlabels')
      chanlabels = thisoscfit.chanlabels;
    else
      chanlabels = nlFT_makeLabelsFromNumbers( 'chan', 1:chancount );
    end


    %
    % Build something pretending to be a Field Trip data structure.

    % Metadata.
    thisft = struct();
    thisft.fsample = samprate;
    thisft.label = chanlabels;

    % Just in case our helpers need it, make an incomplete fake header.
    fthdr = struct();
    fthdr.Fs = samprate;
    fthdr.nChans = chancount;
    fthdr.label = chanlabels;
    thisft.hdr = fthdr;

    % Trials have names too, for plotting.

    % First trial is the ephys waveform data.

    newtimelist = { thistimeseries };
    newwavelist = { thistrialwaves };
    newtrialnames = { 'ephys' };

    % FIXME - This kludge wrapper needs trial definitions, so build them.

    % It doesn't really matter what this is; it's for aligning events.
    globalfirst = min(thistimeseries);

    thisfirst = min(thistimeseries);
    thislast = max(thistimeseries);
    thisoffset = thisfirst;
    thisfirst = round( (thisfirst - globalfirst) * samprate );
    thislast = round( (thislast - globalfirst) * samprate );
    thisoffset = round( thisoffset * samprate );

    newtrialdefs = [ thisfirst thislast thisoffset ];


    % Remaining trials are curve fit waveforms.


    % "Before stim" curve fit.

    [ recontime reconchanwaves ] = euChris_reconstructOscCosine( ...
      oscparams.time_before, oscparams.window_lambda, samprate, 'crop', ...
      thisoscfit.magbefore, thisoscfit.freqbefore, ...
      thisoscfit.phasebefore, thisoscfit.meanbefore );

    newtimelist = [ newtimelist { recontime } ];
    newwavelist = [ newwavelist { reconchanwaves } ];
    newtrialnames = [ newtrialnames ...
      { helper_makeTimeLabel(oscparams.time_before) } ];

    thisfirst = min(recontime);
    thislast = max(recontime);
    thisoffset = thisfirst;
    thisfirst = round( (thisfirst - globalfirst) * samprate );
    thislast = round( (thislast - globalfirst) * samprate );
    thisoffset = round( thisoffset * samprate );

    newtrialdefs = [ newtrialdefs ; thisfirst thislast thisoffset ];

    % FIXME - Render the original wave if it was saved.
    if isfield(thisoscfit, 'origtimebefore') ...
      && isfield(thisoscfit, 'origwavebefore')
      newtimelist = [ newtimelist { thisoscfit.origtimebefore } ];
      newwavelist = [ newwavelist { thisoscfit.origwavebefore } ];
      newtrialnames = [ newtrialnames ...
        { [ helper_makeTimeLabel(oscparams.time_before) 'orig' ] } ];
      newtrialdefs = [ newtrialdefs ; thisfirst thislast thisoffset ];
    end

    % "After stim" curve fits.

    for widx = 1:length(oscparams.timelist_after)
      thiswintime = oscparams.timelist_after(widx);

      [ recontime reconchanwaves ] = euChris_reconstructOscCosine( ...
        oscparams.timelist_after(widx), oscparams.window_lambda, ...
        samprate, 'crop', thisoscfit.magafter(:,widx), ...
        thisoscfit.freqafter(:,widx), thisoscfit.phaseafter(:,widx), ...
        thisoscfit.meanafter(:,widx) );

      newtimelist = [ newtimelist { recontime } ];
      newwavelist = [ newwavelist { reconchanwaves } ];
      newtrialnames = [ newtrialnames { helper_makeTimeLabel(thiswintime) } ];

      thisfirst = min(recontime);
      thislast = max(recontime);
      thisoffset = thisfirst;
      thisfirst = round( (thisfirst - globalfirst) * samprate );
      thislast = round( (thislast - globalfirst) * samprate );
      thisoffset = round( thisoffset * samprate );

      newtrialdefs = [ newtrialdefs ; thisfirst thislast thisoffset ];

      % FIXME - Render the original wave if it was saved.
      if isfield(thisoscfit, 'origtimeafter') ...
        && isfield(thisoscfit, 'origwaveafter')
        newtimelist = [ newtimelist { thisoscfit.origtimeafter{widx} } ];
        newwavelist = [ newwavelist { thisoscfit.origwaveafter{widx} } ];
        newtrialnames = [ newtrialnames ...
          { [ helper_makeTimeLabel(thiswintime) 'orig' ] } ];
        newtrialdefs = [ newtrialdefs ; thisfirst thislast thisoffset ];
      end
    end

    % Store the time series and trials.

    thisft.time = newtimelist;
    thisft.trial = newwavelist;


    %
    % Call the plotting function.

    euPlot_plotFTTrials( thisft, samprate, newtrialdefs, newtrialnames, ...
      samprate, struct(), samprate, { 'perchannel' }, ...
      window_sizes, size_labels, max_count_per_size, ...
      [ titleprefix tidxtitle ], [ fnameprefix tidxlabel ] );

  end
end


% Done.
end


%
% Helper functions.

function thislabel = helper_makeTimeLabel(thistime_secs)
  thistime_ms = thistime_secs * 1000;

  if thistime_ms < 0
    thislabel = sprintf( 'n%03d', abs(thistime_ms) );
  else
    thislabel = sprintf( 'p%03d', thistime_ms );
  end
end


%
% This is the end of the file.
