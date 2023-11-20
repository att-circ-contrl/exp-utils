function [ rangemin rangemax ticlabels wantlog ] = ...
  euPlot_hlevHelperGetRangeAndTics( ...
    dataseries, extravals, loglin, rangewanted )

% function [ rangemin rangemax ticlabels wantlog ] = ...
%   euPlot_hlevHelperGetRangeAndTics( ...
%     dataseries, extravals, loglin, rangewanted )
%
% This is a helper function called by euPlot_hlevPlotXX.
%
% This evaluates a data series, determines whether it's labels or numeric,
% and auto-ranges if necessary.
%
% "dataseries" is a vector or cell array containing data.
% "extravals" is a vector containing additional data values to include in
%   the plot range.
% "loglin" is 'log' or 'linear'. Ignored for label data (always linear).
% "rangewanted" [ min max ] specifies the desired range, or [] to auto-range.
%
% "rangemin" is the minimum range to be plotted (possibly auto-detected, and
%   clamped to positive values if log-scale).
% "rangemax" is the maximum range to be plotted (possibly auto-detected).
% "ticlabels" is a cell array containing unique data series labels sorted in
%   lexical order, or {} if the data series did not contain labels.
% "wantlog" is true if the axis should be rendered log-scale and false
%   otherwise. This is based on "loglin", overridden to be linear for labels.


% Initialize to sane defaults.

ticlabels = {};
wantlog = strcmp(loglin, 'log');



% If we have label data, get the tic series.

if iscell( dataseries )
  ticlabels = unique(dataseries);
end



% If we have label data, force the axis to be linear.

if iscell(dataseries)
  wantlog = false;
end



% If we were asked to auto-range, do so.

if ~isempty(rangewanted)

  % Copy the supplied range.
  rangemin = min(rangewanted);
  rangemax = max(rangewanted);

else

  % Auto-detect the range. This works even with empty data.

  if isempty(ticlabels)
    defaultrange = [ 0 1 ];
  else
    % Default to 0..n+1, to get sensible ranges for labels.
    defaultrange = [ 0 (1 + length(ticlabels)) ];
  end

  % This should be adequately bulletproofed.
  % If we give it [], or if it's non-numeric, it returns the default.
  [ rangemin rangemax ] = euPlot_getDataSeriesRange( ...
    dataseries, defaultrange, extravals );

  % Kludge to catch constant-data case.
  if rangemax == rangemin
    rangemax = rangemin + 1;
  end

end



% Extend to cover requested extra values.

% If we're plotting log-scale, mask off zero and negative values.
if wantlog
  extravals = extravals(extravals >= 1e-100);
end

if ~isempty(extravals)
  rangemax = max(rangemax, max(extravals));
  rangemin = min(rangemin, min(extravals));
end



% Clamp for logscale plots.

if wantlog

  % Handle cases where both values are zero or negative.
  if rangemax < 1e-100
    rangemin = 1;
    rangemax = 10;
  end

  % Handle cases where the minimum value is zero or negative.
  if rangemin < (1e-12 * abs(rangemax))
    rangemin = 0.003 * abs(rangemax);
  end

end



% Done.
end


%
% This is the end of the file.
