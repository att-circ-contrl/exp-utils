function euPlot_axesPlotSignificantHeatmap( thisax, yxdata, yxsig, ...
  xvalues, yvalues, xrange, yrange, xtitle, ytitle, figtitle )

% function euPlot_axesPlotSignificantHeatmap( thisax, yxdata, yxsig, ...
%   xvalues, yvalues, xrange, yrange, xtitle, ytitle, figtitle )
%
% This plots a heatmap, annotating entries flagged as significant.
%
% This is a wrapper for nlPlot_axesPlotSurface2D that pulls shenanigans to
% work around the Z ordering issues Matlab has on Linux.
%
% "thisax" is the "axes" object to render to.
% "yxdata" is a matrix indexed by (y,x) of data values to plot.
% "yxsig" is a boolean matrix indexed by (y,x) that's true for significant
%   values and false otherwise.
% "xvalues" is a series of X coordinate values corresponding to each column
%   of data. These may be numbers or labels.
% "yvalues" is a series of X coordinate values corresponding to each row of
%   data. These may be numbers or labels.
% "xrange" [ min max ] is the range of X values to render, or [] for auto.
% "yrange" [ min max ] is the range of Y values to render, or [] for auto.
% "xtitle" is the title to use for the X axis, or '' to not set one.
% "ytitle" is the title to use for the Y axis, or '' to not set one.
% "figtitle" is the title to use for the figure, or '' to not set one.
%
% No return value.


%
% Interpolate the grid so that each original cell is a 3x3 cell in the new
% grid.


rowcount = length(yvalues);
colcount = length(xvalues);

olddata = yxdata;
oldsig = yxsig;

newdata = [];
newsig = logical([]);

for rowidx = 1:rowcount
  thisrow = olddata(rowidx,:);
  newdata = [ newdata ; thisrow ; thisrow ; thisrow ];

  thisrow = oldsig(rowidx,:);
  newsig = [ newsig ; thisrow ; thisrow ; thisrow ];
end

olddata = newdata;
oldsig = newsig;

newdata = [];
newsig = logical([]);

for colidx = 1:colcount
  thiscol = olddata(:,colidx);
  newdata = [ newdata thiscol thiscol thiscol ];

  thiscol = oldsig(:,colidx);
  newsig = [ newsig thiscol thiscol thiscol ];
end

newxvalues = helper_padScale(xvalues);
newyvalues = helper_padScale(yvalues);



%
% Render the annotated heatmap.


% NaN out anything significant (to make a hole) and call axesPlotSurface2D.

for rowidx = 1:rowcount
  for colidx = 1:colcount
    if yxsig(rowidx,colidx)
      newdata( 3*rowidx - 1 , 3*colidx - 1 ) = NaN;
    end
  end
end

nlPlot_axesPlotSurface2D( thisax, newdata, newxvalues, newyvalues, ...
  xrange, yrange, 'linear', 'linear', 'linear', xtitle, ytitle, figtitle );


% Add annotations in the resulting gaps.
% Don't worry about the Z values for the text objects; Z order doesn't
% work reliably here, and we left a hole for the text to make it moot.

% NOTE - We need to convert text labels to indices, if we had labels.
if iscell(newxvalues)
  newxvalues = 1:length(newxvalues);
end
if iscell(newyvalues)
  newyvalues = 1:length(newyvalues);
end

for rowidx = 1:rowcount
  for colidx = 1:colcount
    if yxsig(rowidx,colidx)
      thisy = newxvalues( 3*rowidx - 1 );
      thisx = newxvalues( 3*colidx - 1 );

      % Vertical alignment defaults to 'middle', but that's the middle of
      % the character cell, not the visible strokes. '*' is at the top of
      % the cell, '\ast' is a lower-case letter (not middle-aligned).
      % Using '\ast' with 'middle' is barely tolerable.
      % Using '\times' with 'middle' is slightly worse.
      % Using '\circ' with 'middle' is also slightly worse.

      text( thisax, thisx, thisy, '\ast', 'FontSize', 32, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle' );
    end
  end
end



% Done.
end



%
% Helper Functions

function newscale = helper_padScale(oldscale)

  % Tolerate both numeric and text labels.

  if iscell(oldscale)
    newscale = {};
    for sidx = 1:length(oldscale)
      newscale = [ newscale {''} oldscale(sidx) {''} ];
    end
  else
    newscale = [];
    edgevals = nlProc_getBinEdgesFromMidpoints(newscale, 'linear');

    for sidx = 1:length(oldscale)
      thisleft = edgevals(sidx);
      thisright = edgevals(sidx+1);
      thisdiff = thisright - thisleft;

      leftbin = thisleft + 0.1667 * thisdiff;
      midbin = oldscale(sidx);
      rightbin = thisleft + 0.8333 * thisdiff;

      newscale = [ newscale leftbin midbin rightbin ];
    end
  end

end



%
% This is the end of the file.
