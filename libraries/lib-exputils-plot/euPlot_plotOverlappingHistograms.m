function euPlot_plotOverlappingHistograms( ...
  hist_list, xtype, ytype, legendpos, xstr, titlestr, fname )

% function euPlot_plotOverlappingHistograms( ...
%   hist_list, xtype, ytype, legendpos, xstr, titlestr, fname )
%
% This generates a line plot representing multiple overlaid histograms.
%
% Empty legend labels suppress rendering of that legend label.
%
% "hist_list" is a cell array. Each cell contains a cell array describing
%   the histograms to plot: { counts, bin_edges, colour, legend_label }
% "xtype" is "linear" or "log".
% "ytype" is "linear" or "log".
% "xstr" is a character array containing the X axis label.
% "legendpos" is the legend location ('off' to disable).
% "titlestr" is a character array containing a human readable plot title.
% "fname" is the filename to write to.
%
% No return value.


thisfig = figure();

figure(thisfig);
clf('reset');

hold on;

for hidx = 1:length(hist_list)
  hcounts = hist_list{hidx}{1};
  hbins = hist_list{hidx}{2};
  thiscol = hist_list{hidx}{3};
  thislabel = hist_list{hidx}{4};

  % Get bin centres.
  bincount = length(hcounts);
  hmidpoints = 0.5 * ( hbins(1:bincount) + hbins(2:(bincount+1)) );

  if ~isempty(thislabel)
    plot(hmidpoints, hcounts, 'Color', thiscol, 'DisplayName', thislabel);
  else
    plot(hmidpoints, hcounts, 'Color', thiscol, 'HandleVisibility', 'off');
  end
end

hold off;

xlabel(xstr);
ylabel('Count');

set(gca, 'xscale', xtype);
set(gca, 'yscale', ytype);

if strcmp(legendpos, 'off')
  legend('off');
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
