function [ minval maxval ] = euPlot_getStructureSeriesRange( ...
  structlist, fieldwanted, defaultrange, extrapoints )

% function [ minval maxval ] = euPlot_getStructureSeriesRange( ...
%   structlist, fieldwanted, defaultrange, extrapoints )
%
% This accepts a structure array or a cell array of structures, aggregates
% one field as a data series, and determines the plotting extents of that
% data series.
%
% This will tolerate non-numeric data (such as cell arrays), falling back to
% defaults.
%
% "structlist" is a structure array or a cell array containing structures.
% "fieldwanted" is the name of the field to extract.
% "defaultrange" [ min max ] is the plotting range to fall back to.
% "extrapoints" is a vector containing additional data series values. The
%   plotting range is extended to include these values.
%
% "minval" is the minimum value plotted.
% "maxval" is the maximum value plotted.


% This returns [] for fields that don't exist.
dataseries = nlUtil_extractStructureSeries( structlist, fieldwanted );

% This should be adequately bulletproofed.
[ minval maxval ] = ...
  euPlot_getDataSeriesRange( dataseries, defaultrange, extrapoints );


% Done.
end


%
% This is the end of the file.
