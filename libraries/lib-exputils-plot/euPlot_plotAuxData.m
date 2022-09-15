function euPlot_plotAuxData( auxdata_ft, auxsamprate, ...
  trialdefs, trialnames, trialsamprate, evlists, evsamprate, ...
  chans_wanted, plots_wanted, figtitle, obase )

% function euPlot_plotAuxData( auxdata_ft, auxsamprate, ...
%   trialdefs, trialnames, trialsamprate, evlists, evsamprate, ...
%   chans_wanted, plots_wanted, figtitle, obase )
%
% This plots several channels of auxiliary data in strip chart form and
% saves the resulting plots. Plots may have all trials stacked or be plotted
% per trial or both.
%
% NOTE - Time ranges and decorations are hardcoded.
%
% This is a wrapper for euPlot_axesPlotFTTrials().
%
% "auxdata_ft" is a Field Trip "datatype_raw" structure with the trial data
%   and metadata.
% "auxsamprate" is the sampling rate of "auxdata_ft".
% "trialdefs" is the field trip trial definition matrix or table that was
%   used to generate the trial data.
% "trialnames" is either a vector of trial numbers or a cell array of trial
%   labels, corresponding to the trials in "trialdefs". An empty vector or
%   cell array auto-generates labels.
% "trialsamprate" is the sampling rate used when generating "trialdefs".
% "evlists" is a structure containing event lists or tables, with one event
%   list or table per field. Fields tested are 'cookedcodes', 'rwdA', and
%   'rwdB'.
% "evsamprate" is the sampling rate used when reading events.
% "chans_wanted" is a cell array with channel names to plot. This cannot be
%   empty. Each listed channel gets one strip (subplot) in the strip chart.
% "plots_wanted" is a cell array containing zero or more of 'oneplot' and
%   'pertrial', controlling which plots are produced.
% "figtitle" is the prefix used when generating figure titles.
% "obase" is the prefix used when generating output filenames.


% Hard-code zoom ranges.
zoomranges = struct( 'full', [], 'zoom', [ -0.3 0.6 ] );

% Get a scratch figure.
thisfig = figure();


% Extract event series.

evcodes = struct([]);
evrwdA = struct([]);
evrwdB = struct([]);

if isfield(evlists, 'cookedcodes');
  evcodes = evlists.cookedcodes;
end
if isfield(evlists, 'rwdA')
  evrwdA = evlists.rwdA;
end
if isfield(evlists, 'rwdB')
  evrwdB = evlists.rwdB;
end


% Get metadata.

chanlist = ft_channelselection( chans_wanted, auxdata_ft.label, {} );
chancount = length(chanlist);

trialcount = size(trialdefs);
trialcount = trialcount(1);


% Convert whatever we were given for trial names into text labels.
trialnames = euPlot_helperMakeTrialNames(trialnames, trialcount);


% Generate the single-plot plot.

if ismember('oneplot', plots_wanted)
  helper_plotAllZooms( thisfig, auxdata_ft, auxsamprate, ...
    trialdefs, trialnames, trialsamprate, chanlist, {}, ...
    evcodes, evrwdA, evrwdB, evsamprate, ...
    [ figtitle ' - All' ], [ obase '-all' ], zoomranges );
end


% Generate the per-trial plots.

if ismember('pertrial', plots_wanted)
  for tidx = 1:trialcount
    [ triallabel trialtitle ] = euUtil_makeSafeString( trialnames{tidx} );

    helper_plotAllZooms( thisfig, auxdata_ft, auxsamprate, ...
      trialdefs, trialnames, trialsamprate, chanlist, trialnames(tidx), ...
      evcodes, evrwdA, evrwdB, evsamprate, ...
      [ figtitle ' - ' trialtitle ], [ obase '-' triallabel ], zoomranges );
  end
end


% Finished with the scratch figure.
close(thisfig);


% Done.

end


%
% Helper Functions


function helper_plotAllZooms( thisfig, auxdata_ft, auxsamprate, ...
  trialdefs, trialnames, trialsamprate, chanlist, triallist, ...
  evcodes, evrwdA, evrwdB, evsamprate, ...
  titlebase, obase, zoomranges )

  zoomlabels = fieldnames(zoomranges);

  chanmask = ismember(auxdata_ft.label, chanlist);
  chanlabels = auxdata_ft.label(chanmask);
  chancount = length(chanlabels);

  if isempty(triallist)
    triallist = trialnames;
  end


  % First pass - Auto-range the data, to keep sub-plots at consistent scale.

  data_ymax = -inf;
  data_ymin = inf;

  trialcount = length(trialnames);

  for tidx = 1:trialcount
    if ismember(trialnames{tidx}, triallist)
      thisdata = auxdata_ft.trial{tidx};
      thisdata = thisdata(chanmask,:);

      this_ymax = max(max(thisdata));
      this_ymin = min(min(thisdata));

      data_ymax = max(data_ymax, this_ymax);
      data_ymin = min(data_ymin, this_ymin);
    end
  end


  % Second pass - Render the plots.

  for zidx = 1:length(zoomlabels)

    thiszlabel = zoomlabels{zidx};
    thiszoom = zoomranges.(thiszlabel);

    figure(thisfig);
    clf('reset')

    for cidx = 1:chancount
      thischan = chanlabels{cidx};
      [ safechanlabel safechantitle ] = euUtil_makeSafeString(thischan);

      thisax = subplot(chancount, 1, cidx);
      euPlot_axesPlotFTTrials( thisax, auxdata_ft, auxsamprate, ...
        trialdefs, trialnames, trialsamprate, { thischan }, triallist, ...
        thiszoom, [ data_ymin, data_ymax ], ...
        evcodes, evrwdA, evrwdB, evsamprate, 'off', ...
        [ titlebase ' - ' safechantitle ] );
    end

    saveas( thisfig, sprintf('%s-%s.png', obase, thiszlabel) );
  end

end


%
% This is the end of the file.
