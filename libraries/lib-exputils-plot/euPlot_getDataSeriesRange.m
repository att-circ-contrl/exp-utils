function [ minval maxval ] = euPlot_getDataSeriesRange( ...
  dataseries, defaultrange, extrapoints )

% function [ minval maxval ] = euPlot_getDataSeriesRange( ...
%   dataseries, defaultrange, extrapoints )
%
% This accepts a vector of data values and determines its plotting extents.
%
% This will tolerate non-numeric data (such as cell arrays), falling back to
% defaults.
%
% "dataseries" is a vector containing data to be ranged.
% "defaultrange" [ min max ] is the plotting range to fall back to.
% "extrapoints" is a vector containing additional data series values. The
%   plotting range is extended to include these values.
%
% "minval" is the minimum value plotted.
% "maxval" is the maximum value plotted.


if isempty(dataseries) || (~isnumeric(dataseries))
  dataseries = defaultrange;
end

if isempty(dataseries) || (~isnumeric(dataseries))
  dataseries = [ 0 1 ];
end

minval = min(dataseries);
maxval = max(dataseries);

if (~isempty(extrapoints)) && isnumeric(extrapoints)
  minval = min( minval, min(extrapoints) );
  maxval = max( maxval, max(extrapoints) );
end


% Done.
end


%
% This is the end of the file.
