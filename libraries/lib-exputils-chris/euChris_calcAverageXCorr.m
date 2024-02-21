function [ vstimelist vslaglist ] = euChris_calcAverageXCorr( ...
  xcorrdata, timeranges_ms, lagranges_ms )

% function [ vstimelist vslaglist ] = euChris_calcAverageXCorr( ...
%   xcorrdata, timeranges_ms, lagranges_ms )
%
% This collapses a dataset produced by euChris_calcXCorr() by averaging
% across correlation lags (producing vs window time) and by averaging across
% window time (producing vs correlation lag). Mean and standard deviation
% for collapsed samples are reported.
%
% "xcorrdata" is a structure with raw cross-correlation data, per
%   CHRISXCORRDATA.txt.
% "timeranges_ms" is a cell array. Each cell specifies a window time range
%   [ min max ] in milliseconds to average across. A range of [] indicates
%   all window times.
% "lagranges_ms" is a cell array. Each cell specifies a correlation lag
%   range [ min max ] in milliseconds to average across. A range of []
%   indicates all correlation lags.
%
% "vstimelist" is a struct array, with a number of elements equal to the
%   number of correlation lag ranges. Each structure contains the following
%   fields:
%   "firstchans" is a cell array with FT channel names for the first set of
%     channels being compared.
%   "secondchans" is a cell array with FT channel names for the second set
%     of channels being compared.
%   "delayrange_ms" is a vector containing the [ min max ] time lag
%     sampled, in milliseconds (copied from "lagranges_ms").
%   "windowlist_ms" is a vector containing timestamps in milliseconds
%     specifying where the middle of each cross-correlation window is.
%   "xcorravg" is a matrix indexed by (firstchan, secondchan, winidx)
%     containing the average cross-correlation values.
%   "xcorrdev" is a matrix indexed by (firstchan, secondchan, winidx)
%     containing the standard deviation of the cross-correlation values.
%
% "vslaglist" is a struct array, with a number of elements equal to the
%   number of correlation lag ranges. Each structure contains the following
%   fields:
%   "firstchans" is a cell array with FT channel names for the first set of
%     channels being compared.
%   "secondchans" is a cell array with FT channel names for the second set
%     of channels being compared.
%   "delaylist_ms" is a vector containing the time lags tested in
%     milliseconds.
%   "windowrange_ms" is a vector containing the [ min max ] window locations
%     sampled, in milliseconds (copied from "timeranges_ms").
%   "xcorravg" is a matrix indexed by (firstchan, secondchan, lagidx)
%     containing the average cross-correlation values.
%   "xcorrdev" is a matrix indexed by (firstchan, secondchan, lagidx)
%     containing the standard deviation of the cross-correlation values.


% Initialize output.

vstimelist = struct( 'firstchans', {}, 'secondchans', {}, ...
  'delayrange_ms', {}, 'windowlist_ms', {}, 'xcorravg', {}, 'xcorrdev', {} );

vslaglist = struct( 'firstchans', {}, 'secondchans', {}, ...
  'delaylist_ms', {}, 'windowrange_ms', {}, 'xcorravg', {}, 'xcorrdev', {} );


% Get metadata.

firstchans = xcorrdata.firstchans;
firstcount = length(firstchans);

secondchans = xcorrdata.secondchans;
secondcount = length(secondchans);

laglist = xcorrdata.delaylist_ms;
lagcount = length(laglist);

winlist = xcorrdata.windowlist_ms;
wincount = length(winlist);



%
% Walk through the list of time lags, collapsing them.

for rangeidx = 1:length(lagranges_ms)

  lagspan = lagranges_ms{rangeidx};

  if isempty(lagspan)
    lagspan = xcorrdata.delaylist_ms;
  end

  minlag = min(lagspan);
  maxlag = max(lagspan);

  thisrec = struct();
  thisrec.firstchans = xcorrdata.firstchans;
  thisrec.secondchans = xcorrdata.secondchans;
  thisrec.delayrange_ms = [ minlag maxlag ];
  thisrec.windowlist_ms = xcorrdata.windowlist_ms;

  lagmask = (laglist >= minlag) & (laglist <= maxlag);

  % There's a Matlab syntax for this, but do this the oops-resistant way.
  thisavg = [];
  thisdev = [];
  for fidx = 1:firstcount
    for sidx = 1:secondcount
      for widx = 1:wincount
        thisslice = xcorrdata.xcorravg(fidx,sidx,widx,lagmask);
        thisavg(fidx,sidx,widx) = mean(thisslice);
        thisdev(fidx,sidx,widx) = std(thisslice);
      end
    end
  end

  thisrec.xcorravg = thisavg;
  thisrec.xcorrdev = thisdev;

  vstimelist(rangeidx) = thisrec;

end



%
% Walk through the list of window locations, collapsing them.

for rangeidx = 1:length(timeranges_ms)

  winspan = timeranges_ms{rangeidx};

  if isempty(winspan)
    winspan = xcorrdata.windowlist_ms;
  end

  minwin = min(winspan);
  maxwin = max(winspan);

  thisrec = struct();
  thisrec.firstchans = xcorrdata.firstchans;
  thisrec.secondchans = xcorrdata.secondchans;
  thisrec.delaylist_ms = xcorrdata.delaylist_ms;
  thisrec.windowrange_ms = [ minwin maxwin ];

  winmask = (winlist >= minwin) & (winlist <= maxwin);

  % There's a Matlab syntax for this, but do this the oops-resistant way.
  thisavg = [];
  thisdev = [];
  for fidx = 1:firstcount
    for sidx = 1:secondcount
      for lidx = 1:lagcount
        thisslice = xcorrdata.xcorravg(fidx,sidx,winmask,lidx);
        thisavg(fidx,sidx,lidx) = mean(thisslice);
        thisdev(fidx,sidx,lidx) = std(thisslice);
      end
    end
  end

  thisrec.xcorravg = thisavg;
  thisrec.xcorrdev = thisdev;

  vslaglist(rangeidx) = thisrec;

end



% Done.
end


%
% This is the end of the file.
