function [ vstimelist vslaglist ] = euInfo_collapseTimeLagAverages( ...
  timelagdata, datafield, timeranges_ms, lagranges_ms )

% function [ vstimelist vslaglist ] = euInfo_collapseTimeLagAverages( ...
%   timelagdata, datafield, timeranges_ms, lagranges_ms )
%
% This collapses time-and-lag analysis data by averaging across time lags
% (producing "vs window time") and by averaging across window time (producing
% "vs time lag"). Mean and standard deviation for collapsed samples are
% reported.
%
% This tolerates NaN data.
%
% "timelagdata" is a data structure per TIMEWINLAGDATA.txt.
% "datafield" is a character vector with the name of the field to average.
%   If the specified field isn't found, "FOOavg" is also tested.
% "timeranges_ms" is a cell array. Each cell specifies an analysis window
%   time range [ min max ] in milliseconds to average across. A range of
%   [] indicates all window times.
% "lagranges_ms" is a cell array. Each cell specifies a time lag range
%   [ min max ] in milliseconds to average across. A range of []
%   indicates all time lags.
%
% "vstimelist" is a struct array, with a number of elements equal to the
%   number of time lag ranges. Each structure contains the following
%   fields:
%   "destchans" is a cell array with FT channel names for putative
%     destination channels.
%   "srcchans" is a cell array with FT channel names for putative source
%     channels.
%   "delayrange_ms" is a vector containing the [ min max ] time lag
%     sampled, in milliseconds (copied from "lagranges_ms").
%   "windowlist_ms" is a vector containing timestamps in milliseconds
%     specifying where the middle of each analysis window is.
%   "avg" is a matrix indexed by (destchan, srcchan, winidx) containing
%     the average data values. NOTE - This is just the mean of "FOOavg",
%     ignoring "count".
%   "dev" is a matrix indexed by (destchan, srcchan, winidx) containing
%     the standard deviation of the data values. NOTE - This is just the
%     standard deviation of "FOOavg", ignoring "var" and "count".
%
% "vslaglist" is a struct array, with a number of elements equal to the
%   number of analysis window ranges. Each structure contains the following
%   fields:
%   "destchans" is a cell array with FT channel names for putative
%     destination channels.
%   "srcchans" is a cell array with FT channel names for putative source
%     channels.
%   "delaylist_ms" is a vector containing the time lags tested in
%     milliseconds.
%   "windowrange_ms" is a vector containing the [ min max ] analysis window
%     locations used, in milliseconds (copied from "timeranges_ms").
%   "avg" is a matrix indexed by (destchan, srcchan, lagidx) containing
%     the average data values. NOTE - This is just the mean of "FOOavg",
%     ignoring "count".
%   "dev" is a matrix indexed by (destchan, srcchan, lagidx) containing
%     the standard deviation of the data values. NOTE - This is just the
%     standard deviation of "FOOavg", ignoring "var" and "count".


% Initialize output.

vstimelist = struct( 'destchans', {}, 'srcchans', {}, ...
  'delayrange_ms', {}, 'windowlist_ms', {}, 'avg', {}, 'dev', {} );

vslaglist = struct( 'destchans', {}, 'srcchans', {}, ...
  'delaylist_ms', {}, 'windowrange_ms', {}, 'avg', {}, 'dev', {} );


% Get metadata.

destchans = timelagdata.destchans;
destcount = length(destchans);

srcchans = timelagdata.srcchans;
srccount = length(srcchans);

laglist = timelagdata.delaylist_ms;
lagcount = length(laglist);

winlist = timelagdata.windowlist_ms;
wincount = length(winlist);


%
% Sanity-check the requested field, and extract it.

if ~isfield( timelagdata, datafield )
  % Try falling back to "FOOavg".
  if isfield( timelagdata, [ datafield 'avg' ] )
    datafield = [ datafield 'avg' ];
  else
    disp([ '### [euInfo_collapseTimeLagAverages]  Can''t find field "' ...
      datafield '".' ]);
    return;
  end
end

fieldavg = timelagdata.(datafield);



%
% Walk through the list of time lags, collapsing them.

for rangeidx = 1:length(lagranges_ms)

  lagspan = lagranges_ms{rangeidx};

  if isempty(lagspan)
    lagspan = [ -inf, inf ];
  end

  minlag = min(lagspan);
  maxlag = max(lagspan);

  thisrec = struct();
  thisrec.destchans = destchans;
  thisrec.srcchans = srcchans;
  thisrec.delayrange_ms = [ minlag maxlag ];
  thisrec.windowlist_ms = winlist;

  lagmask = (laglist >= minlag) & (laglist <= maxlag);

  % There's a Matlab syntax for this, but do this the oops-resistant way.
  thisavg = [];
  thisdev = [];
  for destidx = 1:destcount
    for srcidx = 1:srccount
      for widx = 1:wincount
        thisslice = fieldavg(destidx,srcidx,widx,lagmask);
        thisslice = thisslice(~isnan(thisslice));

        thisavg(destidx,srcidx,widx) = mean(thisslice);
        thisdev(destidx,srcidx,widx) = std(thisslice);
      end
    end
  end

  thisrec.avg = thisavg;
  thisrec.dev = thisdev;

  vstimelist(rangeidx) = thisrec;

end



%
% Walk through the list of window locations, collapsing them.

for rangeidx = 1:length(timeranges_ms)

  winspan = timeranges_ms{rangeidx};

  if isempty(winspan)
    winspan = [ -inf, inf ];
  end

  minwin = min(winspan);
  maxwin = max(winspan);

  thisrec = struct();
  thisrec.destchans = destchans;
  thisrec.srcchans = srcchans;
  thisrec.delaylist_ms = laglist;
  thisrec.windowrange_ms = [ minwin maxwin ];

  winmask = (winlist >= minwin) & (winlist <= maxwin);

  % There's a Matlab syntax for this, but do this the oops-resistant way.
  thisavg = [];
  thisdev = [];
  for destidx = 1:destcount
    for srcidx = 1:srccount
      for lidx = 1:lagcount
        thisslice = fieldavg(destidx,srcidx,winmask,lidx);
        thisslice = thisslice(~isnan(thisslice));

        thisavg(destidx,srcidx,lidx) = mean(thisslice);
        thisdev(destidx,srcidx,lidx) = std(thisslice);
      end
    end
  end

  thisrec.avg = thisavg;
  thisrec.dev = thisdev;

  vslaglist(rangeidx) = thisrec;

end



% Done.
end


%
% This is the end of the file.
