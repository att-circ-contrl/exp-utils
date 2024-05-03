function newdata = euInfo_smoothTimeLagAverages( ...
  olddata, fieldnames, timesmooth_ms, lagsmooth_ms, method );

% function newdata = euInfo_smoothTimeLagAverages( ...
%   olddata, fieldnames, timesmooth_ms, lagsmooth_ms, method );
%
% This function smooths time-and-lag analysis data and optionally re-bins it
% using coarser bins. This operates on data that has already been averaged
% across trials.
%
% "olddata" is a data structure per TIMEWINLAGDATA.txt. This should contain
%   "avg", "var", and "count" fields for the desired data fields.
% "fieldnames" is a cell array containing field name prefixes used to define
%   the "avg", "var", and "count" fields being operated on.
% "timesmooth_ms" is the smoothing/binning window size for window times, in
%   milliseconds. Specify NaN to not smooth window times.
% "lagsmooth_ms" is the smoothing/binning window size for correlation time
%   lags, in milliseconds. Specify NaN to not smooth lags.
% "method" is 'smooth' to perform smoothing and keep the same bins, or
%   'coarse' to re-bin into larger bins.
%
% "newdata" is a data structure per TIMEWINLAGDATA.txt containing data from
%   the requested fields that's either smoothed or re-binned. Metadata is
%   copied from "olddata", with delay and window lists modified if re-binning
%   was performed.


%
% Initialize.

newdata = struct();
newdata.firstchans = olddata.firstchans;
newdata.secondchans = olddata.secondchans;


%
% Get metadata.

want_decimate = strcmp(method, 'coarse');

firstcount = length(olddata.firstchans);
secondcount = length(olddata.secondchans);

delaylist_ms = olddata.delaylist_ms;
windowlist_ms = olddata.windowlist_ms;

delaycount = length(delaylist_ms);
windowcount = length(windowlist_ms);


%
% Figure out our bin mappings.

% This has to tolerate nonuniform bins.

[ delaysources delaylist_new ] = ...
  helper_mapBins( delaylist_ms, lagsmooth_ms, want_decimate );
[ windowsources windowlist_new ] = ...
  helper_mapBins( windowlist_ms, timesmooth_ms, want_decimate );


%
% Store modified bin metadata.

newdata.delaylist_ms = delaylist_new;
newdata.windowlist_ms = windowlist_new;

newdelaycount = length(delaylist_new);
newwindowcount = length(windowlist_new);


%
% Sanity-check the field list.

newfields = {};
for fidx = 1:length(fieldnames)
  thisfield = fieldnames{fidx};

  if isfield( olddata, [ thisfield 'avg' ] ) ...
    && isfield( olddata, [ thisfield 'var' ] ) ...
    && isfield( olddata, [ thisfield 'count' ] )
    newfields = [ newfields { thisfield } ];
  else
    disp([ '### [euInfo_smoothTimeLagAverages]  Can''t find field "' ...
      thisfield '".' ]);
  end
end
fieldnames = newfields;



%
% Build the new data arrays.

for fidx = 1:length(fieldnames)

  thisfield = fieldnames{fidx};

  fieldavg = olddata.([ thisfield 'avg' ]);
  fieldcount = olddata.([ thisfield 'count' ]);
  fieldvar = olddata.([ thisfield 'var' ]);

  newavg = zeros([ firstcount secondcount newwindowcount newdelaycount ]);
  newvar = zeros(size(newavg));
  newcount = zeros(size(newavg));

  for didxnew = 1:newdelaycount
    for widxnew = 1:newwindowcount

      thisdelaysrclist = delaysources{didxnew};
      thiswindowsrclist = windowsources{widxnew};

      thisavg = zeros([ firstcount secondcount ]);
      thisvar = zeros(size(thisavg));
      thiscount = zeros(size(thisavg));

      for didxsrc = 1:length(thisdelaysrclist)
        for widxsrc = 1:length(thiswindowsrclist)

          didxold = thisdelaysrclist(didxsrc);
          widxold = thiswindowsrclist(widxsrc);

          % These are (firstidx,secondidx) matrices, not scalars.

          oldavg = fieldavg(:,:,widxold,didxold);
          oldcount = fieldcount(:,:,widxold,didxold);
          oldvar = fieldvar(:,:,widxold,didxold);

          validmask = (~isnan(oldavg)) & (oldcount > 0);

          thisavg(validmask) = thisavg(validmask) ...
            + ( oldavg(validmask) .* oldcount(validmask) );
          thisvar(validmask) = thisvar(validmask) ...
            + ( oldvar(validmask) .* oldcount(validmask) );
          thiscount(validmask) = thiscount(validmask) + oldcount(validmask);

        end
      end

      % Anything with a count of 0 gets turned into NaN, which is fine.
      thisavg = thisavg ./ thiscount;
      thisvar = thisvar ./ thiscount;

      newavg(:,:,widxnew,didxnew) = thisavg;
      newvar(:,:,widxnew,didxnew) = thisvar;
      newcount(:,:,widxnew,didxnew) = thiscount;

    end
  end

  newdata.([ thisfield 'avg' ]) = newavg;
  newdata.([ thisfield 'count' ]) = newcount;
  newdata.([ thisfield 'var' ]) = newvar;

end


% Done.
end



%
% Helper Functions


% This identifies which old bins contribute to each new bin.
% This also lists centres of new bins, to account for decimation.
% A smoothing window of NaN means "don't smooth/decimate".

function [ mapsources newlist ] = ...
  helper_mapBins( oldlist, smoothwindow, want_decimate )

  if isnan(smoothwindow)
    mapsources = 1:length(oldlist);
    mapsources = num2cell(mapsources);
    newlist = oldlist;
  else
    % Do this by brute force. O(n2) is fine here.

    mapsources = {};
    newlist = [];

    % Trim or pad these by a small amount to avoid precision issues.
    smoothradius = 0.51 * smoothwindow;
    decimstep = 0.99 * smoothwindow;

    lastnew = -inf;

    for oldidx = 1:length(oldlist)

      thispos = oldlist(oldidx);

      wantkeep = true;
      if want_decimate
        wantkeep = ( (thispos - lastnew) >= decimstep );
      end

      if wantkeep
        lastnew = thispos;

        minval = thispos - smoothradius;
        maxval = thispos + smoothradius;

        thismap = find( (oldlist >= minval) & (oldlist <= maxval) );

        mapsources = [ mapsources { thismap } ];
        newlist = [ newlist thispos ];
      end

    end
  end

end


%
% This is the end of the file.
