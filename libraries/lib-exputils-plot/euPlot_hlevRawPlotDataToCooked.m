function cookeddata = ...
  euPlot_hlevRawPlotDataToCooked( rawdata, xfield, yfield )

% function cookeddata = ...
%   euPlot_hlevRawPlotDataToCooked( rawdata, xfield, yfield )
%
% This function converts "raw" plot data into "cooked" plot data, as defined
% by PLOTDATARAW.txt and PLOTDATACOOKED.txt.
%
% "Raw" data stores multiple types of data from multiple time bins in one
% record. "Cooked" data stores data from a single data series and time bin
% in any given record.
%
% "rawdata" is a cell array of data structures, per PLOTDATARAW.txt.
% "xfield" is the name of the structure field containing the independent
%   data series (typically plotted on the X axis).
% "yfield" is the name of the structure field containing the dependent data
%   series (typically plotted on the Y axis).
%
% "cookeddata" is a structure array containing data to be plotted, per
%   PLOTDATACOOKED.txt.


% Initialize to an empty structure array with the correct fields.
cookeddata = struct( ...
  'sessionlabel', {}, 'caselabel', {}, 'probelabel', {}, ...
  'timelabel', {}, 'timevaluems', {}, ...
  'dataseriesx', {}, 'dataseriesy', {} );
cookedcount = 0;


% Walk through the input.
for rawidx = 1:length(rawdata)
  thisraw = rawdata{rawidx};
  if isfield(thisraw, xfield) && isfield(thisraw, yfield)

    % Data exists; copy it.

    templatecooked = struct( 'sessionlabel', thisraw.sessionlabel, ...
      'caselabel', thisraw.caselabel, 'probelabel', thisraw.probelabel );

    timelabellist = thisraw.timelabels;
    timemslist = thisraw.timevaluesms;
    datamatrixx = thisraw.(xfield);
    datamatrixy = thisraw.(yfield);


    % Figure out how many time bins and data points we have.
    % Data matrixes are Npoints x Nbins or Npoints x 1.

    timecount = length(timelabellist);

    datacount = 1;

    if ~ischar(datamatrixx)
      datacount = size(datamatrixx);
      datacount = datacount(1);
    elseif ~ischar(datamatrixy)
      datacount = size(datamatrixy);
      datacount = datacount(1);
    end


    % Promote any single-label data fields to cell arrays with replicated
    % values.

    if ischar(datamatrixx)
      scratch = datamatrixx;
      datamatrixx = cell(datacount, 1);
      datamatrixx(:) = { scratch };
    end

    if ischar(datamatrixy)
      scratch = datamatrixx;
      datamatrixx = cell(datacount, 1);
      datamatrixx(:) = { scratch };
    end


    % Figure out if either of the series is time-binned.
    % The number of columns should match the number of time bins if so.
    % Having a single time bin is allowed.

    scratch = size(datamatrixx);
    have_bins_x = (scratch(2) == timecount);

    scratch = size(datamatrixy);
    have_bins_y = (scratch(2) == timecount);


    % Force sanity, just in case we were given something strange.

    if ~have_bins_x
      datamatrixx = datamatrixx(:,1);
    end

    if ~have_bins_y
      datamatrixy = datamatrixy(:,1);
    end


    % Build data records.

    if have_bins_x || have_bins_y
      % Data is time-binned on at least one axis. Iterate.
      for tidx = 1:timecount

        if have_bins_x
          thiscol_x = datamatrixx(:,tidx);
        else
          thiscol_x = datamatrixx(:,1);
        end

        if have_bins_y
          thiscol_y = datamatrixy(:,tidx);
        else
          thiscol_y = datamatrixy(:,1);
        end

        thiscooked = templatecooked;
        thiscooked.timelabel = timelabellist{tidx};
        thiscooked.timevaluems = timemslist(tidx);
        thiscooked.dataseriesx = thiscol_x;
        thiscooked.dataseriesy = thiscol_y;

        cookedcount = cookedcount + 1;
        cookeddata(cookedcount) = thiscooked;

      end
    else
      % Data is not time-binned at all. Make one record.

      thiscooked = templatecooked;
      thiscooked.timelabel = '';
      thiscooked.timevaluems = NaN;
      thiscooked.dataseriesx = datamatrixx;
      thiscooked.dataseriesy = datamatrixy;

      cookedcount = cookedcount + 1;
      cookeddata(cookedcount) = thiscooked;
    end

  end
end


% Done.
end


%
% This is the end of the file.
