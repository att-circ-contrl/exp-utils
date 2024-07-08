function euPlot_hlevPlotNetwork( ampdata, lagdata, timevals_ms, ...
  plotconfig, firstlabels, secondlabels, plottitle, fname )

% function euPlot_hlevPlotNetwork( ampdata, lagdata, timevals_ms, ...
%   plotconfig, firstlabels, secondlabels, plottitle, fname )
%
% This renders a network graph and saves it to a file.
% If the data matrices are three-dimensional, this saves an animation.
% NOTE - The animation filename should end in '.avi', since that's the
% default video writer format.
%
% "ampdata" is a matrix indexed by (firstidx,secondidx,time) containing the
%   mean cross-correlation for each pair of channels.
% "lagdata" is a matrix indexed by (firstidx,secondidx,time) containing the
%   mean time lag for each pair of channels, in milliseconds.
% "timevals_ms" is a vector containing timestamps in milliseconds associated
%   with each frame, or [] for data that isn't a time series.
% "plotconfig" is a structure with the following fields:
%   "amp_range" [ min max ] is the range of cross-correlation magnitudes to
%     render using varying line widths.
%   "lag_range_ms" [ min max ] is the range of time lags to render using
%     different sized arrows.
%   "amp_rolloff" { min max } is the method used to deal with out-of-range
%     amplitude values ('nan', 'clamp', or 'sigmoid').
%   "lag_rolloff" { min max } is the method used to deal with out-of-range
%     time lag values ('nan', 'clamp', or 'sigmoid').
%   "layout" is 'circle' to position channels around a circle or 'adaptive'
%     to generate a t-SNE projection.
%   "anim_framerate" (optional) is the frame rate to use when writing the
%     animation. If this isn't present, a default frame rate is used.
% "firstlabels" is the list of first channel names.
% "secondlabels" is the list of second channel names.
% "plottitle" is the title to use for the plot.
% "fname" is the name of the file to write to.
%
% No return value.


%
% Get metadata.

firstcount = length(firstlabels);
secondcount = length(secondlabels);

if isempty(timevals_ms)
  % Dummy value for still frames.
  timevals_ms = [ 0 ];
end

timecount = length(timevals_ms);
want_anim = (timecount > 1);

want_adaptive = strcmp(plotconfig.layout, 'adaptive');



%
% Fiddle with channel lists and masks.

scratchfirst = firstlabels;
if ~isrow(scratchfirst)
  scratchfirst = transpose(scratchfirst);
end

scratchsecond = secondlabels;
if ~isrow(scratchsecond)
  scratchsecond = transpose(scratchsecond);
end

alllabels = sort(unique( [ scratchfirst scratchsecond ] ));
allcount = length(alllabels);

[ scratch safelabels ] = euUtil_makeSafeStringArray( alllabels );

pairmask = nlUtil_getPairMask(firstlabels, secondlabels);

% Get mappings from "first" and "second" to "all".
firstindices = helper_lookUpList( firstlabels, alllabels, 1:allcount );
secondindices = helper_lookUpList( secondlabels, alllabels, 1:allcount );



%
% Normalize the input data.

% There has to be a better way to do this masking.
for tidx = 1:timecount
  thisampslice = ampdata(:,:,tidx);
  thislagslice = lagdata(:,:,tidx);

  thisampslice(~pairmask) = NaN;
  thislagslice(~pairmask) = NaN;

  ampdata(:,:,tidx) = thisampslice;
  lagdata(:,:,tidx) = thislagslice;
end

ampsign = (ampdata > 0);
lagsign = (lagdata > 0);

ampdata = nlProc_rescaleDataValues( abs(ampdata), ...
  plotconfig.amp_range, plotconfig.amp_rolloff );
lagdata = nlProc_rescaleDataValues( abs(lagdata), ...
  plotconfig.lag_range_ms, plotconfig.lag_rolloff );



%
% Get a projected layout for the channels.

[ circx, circy ] = helper_getCirclePoints( allcount );

channelx = zeros(timecount,allcount);
channely = zeros(timecount,allcount);

if want_adaptive
  smoothwindow = 10;
  [ channelx channely ] = nlProc_projectGraphTSNE( ...
    ampdata, firstindices, secondindices, circx, circy, smoothwindow );
else
  for tidx = 1:timecount
    channelx(tidx,:) = circx;
    channely(tidx,:) = circy;
  end
end



%
% Set up for plotting.

thisfig = figure();
figure(thisfig);

cols = nlPlot_getColorPalette();

colourpos = cols.grn * 0.75 + cols.blu * 0.24;
colourneg = cols.brn * 0.75 + cols.wht * 0.24;

if want_anim
  desiredrate = 20;
  if isfield(plotconfig, 'anim_framerate')
    desiredrate = plotconfig.anim_framerate;
  end

  thiswriter = VideoWriter(fname);
  thiswriter.FrameRate = desiredrate;
  open(thiswriter);
end



%
% Render frames.

for tidx = 1:timecount

  % Get data.

  thistime = timevals_ms(tidx);

  ampweightslice = ampdata(:,:,tidx);
  ampsignslice = ampsign(:,:,tidx);

  lagweightslice = lagdata(:,:,tidx);
  lagsignslice = lagsign(:,:,tidx);


  % Get coordinates.

  firstx = channelx(tidx,firstindices);
  firsty = channely(tidx,firstindices);

  secondx = channelx(tidx,secondindices);
  secondy = channely(tidx,secondindices);


  % Reset the figure.

  clf('reset');
  thisax = gca;
  hold on;



  % FIXME - Magic sizes.

%  textbump = 0.15;
  textbump = 0.1;

  % Size 12 is okay up to 30-40 points.
  markersize = round(400 / allcount);
  markersize = min(markersize, 12);
  markersize = max(markersize, 1);

  % Size 16 is fine at 4 points, but use 8 max at 30-40.
  fontsize = round(300 / allcount);
  fontsize = min(fontsize, 16);
  fontsize = max(fontsize, 1);


  % Render nodes.

  for aidx = 1:allcount
    thisx = channelx(tidx,aidx);
    thisy = channely(tidx,aidx);

    plot( thisax, thisx, thisy, 'o', 'Color', cols.blk, ...
      'LineWidth', 3, 'MarkerSize', markersize, 'HandleVisibility', 'off' );


    if (thisy < 0)
      thisy = thisy - textbump;
    else
      thisy = thisy + textbump;
    end

    if (thisx < 0)
      thisx = thisx - textbump;
      thisalign = 'right';
    else
      thisx = thisx + textbump;
      thisalign = 'left';
    end

    text( thisax, thisx, thisy, safelabels{aidx}, 'FontSize', fontsize, ...
      'HorizontalAlignment', thisalign, 'VerticalAlignment', 'middle' );
  end


  % Render edges.

  for fidx = 1:firstcount
    for sidx = 1:secondcount

      thisamp = ampweightslice(fidx,sidx);
      thislag = lagweightslice(fidx,sidx);
      thisampsign = ampsignslice(fidx,sidx);
      thislagsign = lagsignslice(fidx,sidx);

      thiscol = colourneg;
      if thisampsign
        thiscol = colourpos;
      end

      if ~isnan(thisamp)

        x1 = firstx(fidx);
        y1 = firsty(fidx);
        x2 = secondx(sidx);
        y2 = secondy(sidx);

        % FIXME - Lots of magic values for lines!

        [ x1 y1 x2 y2 ] = helper_trimLine( x1, y1, x2, y2, 0.1 );

        % Line width is in points.
        linewidth = thisamp * 10 + 0.5;

        % Arrow width is in image coordinates.
        arrowwidth = thislag * 0.2;

        % Options are 'outline' and 'vee'.
        arrowtype = 'outline';

        if isnan(thislag)
          plot( [ x1 x2 ], [ y1 y2 ], 'Color', thiscol, ...
            'LineWidth', linewidth, 'HandleVisibility', 'off' );
        elseif thislagsign
          nlPlot_axesBasicArrow( thisax, [ x1 x2 ], [ y1 y2 ], ...
            linewidth, thiscol, arrowwidth, arrowwidth, arrowtype );
        else
          nlPlot_axesBasicArrow( thisax, [ x2 x1 ], [ y2 y1 ], ...
            linewidth, thiscol, arrowwidth, arrowwidth, arrowtype );
        end
      end

    end
  end

  % Legend lines.
  plot( nan, nan, 'Color', colourpos, 'DisplayName', 'positive xc' );
  plot( nan, nan, 'Color', colourneg, 'DisplayName', 'negative xc' );


  % Add decorations.

  hold off;

  title(plottitle);

  legend('Location', 'east');

  set(thisax, 'XColor', 'none');
  set(thisax, 'YColor', 'none');

  % FIXME - Hard-coding plot range.
  xlim([ -1.5 2.5 ]);
  ylim([ -1.5 1.5 ]);

  if want_anim
    timetext = sprintf('%d ms', thistime);
    text( thisax, 2.25, -1.25, timetext, 'FontSize', 16, ...
      'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle' );
  end


  % Write this frame.

  if want_anim
    thisframe = getframe(thisfig);
    writeVideo(thiswriter, thisframe);
  else
    saveas(thisfig, fname);
  end

end



%
% Finished plotting.

if want_anim
  close(thiswriter);
end

close(thisfig);


% Done.
end



%
% Helper Functions


% This gets coordinates of N points arranged around a unit circle.

function [ xposlist yposlist ] = helper_getCirclePoints(pointcount)

  % Start at the top and go clockwise.
  % Make the first and last points have the same Y value (i.e. start half
  % a wedge off from vertical).

  dtheta = 2 * pi / pointcount;

  theta = 1:pointcount;
  theta = theta - 0.5;
  theta = theta * dtheta;

  xposlist = sin(theta);
  yposlist = cos(theta);

end



% This performs a series of lookup table queries based on label values.

function targetvals = helper_lookUpList( targetlabels, lutlabels, lutvals )

  targetvals = [];

  for tidx = 1:length(targetlabels)
    lidx = min(find(strcmp( targetlabels{tidx}, lutlabels )));

    if isempty(lidx)
      targetvals(tidx) = NaN;
    else
      targetvals(tidx) = lutvals(lidx);
    end
  end

end



% This trims a fraction off of the ends of a line.

function [ newx1 newy1 newx2 newy2 ] = helper_trimLine( ...
  oldx1, oldy1, oldx2, oldy2, trimfrac )

  dx = (oldx2 - oldx1) * trimfrac;
  dy = (oldy2 - oldy1) * trimfrac;

  newx1 = oldx1 + dx;
  newy1 = oldy1 + dy;

  newx2 = oldx2 - dx;
  newy2 = oldy2 - dy;

end


%
% This is the end of the file.
