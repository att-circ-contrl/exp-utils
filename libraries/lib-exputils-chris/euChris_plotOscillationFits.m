function euChris_plotOscillationFits( ...
  oscfitdata, oscparams, trialtimes, trialwaves, timeswanted, ...
  window_sizes, size_labels, max_count_per_size, titleprefix, fnameprefix )

% function euChris_plotOscillationFits( ...
%   oscfitdata, oscparams, trialtimes, trialwaves, timeswanted, ...
%   window_sizes, size_labels, max_count_per_size, titleprefix, fnameprefix )
%
% This generates waveform plots of stimulation events and oscillation fits
% near those events.
%
% "oscfitdata" is a cell array with one entry per trial. Each cell contains
%   a structure with detected oscillation features, per CHRISSTIMFEATURES.txt.
%   If the "chanlabels" field is present, it's used.
% "oscparams" is a structure containing oscillation fit parameters, per
%   CHRISOSCPARAMS.txt.
% "trialtimes" is a cell array with one entry per trial, containing the
%   timestamp series for each trial.
% "trialwaves" is a cell array with one entry per trial. Each cell contains
%   a Nchans x Nsamples matrix with waveform data.
% "timeswanted" is 'before', 'after', or 'both' (before/after stimulation).
% "window_sizes" is a cell array. Each cell contains a plot time range
%   [ begin end ] in seconds, or [] for the full data extent.
% "size_labels" is a cell array containing filename-safe labels used when
%   creating filenames and annotating titles for plots of each window size.
% "max_count_per_size" is a scalar indicating the maximum number of plots
%   to emit at a given size level. Set to inf to not decimate plots.
% "titleprefix" is the prefix used when generating figure titles.
% "fnameprefix" is the prefix used when generating output filenames.


% Unpack the time request parameter.
want_before = ~strcmp(timeswanted, 'after');
want_after = ~strcmp(timeswanted, 'before');


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

    [ thisfirst thislast thisoffset ] = ...
      helper_computeTrialDefInfo( thistimeseries, globalfirst, samprate );

    newtrialdefs = [ thisfirst thislast thisoffset ];


    % Remaining trials are curve fit waveforms.

    % "Before stim" curve fit.
    if want_before
      [ newtimelist newwavelist newtrialnames newtrialdefs ] = ...
        helper_addCurveFitTrial( ...
          newtimelist, newwavelist, newtrialnames, newtrialdefs, ...
          oscparams.time_before, oscparams.window_lambda, samprate, ...
          thisoscfit, 'before', globalfirst );
    end

    % "After stim" curve fits.
    if want_after
      [ newtimelist newwavelist newtrialnames newtrialdefs ] = ...
        helper_addCurveFitTrial( ...
          newtimelist, newwavelist, newtrialnames, newtrialdefs, ...
          oscparams.timelist_after, oscparams.window_lambda, samprate, ...
          thisoscfit, 'after', globalfirst );
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


% This turns a time window location into an appropriate legend/file label.

function thislabel = helper_makeTimeLabel(thistime_secs)

  thistime_ms = thistime_secs * 1000;

  if thistime_ms < 0
    thislabel = sprintf( 'n%03d', abs(thistime_ms) );
  else
    thislabel = sprintf( 'p%03d', thistime_ms );
  end

end



% This computes trialdef columns for a time series.

function [ sampfirst samplast sampoffset ] = ...
  helper_computeTrialDefInfo( timeseries, globalfirst, samprate )

  timefirst = min(timeseries);
  timelast = max(timeseries);
  timeoffset = timefirst;

  sampfirst = round( (timefirst - globalfirst) * samprate );
  samplast = round( (timelast - globalfirst) * samprate );
  sampoffset = round( timeoffset * samprate );

end



% This adds a "before" or "after" reconstructed waveform to the trial list,
% and adds original and raw reconstruction waves if present.

function [ newtimelist newwavelist newtrialnames newtrialdefs ] = ...
  helper_addCurveFitTrial( ...
    oldtimelist, oldwavelist, oldtrialnames, oldtrialdefs, ...
    window_times, window_periods, samprate, ...
    thisoscfit, fieldsuffix, globalfirst )

  % Get relevant oscillation fit fields and behavior flags.

  maglist = thisoscfit.([ 'mag' fieldsuffix ]);
  freqlist = thisoscfit.([ 'freq' fieldsuffix ]);
  phaselist = thisoscfit.([ 'phase' fieldsuffix ]);
  meanlist = thisoscfit.([ 'mean' fieldsuffix ]);
  ramplist = zeros(size(meanlist));
  if isfield(thisoscfit, [ 'ramp' fieldsuffix ])
    ramplist = thisoscfit.([ 'ramp' fieldsuffix ]);
  end

  have_orig = false;
  if isfield(thisoscfit, [ 'origtime' fieldsuffix ]) ...
    && isfield(thisoscfit, [ 'origwave' fieldsuffix ])
    have_orig = true;
    origtimelist = thisoscfit.([ 'origtime' fieldsuffix ]);
    origwavelist = thisoscfit.([ 'origwave' fieldsuffix ]);
  end

  have_raw_phase = false;
  if isfield(thisoscfit, [ 'rawphase', fieldsuffix ])
    have_raw_phase = true;
    rawphaselist = thisoscfit.([ 'rawphase' fieldsuffix ]);
  end


  % The canon series are x1 (before) or xNwindows (after), and so compatible.
  % The debug series are stored as cell arrays if per-window, so convert
  % the "before" versions to cell arrays for compatibility.

  if have_orig
    if ~iscell(origtimelist)
      origtimelist = { origtimelist };
      origwavelist = { origwavelist };
    end
  end

  if have_raw_phase
    if ~iscell(rawphaselist)
      rawphaselist = { rawphaselist };
    end
  end


  % Walk through the time list, adding each saved wave.

  newtimelist = oldtimelist;
  newwavelist = oldwavelist;
  newtrialnames = oldtrialnames;
  newtrialdefs = oldtrialdefs;

  for widx = 1:length(window_times)

    thiswintime = window_times(widx);

    %
    % Reconstructed wave.

    [ recontime reconchanwaves ] = euChris_reconstructOscCosine( ...
      thiswintime, window_periods, samprate, 'crop', ...
      maglist(:,widx), freqlist(:,widx), phaselist(:,widx), ...
      meanlist(:,widx), ramplist(:,widx) );

    % Compute trial_definition information.
    [ thisfirst thislast thisoffset ] = ...
      helper_computeTrialDefInfo( recontime, globalfirst, samprate );

    % Save trial information.
    newtimelist = [ newtimelist { recontime } ];
    newwavelist = [ newwavelist { reconchanwaves } ];
    newtrialnames = [ newtrialnames { helper_makeTimeLabel(thiswintime) } ];
    newtrialdefs = [ newtrialdefs ; thisfirst thislast thisoffset ];


    %
    % Plot curve fit tattle info, if present.

    if have_orig

      % Add the saved original wave.

      thisorigtime = origtimelist{widx};
      thisorigwave = origwavelist{widx};

      [ thisfirst thislast thisoffset ] = ...
        helper_computeTrialDefInfo( thisorigtime, globalfirst, samprate );

      newtimelist = [ newtimelist { thisorigtime } ];
      newwavelist = [ newwavelist { thisorigwave } ];
      newtrialnames = [ newtrialnames ...
        { [ helper_makeTimeLabel(thiswintime) 'orig' ] } ];
      newtrialdefs = [ newtrialdefs ; thisfirst thislast thisoffset ];

      if have_raw_phase
        % Reconstruct without the helper, so we can _test_ the helper.

        recontime = 1:length(thisorigtime);
        recontime = (recontime - 1) / samprate;

        magbychan = maglist(:,widx);
        freqbychan = freqlist(:,widx);
        meanbychan = meanlist(:,widx);
        rampbychan = ramplist(:,widx);
        phasebychan = rawphaselist{widx};

        timedelta = thiswintime - thisorigtime(1);
        meanbychan = meanbychan - rampbychan * timedelta;

        reconwave = [];
        for cidx = 1:length(magbychan)
          thisbg = recontime * rampbychan(cidx) + meanbychan(cidx);
          thisrecon = thisbg + magbychan(cidx) * cos( ...
            recontime * 2 * pi * freqbychan(cidx) + phasebychan(cidx) );
          reconwave(cidx,:) = thisrecon;
        end

        newtimelist = [ newtimelist { thisorigtime } ];
        newwavelist = [ newwavelist { reconwave } ];
        newtrialnames = [ newtrialnames ...
          { [ helper_makeTimeLabel(thiswintime) 'raw' ] } ];
        % Still using the "origtime" time series, so the same trialdef info.
        newtrialdefs = [ newtrialdefs ; thisfirst thislast thisoffset ];
      end

    end

  end
end



%
% This is the end of the file.
