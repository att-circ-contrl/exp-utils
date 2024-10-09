function [ newvalues newbinids newsetlabels ] = ...
  euPlot_makeBoxPlotConfidence( oldvalues, oldbinids, oldsetlabels, ...
    valuedevs, confsigma, minvalues, maxvalues )

% function [ newvalues newbinids newsetlabels ] = ...
%   euPlot_makeBoxPlotConfidence( oldvalues, oldbinids, oldsetlabels, ...
%     valuedevs, confsigma, minvalues, maxvalues )
%
% This function augments a list of samples with additional fake samples
% so that the resulting box plots have the desired confidence intervals.
% This is used when you have sample statistics but have discarded the actual
% samples.
%
% This is intended to be used with euPlot_plotMultipleBoxCharts().
%
% The idea is that calling "boxchart" with [ u-conf u-conf u u+conf u+conf ]
% puts the quartiles at (u-conf) and (u+conf), and these are what get
% rendered. Ditto [ min u-conf u-conf u u+conf u+conf max ], for whiskers.
%
% NOTE - This will tolerate matrix input rather than vector, but the output
% will always be row vectors suitable for euPlot_plotMultipleBoxCharts().
%
% "oldvalues" is a vector with sample values.
% "oldbinids" is a vector or cell array with bin labels or values for each
%   data sample. This may be [] or {} to not process bin IDs.
% "oldsetlabels" is a cell array with dataset labels for each data sample.
%   This may be {} to not process dataset labels.
% "valuedevs" is a vector with the standard deviation associated with each
%   data sample.
% "confsigma" is the number of standard deviations to use for the
%   confidence interval (typically 2.0).
% "minvalues" is an optional argument with minimum sample values for each
%   data sample (bottom whisker location). Absent or [] to not use.
% "maxvalues" is an optional argument with maximum sample values for each
%   data sample (top whisker location). Absent or [] to not use.
%
% "newvalues" is a vector with original and fake sample values.
% "newbinids" is a vector or cell array with new bin labels or values.
% "newsetlabels" is a cell array with new dataset labels.


%
% Sanity check optional arguments.

if ~exist('minvalues', 'var')
  minvalues = [];
end

if ~exist('maxvalues', 'var')
  maxvalues = [];
end

% These are an all-or-nothing pair.
want_whiskers = true;
if isempty(minvalues) || isempty(maxvalues)
  minvalues = [];
  maxvalues = [];
  want_whiskers = false;
end


%
% Initialize output.

newvalues = [];
newbinids = [];
if iscell(oldbinids)
  newbinids = {};
end
newsetlabels = {};


%
% Force consistent input geometry.

% This will even tolerate matrix input, though we shouldn't get that.

oldvalues = reshape(oldvalues, 1, []);
oldbinids = reshape(oldbinids, 1, []);
oldsetlabels = reshape(oldsetlabels, 1, []);
valuedevs = reshape(valuedevs, 1, []);
minvalues = reshape(minvalues, 1, []);
maxvalues = reshape(maxvalues, 1, []);


%
% Augment the data with fake samples that give the desired boxes/whiskers.

valuedevs = valuedevs * confsigma;

if want_whiskers

  % 7 elements:  [ min u-conf u-conf u u+conf u+conf max ]
  newvalues = [ minvalues (oldvalues - valuedevs) (oldvalues - valuedevs), ...
    oldvalues (oldvalues + valuedevs) (oldvalues + valuedevs) maxvalues ];

  if ~isempty(oldbinids)
    newbinids = [ oldbinids oldbinids oldbinids ...
      oldbinids oldbinids oldbinids oldbinids ];
  end

  if ~isempty(oldsetlabels)
    newsetlabels = [ oldsetlabels oldsetlabels oldsetlabels ...
      oldsetlabels oldsetlabels oldsetlabels oldsetlabels ];
  end

else

  % 5 elements:  [ u-conf u-conf u u+conf u+conf ]
  newvalues = [ (oldvalues - valuedevs) (oldvalues - valuedevs), ...
    oldvalues (oldvalues + valuedevs) (oldvalues + valuedevs) ];

  if ~isempty(oldbinids)
    newbinids = [ oldbinids oldbinids oldbinids oldbinids oldbinids ];
  end

  if ~isempty(oldsetlabels)
    newsetlabels = [ oldsetlabels oldsetlabels ...
      oldsetlabels oldsetlabels oldsetlabels ];
  end

end
