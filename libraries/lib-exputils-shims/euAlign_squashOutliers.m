function newdata = euAlign_squashOutliers( ...
  timeseries, olddata, windowrad, outliersigma )

% This was moved to nlProc_xx.
% It was also changed to explicitly use percentiles, rather than pretending
% to use standard deviation.

euUtil_warnDeprecated( 'euAlign_squashOutliers', ...
  'Call nlProc_squashOutliersSlidingWindow().' );

newdata = nlProc_squashOutliersSlidingWindow( ...
  timeseries, olddata, windowrad, 16, outliersigma );

end


%
% This is the end of the file.
