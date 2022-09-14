function euPlot_plotFTTrials( wavedata_ft, wavesamprate, ...
  trialdefs, trialsamprate, evlists, evsamprate, ...
  plots_wanted, figtitle, obase )

% function euPlot_plotFTTrials( wavedata_ft, wavesamprate, ...
%   trialdefs, trialsamprate, evlists, evsamprate, ...
%   plots_wanted, figtitle, obase )
%
% This plots a series of stacked trial waveforms and saves the resulting
% plots. Plots may have all trials and channels stacked, or have all
% trials stacked and have one plot per channel, or have all channels
% stacked and have one plot per trial, or a combination of the above.
%
% NOTE - Time ranges and decorations are hardcoded.
%
% This is a wrapper for euPlot_axesPlotFTTrials().
%
% "wavedata_ft" is a Field Trip "datatype_raw" structure with the trial data
%   and metadata.
% "wavesamprate" is the sampling rate of "wavedata_ft".
% "trialdefs" is the field trip trial definition matrix or table that was
%   used to generate the trial data.
% "trialsamprate" is the sampling rate used when generating "trialdefs".
% "evlists" is a structure containing event lists or tables, with one event
%   list or table per field. Fields tested for are 'cookedcodes', 'rwdA',
%   and 'rwdB'.
% "evsamprate" is the sampling rate used when reading events.
% "plots_wanted" is a cell array containing zero or more of 'oneplot',
%   'perchannel', and 'pertrial', controlling which plots are produced.
% "figtitle" is the prefix used when generating figure titles.
% "obase" is the prefix used when generating output filenames.


% Hard-code zoom ranges.
zoomranges = struct( 'full', [], 'zoom', [ -0.3 0.6 ] );

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

trialcount = size(trialdefs);
trialcount = trialcount(1);


% Generate the single-plot plot.

if ismember('oneplot', plots_wanted)

  legendpos = 'northeast';
  if chancount > maxlegendsize
    legendpos = 'off';
  elseif (1 == chancount) && (trialcount > maxlegendsize)
    legendpos = 'off';
  end

  helper_plotAllZooms( thisfig, wavedata_ft, wavesamprate, ...
    trialdefs, trialsamprate, {}, [], ...
    evcodes, evrwdA, evrwdB, evsamprate, ...
    legendpos, [ figtitle ' - All' ], [ obase '-all' ], zoomranges );

end


% Generate the per-channel plots.

if ismember('perchannel', plots_wanted)

  legendpos = 'northeast';
  if trialcount > maxlegendsize
    legendpos = 'off';
  end

  for cidx = 1:chancount
    thischan = chanlist{cidx};
    [ thischanlabel thischantitle ] = euUtil_makeSafeString(chanlist{cidx});

    helper_plotAllZooms( thisfig, wavedata_ft, wavesamprate, ...
      trialdefs, trialsamprate, { thischan }, [], ...
      evcodes, evrwdA, evrwdB, evsamprate, legendpos, ...
      [ figtitle ' - ' thischantitle ], [ obase '-' thischanlabel ], ...
      zoomranges );
  end

end


% Generate the per-trial plots.

if ismember('pertrial', plots_wanted)

  legendpos = 'northeast';
  if chancount > maxlegendsize
    legendpos = 'off';
  end

  for tidx = 1:trialcount
    thistidx = sprintf('%04d', tidx);

    helper_plotAllZooms( thisfig, wavedata_ft, wavesamprate, ...
      trialdefs, trialsamprate, {}, [ tidx ], ...
      evcodes, evrwdA, evrwdB, evsamprate, legendpos, ...
      [ figtitle ' - Tr ' thistidx ], [ obase '-tr' thistidx ], zoomranges );
  end

end


% Finished with the scratch figure.
close(thisfig);


% Done.

end


%
% Helper Functions


function helper_plotAllZooms( thisfig, wavedata_ft, wavesamprate, ...
  trialdefs, trialsamprate, chanlist, triallist, ...
  evcodes, evrwdA, evrwdB, evsamprate, ...
  legendpos, titlebase, obase, zoomranges )

  zoomlabels = fieldnames(zoomranges);

  for zidx = 1:length(zoomlabels)

    thiszlabel = zoomlabels{zidx};
    thiszoom = zoomranges.(thiszlabel);

    figure(thisfig);
    clf('reset');
    thisax = gca();

    euPlot_axesPlotFTTrials( thisax, wavedata_ft, wavesamprate, ...
      trialdefs, trialsamprate, chanlist, triallist, thiszoom, [], ...
      evcodes, evrwdA, evrwdB, evsamprate, legendpos, titlebase );

    saveas( thisfig, sprintf('%s-%s.png', obase, thiszlabel) );

  end

  % Done.
end



%
% This is the end of the file.
