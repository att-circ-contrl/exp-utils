function doPlotStackedSpectra( fname, spectmags, spectfreqs, ...
  scaletype, cursorfreqs, fitmags, fitfreqs, chanlabels, figtitle )

% function doPlotStackedSpectra( fname, spectmags, spectfreqs, ...
%   scaletype, cursorfreqs, fitmags, fitfreqs, chanlabels, figtitle )
%
% This plots a series of per-channel stacked spectra. These are magnitude
% spectra, not power spectra. The spectra are optionally annotated with
% cursors and with fitted curves.
%
% "fname" is the name of the file to save the plot to.
% "spectmags" is a cell array with per-channel spectrum magnitude vectors.
% "spectfreqs" is a cell array with per-channel spectrum frequency vectors.
% "scaletype" is 'magnitude' or 'power'.
% "cursorfreqs" is a cell array with per-channel cursor frequency vectors.
% "fitmags" is a cell array with per-channel fitted curve magnitude vectors.
% "fitfreqs" is a cell array with per-channel fitted curve frequency vectors.
% "chanlabels" is a cell array containing channel labels.
% "figtitle" is a character array to use as the figure title.
%
% Empty cell arrays can be passed as "cursorfreqs", "fitmags", or "fitfreqs"
% to suppress cursor or curve-fit output.


% Get metadata.
chancount = length(chanlabels);


% FIXME - Strip special characters from the channel labels.
for cidx = 1:chancount
  chanlabels{cidx} = strrep(chanlabels{cidx}, '_', ' ');
end


% Make a readable palette.

cols = nlPlot_getColorPalette();
palette_spectra = nlPlot_getColorSpread(cols.grn, chancount, 180);
palette_cursors = nlPlot_getColorSpread(cols.mag, chancount, 60);
palette_fits = nlPlot_getColorSpread(cols.brn, chancount, 60);


% FIXME - Pick a sane Y scale.

ymagmax = 0;
ymagmin = 0;
for cidx = 1:chancount
  thismax = max(spectmags{cidx});
  ymagmax = max(ymagmax, thismax);
end
ymagmax = 10^ceil(log10(ymagmax));

% FIXME - A factor of 1000 is fine for the tungsten test data but not the
% silicon one.
%yrangescale = 1e+3;
yrangescale = 1e+4;
if strcmp('power', scaletype)
  yrangescale = yrangescale * yrangescale;
end

ymagmin = ymagmax / yrangescale;


% Initialize the figure.

thisfig = figure();
clf('reset');

title(figtitle);
xlabel('Frequency (Hz)');

if strcmp('power', scaletype)
  ylabel('Power (a.u.)');
else
  ylabel('Magnitude (a.u.)');
end

set(gca, 'Xscale', 'log');
set(gca, 'Yscale', 'log');

ylim( [ymagmin ymagmax] );

hold on;


% Render cursors, followed by spectra, followed by curve fits.

if ~isempty(cursorfreqs)
  for cidx = 1:chancount
    thiscursorlist = cursorfreqs{cidx};

    for lidx = 1:length(thiscursorlist)
      thisfreq = thiscursorlist(lidx);

      if lidx == 1
        plot( [thisfreq thisfreq], [ymagmin ymagmax], ...
          'Color', palette_cursors{cidx}, 'DisplayName', chanlabels{cidx} );
      else
        plot( [thisfreq thisfreq], [ymagmin ymagmax], ...
          'Color', palette_cursors{cidx}, 'HandleVisibility', 'off' );
      end
    end
  end
end

for cidx = 1:chancount
  plot( spectfreqs{cidx}, spectmags{cidx}, ...
    'Color', palette_spectra{cidx}, 'DisplayName', chanlabels{cidx} );
end

if (~isempty(fitmags)) && (~isempty(fitfreqs))
  for cidx = 1:chancount
    thismaglist = fitmags{cidx};
    thisfreqlist = fitfreqs{cidx};

    if (~isempty(thismaglist)) && (~isempty(thisfreqlist))
      plot( thisfreqlist, thismaglist, ...
        'Color', palette_fits{cidx}, 'DisplayName', chanlabels{cidx} );
    end
  end
end


hold off;

saveas(thisfig, fname);

% Reset before closing, just in case of memory leaks.
figure(thisfig);
clf('reset');

close(thisfig);


% Done.

end


%
% This is the end of the file.
