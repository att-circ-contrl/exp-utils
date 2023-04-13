function [ boxgroupindices boxgroupvalues ] = ...
  euPlot_getBoxChartGroups( data_xseries, data_xbins )

% function [ boxgroupindices boxgroupvalues ] = ...
%   euPlot_getBoxChartGroups( data_xseries, data_xbins )
%
% This produces an "xgroupdata" series for use with the "boxchart"
% function. Plotted data is binned by the "x series" variable (we only need
% to know this variable, not the plotted data values themselves).
%
% "data_xseries" is a vector containing values used for binning plotted data.
% "data_xbins" is a vector containing bin edges for binning x-series values.
%
% "boxgroupindices" is a vector containing bin indices for each supplied
%   data point.
% "boxgroupvalues" is a vector containing bin midpoint X values for each
%   supplied data point (which "boxchart" uses to generate column names).


boxgroupindices = nan(size(data_xseries));
boxgroupvalues = nan(size(data_xseries));

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
