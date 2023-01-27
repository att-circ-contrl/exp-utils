function euPlot_plotOverlappingRoses( ...
  hist_list, cursor_list, legendpos, titlestr, fname )

% function euPlot_plotOverlappingRoses( ...
%   hist_list, cursor_list, legendpos, titlestr, fname )
%
% This generates a polar plot representing multiple overlaid histograms.
% The first and last bin of the histogram are connected (plots are closed
% curves).
%
% Empty legend labels suppress rendering of that legend label.
%
% "hist_list" is a cell array. Each cell contains a cell array describing
%   the histograms to plot: { counts, bin_edges, colour, legend_label }
% "cursor_list" is a cell array. Each cell contains a cell array describing
%   radial cursors to plot: { angles, colour, legend_label }
% "legendpos" is the legend location ('off' to disable).
% "titlestr" is a character array containing a human-readable plot title.
% "fname" is the filename to write to.
%
% No return value.


% Get and initialize a figure.

thisfig = figure();

figure(thisfig);
clf('reset');

thisax = polaraxes;


% Preprocessing: Get the maximum count, to get cursor sizes.

cursormax = -inf;

for hidx = 1:length(hist_list)
  thismax = max(hist_list{hidx}{1});
  cursormax = max(cursormax, thismax);
end

if ~isfinite(cursormax)
  cursormax = 1.0;
end


% Plot the histograms and cursors.

hold on;

for hidx = 1:length(hist_list)
  hcounts = hist_list{hidx}{1};
  hbins = hist_list{hidx}{2};
  thiscol = hist_list{hidx}{3};
  thislabel = hist_list{hidx}{4};

  % Get bin centres.
  bincount = length(hcounts);
  hmidpoints = 0.5 * ( hbins(1:bincount) + hbins(2:(bincount+1)) );

  % Make a closed loop.
  hcounts(bincount + 1) = hcounts(1);
  hmidpoints(bincount + 1) = hmidpoints(1);

  % Plot.
  if ~isempty(thislabel)
    polarplot( hmidpoints, hcounts, ...
      'Color', thiscol, 'DisplayName', thislabel );
  else
    polarplot( hmidpoints, hcounts, ...
      'Color', thiscol, 'HandleVisibility', 'off' );
  end
end

for cidx = 1:length(cursor_list)
  thisanglist = cursor_list{cidx}{1};
  thiscol = cursor_list{cidx}{2};
  thislabel = cursor_list{cidx}{3};

  for aidx = 1:length(thisanglist)
    thisangle = thisanglist(aidx);
    if ~isempty(thislabel)
      polarplot( [ thisangle thisangle ], [ 0 cursormax ], ...
        'Color', thiscol, 'DisplayName', thislabel );
    else
      polarplot( [ thisangle thisangle ], [ 0 cursormax ], ...
        'Color', thiscol, 'HandleVisibility', 'off' );
    end
  end
end

hold off;


% Annotate and save the plot.

if strcmp(legendpos, 'off')
  legand('off');
else
  legend('Location', legendpos);
end

title(titlestr);

saveas(thisfig, fname);

close(thisfig);


% Done.
end


%
% This is the end of the file.
