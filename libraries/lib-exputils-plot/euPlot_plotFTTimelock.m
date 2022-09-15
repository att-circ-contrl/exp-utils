function euPlot_plotFTTimelock( ...
  timelockdata_ft, bandsigma, plots_wanted, figtitle, obase )

% function euPlot_plotFTTimelock( ...
%   timelockdata_ft, bandsigma, plots_wanted, figtitle, obase )
%
% This plots a series of time-locked average waveforms and saves the
% resulting plots. Plots may have all channels stacked, or be per-channel,
% or a combination of the above.
%
% NOTE - Time ranges and decorations are hardcoded.
%
% This is a wrapper for euPlot_axesPlotFTTimelock().
%
% "timelockdata_ft" is a Field Trip structure produced by
%   ft_timelockanalysis().
% "bandsigma" is a scalar indicating where to draw confidence intervals.
%   This is a multiplier for the standard deviation.
% "plots_wanted" is a cell array containing zero or more of 'oneplot' and
%   'perchannel', controlling which plots are produced.
% "figtitle" is the prefix used when generating figure titles.
% "obase" is the prefix used when generating output filenames.


% Hard-code zoom ranges.
zoomranges = struct( 'full', [], ...
  'zoom', [ -0.3 0.6 ], 'detail', [ -0.03 0.06 ] );

% Magic number for pretty display.
maxlegendsize = 20;

% Get a scratch figure.
thisfig = figure();


% Get metadata.

chanlist = timelockdata_ft.label;
chancount = length(chanlist);


% Generate the single-plot plot.

if ismember('oneplot', plots_wanted)

  legendpos = 'northeast';
  if chancount > maxlegendsize
    legendpos = 'off';
  end

  helper_plotAllZooms( thisfig, timelockdata_ft, {}, bandsigma, ...
    legendpos, [ figtitle ' - All' ], [ obase '-all' ], zoomranges );

end


% Generate the per-channel plots.

if ismember('perchannel', plots_wanted)

  for cidx = 1:chancount
    thischan = chanlist{cidx};
    [ thischanlabel thischantitle ] = euUtil_makeSafeString(chanlist{cidx});

    helper_plotAllZooms( thisfig, timelockdata_ft, ...
      { thischan }, bandsigma, ...
      'off', [ figtitle ' - ' thischantitle ], ...
      [ obase '-' thischanlabel ], zoomranges );
  end

end


% Finished with the scratch figure.
close(thisfig);


% Done.

end


%
% Helper Functions


function helper_plotAllZooms( thisfig, timelockdata_ft, ...
  chanlist, bandsigma, legendpos, titlebase, obase, zoomranges )

  zoomlabels = fieldnames(zoomranges);

  for zidx = 1:length(zoomlabels)

    thiszlabel = zoomlabels{zidx};
    thiszoom = zoomranges.(thiszlabel);

    figure(thisfig);
    clf('reset');
    thisax = gca();

    euPlot_axesPlotFTTimelock( thisax, timelockdata_ft, ...
      chanlist, bandsigma, thiszoom, [], ...
      legendpos, titlebase );

    saveas( thisfig, sprintf('%s-%s.png', obase, thiszlabel) );

  end

  % Done.
end



%
% This is the end of the file.
