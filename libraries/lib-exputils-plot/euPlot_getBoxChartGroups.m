function [ boxgroupindices boxgroupvalues ] = ...
  euPlot_getBoxChartGroups( data_yseries, data_xseries, data_xbins )

% function [ boxgroupindices boxgroupvalues ] = ...
%   euPlot_getBoxChartGroups( data_yseries, data_xseries, data_xbins )
%
% This produces "ydata" and "xgroupdata" series for use with the "boxchart"
% function. Input "y series" data is binned by the "x series" variable.
%
% "data_yseries" is a vector containing data to be box-plotted.
% "data_xseries" is a vector containing values used for binning y-series data.
% "data_xbins" is a vector containing bin edges for binning x-series values.
%
% "boxgroupindices" is a vector containing bin indices for the y-series data.
% "boxgroupvalues" is a vector containing bin midpoint X values for the
%   y-series data (so that "boxchart" generates appropriate column names).


boxgroupindices = nan(size(data_yseries));
boxgroupvalues = nan(size(data_yseries));

for bidx = 1:(length(data_xbins) - 1)
  thismin = data_xbins(bidx);
  thismax = data_xbins(bidx+1);
  thisbinval = 0.5 * (thismin + thismax);

  thismask = (data_xseries >= thismin) & (data_xseries < thismax);
  boxgroupindices(thismask) = bidx;
  boxgroupvalues(thismask) = thisbinval;
end


% Done.
end


%
% This is the end of the file.
