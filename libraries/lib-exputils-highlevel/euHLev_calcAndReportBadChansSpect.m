function badchanlist = euHLev_calcAndReportBadChansSpect( ...
  cachefilename, checkdata, checkchans, checkconfig, ...
  plotswanted, titleprefix, fileprefix )

% function badchanlist = euHLev_calcAndReportBadChansSpect( ...
%   cachefilename, checkdata, checkchans, checkconfig, ...
%   plotswanted, titleprefix, fileprefix )
%
% This attempts to identify bad channels within ephys data by looking for
% channels with abnormal spectra compared the group as a whole.
%
% The analysis data is optionally read from or saved to a cache file to
% avoid repeated re-analysis.
%
% "cachefilename" is the name of the cache file to use, or '' for no cache.
% "checkdata" is either a ft_datatype_raw structure containing ephys data,
%   in Field Trip format, or a folder to read ephys data from via Field Trip.
% "checkchans" is a cell array containing the names of channels to analyze.
%   If this is {}, all channels are analyzed.
% "checkconfig" is a configuration struture per euTools_guessBadChannelsSpect.
% "plotswanted" is a cell array with zero or more of the following:
%   'rawscatter' scatter-plots raw power and tone statistics.
%   'rawhist' shows histograms of power and tone statistics.
%   'rawheatmap' plots power and tone statistics vs channel and band.
%   'pcascatter' scatter-plots PCA-reduced power and tone statistics.
%   'chanlists' emits lists of bad channels.
% "titleprefix" is a prefix to use when building plot titles.
% "fileprefix" is a prefix to use when building plot and report filenames.
%
% "badchanlist" is a cell array containing the FT names of bad channels.


%
% Wrap the euTools function to do the actual analysis.

disp('-- Looking for bad channels via spectral analysis.');

want_cache = ~isempty(cachefilename);

if want_cache && exist(cachefilename, 'file')
  disp('.. Loading spectral analysis from cache.');
  load( cachefilename );
else
  [ checkconfig chanlabels changoodvec ...
    spectpower tonepower pcacoords ...
    spectclusters toneclusters pcaclusters ] = ...
    euTools_guessBadChannelsSpect( checkdata, checkchans, checkconfig );

  if want_cache
    save( cachefilename, 'checkconfig', 'chanlabels', 'changoodvec', ...
      'spectpower', 'tonepower', 'pcacoords', ...
      'spectclusters', 'toneclusters', 'pcaclusters', '-v7.3' );
  end
end

disp(sprintf( '-- Found %d bad channels (of %d total).', ...
  sum(~changoodvec), length(changoodvec) ));



%
% Build a report, if requested.

badchanlist = chanlabels(~changoodvec);

% List these in sorted order.
badchanlist = sort(badchanlist);

reporttext = sprintf('%s - Bad Channel List:\n', titleprefix);
for cidx = 1:length(badchanlist)
  reporttext = [ reporttext sprintf('%12s\n', badchanlist{cidx}) ];
end
reporttext = [ reporttext sprintf('End of list.\n') ];

if ismember('chanlists', plotswanted)
  nlIO_writeTextFile( [ fileprefix '-badchans.txt' ], reporttext );
end



%
% Generate plots, if requested.


% Get a scratch figure.
thisfig = figure();
figure(thisfig);


% Get metadata.

chancount = length(changoodvec);
bandcount = length(checkconfig.freqbinedges) - 1;

bandlabels = {};
bandtitles = {};
for bidx = 1:bandcount
  thismin = round(checkconfig.freqbinedges(bidx));
  thismax = round(checkconfig.freqbinedges(bidx+1));
  % NOTE - Not calculating midpoint. It won't be a pretty value.
  bandlabels{bidx} = sprintf('%04d-%04dhz', thismin, thismax);
  bandtitles{bidx} = sprintf('%d Hz to %d Hz', thismin, thismax);
end

[ chanlabelssafe chantitles ] = euUtil_makeSafeStringArray( chanlabels );

pcadims = checkconfig.pcadims;

cols = nlPlot_getColorPalette();

% Get geometry information for resizing the figure.
[ oldpos newpos ] = nlPlot_makeFigureTaller( thisfig, chancount, 32 );



%
% Raw data plots.

want_raw_scatter = ismember('rawscatter', plotswanted);
want_raw_hist = ismember('rawhist', plotswanted);
want_raw_heatmap = ismember('rawheatmap', plotswanted);

if want_raw_scatter || want_raw_hist

  % These plots are iterated per-band.

  for bidx = 1:bandcount

    thisbandlabel = bandlabels{bidx};
    thisbandtitle = bandtitles{bidx};

    % Data to be plotted.

    thispower = spectpower(:,bidx);
    thistone = tonepower(:,bidx);
    thischanidx = [];
    thischanidx(1:chancount,1) = 1:chancount;

    % Cluster information.

    thispowertags = spectclusters(:,bidx);
    thistonetags = toneclusters(:,bidx);

    powercount = max(thispowertags);
    tonecount = max(thistonetags);

    % Ask for N+1 colours, since the last is the same as the first.
    powercols = nlPlot_getColorSpread(cols.blu, (powercount+1), 360);
    tonecols = nlPlot_getColorSpread(cols.blu, (tonecount+1), 360);


    % Scatter plots.
    % X axis is total power or relative tone power.
    % Y axis is the channel index. FIXME - This would ideally be the label!

    if want_raw_scatter

      % Total absolute power.

      clf('reset');
      thisfig.Position = newpos;
      hold on;

      for tidx = 1:powercount
        thismask = (thispowertags == tidx);
        goodmask = thismask & changoodvec;
        badmask = thismask & (~changoodvec);

        thisdata = thispower(goodmask);
        if ~isempty(thisdata)
          plot( thisdata, thischanidx(goodmask), ...
            '+', 'Color', powercols{tidx}, 'HandleVisibility', 'off' );
        end

        thisdata = thispower(badmask);
        if ~isempty(thisdata)
          plot( thisdata, thischanidx(badmask), ...
            'o', 'Color', powercols{tidx}, 'HandleVisibility', 'off' );
        end
      end

      hold off;

      legend('off');

      title([ titleprefix ' - Channel Power (' thisbandtitle ')' ]);
      xlabel('In-Band Power (a.u.)');
      ylabel('Channel');

      saveas( thisfig, [ fileprefix '-chanpower-' thisbandlabel '.png' ] );


      % Peak power relative to baseline. Tones will have high peak power.

      clf('reset');
      thisfig.Position = newpos;
      hold on;

      for tidx = 1:tonecount
        thismask = (thistonetags == tidx);
        goodmask = thismask & changoodvec;
        badmask = thismask & (~changoodvec);

        thisdata = thistone(goodmask);
        if ~isempty(thisdata)
          plot( thisdata, thischanidx(goodmask), ...
            '+', 'Color', tonecols{tidx}, 'HandleVisibility', 'off' );
        end

        thisdata = thistone(badmask);
        if ~isempty(thisdata)
          plot( thisdata, thischanidx(badmask), ...
            'o', 'Color', tonecols{tidx}, 'HandleVisibility', 'off' );
        end
      end

      hold off;

      legend('off');

      title([ titleprefix ' - Peak Power (' thisbandtitle ')' ]);
      xlabel('Peak Power (normalized)');
      ylabel('Channel');

      saveas( thisfig, [ fileprefix '-chantones-' thisbandlabel '.png' ] );


      % Restore original geometry.
      thisfig.Position = oldpos;

    end


    % Histogram plots.
    % X axis is total power or relative tone power.
    % Y axis is the number of channels.

    if want_raw_hist
% FIXME - NYI.
    end

  end
end


if want_raw_heatmap

  % Cyan-and-yellow heatmap.
  colmap = nlPlot_getColorMapHotCold( ...
    [ 0.6 0.9 1.0 ], [ 1.0 0.9 0.3 ], 1.0 );


  % Transform the data for plotting.
  % For power, keep it linear and make it relative to median and quartiles.
  % For tones, make it log-scale and scale it to the median (it's one-sided).

  plotpower = spectpower;
  plottone = log10(tonepower);

  for bidx = 1:bandcount
    % Total in-band power.
    % Normalize so that the median power is 0.
    % Scale above and below median independently, so that quartiles are +/- 1.
    % NOTE - Rescale so that quartiles are +/- 0.67, and we're getting
    % standard deviations from the median (approximately).

    thispower = plotpower(:,bidx);
    thispower = thispower - median(thispower);

    posmask = (thispower >= 0);
    negmask = ~posmask;
    posamp = prctile(thispower, 75);
    negamp = prctile(thispower, 25);

    thispower(posmask) = thispower(posmask) / posamp;
    thispower(negmask) = thispower(negmask) / abs(negamp);

    % Rescale so that we're standard deviations rather than quartiles.
    % This is approximate!
    thispower = 0.67 * thispower;

    plotpower(:,bidx) = thispower;


    % Tone power.
    % Minimum is log(1) = 0. Maximum is arbitrary.
    % Normalize so that the median relative tone power is 1.

    thistone = plottone(:,bidx);
    plottone(:,bidx) = thistone / median(thistone);
  end


  % Render heatmaps.
  % Data is indexed by (channel,band), and plotted as (y,x), which is fine.


  clf('reset');
  thisfig.Position = newpos;
  colormap(thisfig, colmap);

  nlPlot_axesPlotSurface2D( gca, plotpower, ...
    bandtitles, chantitles, [], [], ...
    'linear', 'linear', 'linear', ...
    'Band', 'Channel', ...
    [ titleprefix ' - Channel Power' ] );

  % Median 0, quartiles at +/- 0.67 (deviations +/- 1 approximately).
  clim([ -3 3 ]);

  thiscol = colorbar;
  thiscol.Label.String = 'Normalized In-Band Power';

  saveas( thisfig, [ fileprefix '-chanpowerheat.png' ] );


  clf('reset');
  thisfig.Position = newpos;
  colormap(thisfig, colmap);

  nlPlot_axesPlotSurface2D( gca, plottone, ...
    bandtitles, chantitles, [], [], ...
    'linear', 'linear', 'linear', ...
    'Band', 'Channel', ...
    [ titleprefix ' - Tone Power' ] );

  % Minimum 0, median 1, log10 scale.
  clim([ 0 3 ]);

  thiscol = colorbar;
  thiscol.Label.String = 'Normalized Tone Power (log)';

  saveas( thisfig, [ fileprefix '-chantonesheat.png' ] );


  % Restore original geometry.
  thisfig.Position = oldpos;

end



%
% PCA plots.

want_pca_scatter = ismember('pcascatter', plotswanted);

if want_pca_scatter

  % Data to be plotted.
  % Plot the first two principal components if present.
  % If we only have one component, plot against channel index.
  % FIXME - This would ideally be channel label, not index!

  thispca_x = pcacoords(:,1);

  if pcadims > 1
    thispca_y = pcacoords(:,2);
  else
    thispca_y = [];
    thispca_y(1:chancount,1) = 1:chancount;
  end

  % Cluster information.

  tagcount = max(pcaclusters);

  % Ask for N+1 colours, since the last is the same as the first.
  pcacols = nlPlot_getColorSpread(cols.blu, (tagcount+1), 360);


  % Scatter plot.

  clf('reset');
  hold on;

  for tidx = 1:tagcount
    thismask = (pcaclusters == tidx);
    goodmask = thismask & changoodvec;
    badmask = thismask & (~changoodvec);

    thisdata_x = thispca_x(goodmask);
    thisdata_y = thispca_y(goodmask);
    if ~isempty(thisdata_x)
      plot( thisdata_x, thisdata_y, ...
        '+', 'Color', pcacols{tidx}, 'HandleVisibility', 'off' );
    end

    thisdata_x = thispca_x(badmask);
    thisdata_y = thispca_y(badmask);
    if ~isempty(thisdata_x)
      plot( thisdata_x, thisdata_y, ...
        'o', 'Color', pcacols{tidx}, 'HandleVisibility', 'off' );
    end
  end

  hold off;

  legend('off');

  title([ titleprefix ' - Power PCA' ]);
  xlabel('First Principal Component');
  if pcadims > 1
    ylabel('Second Principal Component');
  else
    ylabel('Channel');
  end

  saveas( thisfig, [ fileprefix '-chanpca.png' ] );

end



% Dispose of the scratch figure.
close(thisfig);



% Done.
end


%
% This is the end of the file.
