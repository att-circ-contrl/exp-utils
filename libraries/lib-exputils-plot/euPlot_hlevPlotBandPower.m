function euPlot_hlevPlotBandPower( bandpower, tonepower, ...
  bandlabels, chanlabels, triallabels, bandpowerrange, tonepowerrange, ...
  plotswanted, titleprefix, fileprefix )

% function euPlot_hlevPlotBandPower( bandpower, tonepower, ...
%   bandlabels, chanlabels, triallabels, bandpowerrange, tonepowerrange, ...
%   plotswanted, titleprefix, fileprefix )
%
% This makes plots of in-band power and tone power data returned by
%  nlProc_getBandPower().
%
% If multiple trials are defined, an additional plot is generated with the
% average across trials (trial name 'Average').
%
% If only one trial is defined, trial labels aren't rendered or used for
% filenames.
%
% If plot ranges aren't specified, reasonable defaults are used that assume
% the power values have been z-scored.
%
% "bandpower" is a nChans x nBands x nTrials matrix containing per-band
%   total power for each channel, band, and trial.
% "tonepower" is a nChans x nBands x nTrials matrix containing the ratio
%   of maximum component power to median component power of in-band
%   frequencies.
% "bandlabels" is a cell array of character vectors, or a vector with
%   nBands elements specifying band midpoint frequencies, or a vector with
%   nBands+1 elements specifying band edge frequencies. If this is {} or [],
%   labels are automatically generated.
% "chanlabels" is a cell array of character vectors, or a vector with
%   channel numbers. If this is {} or [], labels are automatically generated.
% "triallabels" is a cell array of character vectors, or a vector with trial
%   numbers. If this is {} or [], labels are automatically generated.
% "bandpowerrange" [ min max ] is the Z range to use when plotting in-band
%   power heatmaps, or [] to use a default range.
% "tonepowerrange" [ min max ] is the Z range to use when plotting tone
%   power heatmaps, or [] to use a default range.
% "plotswanted" is a cell array with zero or more of the following:
%   'powerbychan' - In-band power for each channel; one plot per band/trial.
%   'tonebychan' - Tone power for each channel; one plot per band/trial.
%   'powerheatmap' - In-band power vs channel and band; one plot per trial.
%   'toneheatmap' - Tone power vs channel and band; one plot per trial.
% "titleprefix" is a prefix used when building plot titles.
% "fileprefix" is a prefix used when building output filenames.
%
% No return value.


% Get metadata.

chancount = size(bandpower,1);
bandcount = size(bandpower,2);
trialcount = size(bandpower,3);


% Set magic ranges.

if isempty(bandpowerrange)
  % +/- 3 sigma, with midpoint at the mean.
  bandpowerrange = [ -3 3 ];
end

if isempty(tonepowerrange)
  % Midpoint at +1 sigma, wide enough range to catch extreme values.
  % Tones from noise tend to be really strong.
  tonepowerrange = [ -4 6 ];
end



%
% Get labels.


% If we're missing any label series, generate them.

if isempty(chanlabels)
  chanlabels = 1:chancount;
end

if isempty(bandlabels)
  bandlabels = 1:bandcount;
  bandlabels = nlUtil_sprintfCellArray('Band %02d', bandlabels);
end

if isempty(triallabels)
  triallabels = 1:trialcount;
end


% If any label series are numbers, convert them.

% NOTE - We want different formats for "titles" vs "labels"; prepare both.
chantitles = {};
bandtitles = {};
trialtitles = {};

if ~iscell(chanlabels)
  chantitles = nlUtil_sprintfCellArray('CH %03d', chanlabels);
  chanlabels = nlUtil_sprintfCellArray('ch%04d', chanlabels);
end

if ~iscell(bandlabels)
  bandlabels = round(bandlabels);

  if length(bandlabels) > bandcount
    scratch = bandlabels;
    bandlabels = {};
    for bidx = 1:bandcount
      bandtitles{bidx} = ...
        sprintf('%d Hz to %d Hz', scratch(bidx), scratch(bidx+1) );
      bandlabels{bidx} = ...
        sprintf('%04d-%04dhz', scratch(bidx), scratch(bidx+1) );
    end
  else
    bandtitles = nlUtil_sprintfCellArray('%d Hz', bandlabels);
    bandlabels = nlUtil_sprintfCellArray('%04dhz', bandlabels);
  end
end

if ~iscell(triallabels)
  trialtitles = nlUtil_sprintfCellArray('Tr %04d', triallabels);
  triallabels = nlUtil_sprintfCellArray('tr%04d', triallabels);
end


% If any titles are uninitialized, initialize them.
% This happens if we were given label strings instead of numbers.
% This also sanitizes the user-provided label strings.

if isempty(chantitles)
  [ chanlabels chantitles ] = euUtil_makeSafeStringArray( chanlabels );
end

if isempty(bandtitles)
  [ bandlabels bandtitles ] = euUtil_makeSafeStringArray( bandlabels );
end

if isempty(trialtitles)
  [ triallabels trialtitles ] = euUtil_makeSafeStringArray( triallabels );
end



%
% If we have multiple trials, make an additional "average" trial.

if trialcount > 1
  scratch = mean(bandpower, 3);
  bandpower(:,:,trialcount+1) = scratch;

  scratch = mean(tonepower,3);
  tonepower(:,:,trialcount+1) = scratch;

  triallabels{trialcount+1} = 'avg';
  trialtitles{trialcount+1} = 'Average';

  trialcount = trialcount + 1;
end



%
% Generate plots.


% Get a scratch figure.
thisfig = figure();
figure(thisfig);


% Get colours.
cols = nlPlot_getColorPalette();

% Cyan-and-yellow heatmap.
colmap = nlPlot_getColorMapHotCold( [ 0.6 0.9 1.0 ], [ 1.0 0.9 0.3 ], 1.0 );

% Get geometry information for resizing the figure.
[ oldpos newpos ] = nlPlot_makeFigureTaller( thisfig, chancount, 32 );


% Get plotting flags.

want_powerbychan = ismember('powerbychan', plotswanted);
want_tonebychan = ismember('tonebychan', plotswanted);

want_powerheat = ismember('powerheatmap', plotswanted);
want_toneheat = ismember('toneheatmap', plotswanted);


% Iterate trials.

trialtitlesuffix = '';
triallabelsuffix = '';

for tidx = 1:trialcount

  if trialcount > 1
    trialtitlesuffix = [ ' - ' trialtitles{tidx} ];
    triallabelsuffix = [ '-' triallabels{tidx} ];
  end


  % These plots are iterated per-band.
  for bidx = 1:bandcount

    thisbandlabel = bandlabels{bidx};
    thisbandtitle = bandtitles{bidx};

    thispower = bandpower(:,bidx,tidx);
    thistone = tonepower(:,bidx,tidx);

    if want_powerbychan
      clf('reset');
      thisfig.Position = newpos;

      plot( thispower, 1:chancount, ...
            '+', 'Color', cols.blu, 'HandleVisibility', 'off' );

      legend('off');

      title([ titleprefix ' - Channel Power (' thisbandtitle ')' ...
        trialtitlesuffix ]);
      xlabel('In-Band Power');
      ylabel('Channel');

      set( gca, 'YTick', 1:chancount, 'YTickLabel', chantitles );

      saveas( thisfig, [ fileprefix '-chanpower-' thisbandlabel ...
        triallabelsuffix '.png' ] );
    end

    if want_tonebychan
      clf('reset');
      thisfig.Position = newpos;

      plot( thistone, 1:chancount, ...
            '+', 'Color', cols.blu, 'HandleVisibility', 'off' );

      legend('off');

      title([ titleprefix ' - Tone Power (' thisbandtitle ')' ...
        trialtitlesuffix ]);
      xlabel('Relative Tone Power');
      ylabel('Channel');

      set( gca, 'YTick', 1:chancount, 'YTickLabel', chantitles );

      saveas( thisfig, [ fileprefix '-chantones-' thisbandlabel ...
        triallabelsuffix '.png' ] );
    end

  end


  % Render heatmaps.
  % Data is indexed by (channel,band), and plotted as (y,x), which is fine.

  thispower = bandpower(:,:,tidx);
  thistone = tonepower(:,:,tidx);

  if want_powerheat
    clf('reset');
    thisfig.Position = newpos;
    colormap(thisfig, colmap);

    nlPlot_axesPlotSurface2D( gca, thispower, ...
      bandtitles, chantitles, [], [], ...
      'linear', 'linear', 'linear', ...
      'Band', 'Channel', ...
      [ titleprefix ' - Channel Power' trialtitlesuffix ] );

    clim(bandpowerrange);

    thiscol = colorbar;
    thiscol.Label.String = 'In-Band Power';

    saveas( thisfig, [ fileprefix '-chanpowerheat' triallabelsuffix '.png' ] );
  end

  if want_toneheat
    clf('reset');
    thisfig.Position = newpos;
    colormap(thisfig, colmap);

    nlPlot_axesPlotSurface2D( gca, thistone, ...
      bandtitles, chantitles, [], [], ...
      'linear', 'linear', 'linear', ...
      'Band', 'Channel', ...
      [ titleprefix ' - Tone Power' trialtitlesuffix ] );

    clim(tonepowerrange);

    thiscol = colorbar;
    thiscol.Label.String = 'Tone Power';

    saveas( thisfig, [ fileprefix '-chantonesheat' triallabelsuffix '.png' ] );
  end

end


% Restore original figure geometry.
thisfig.Position = oldpos;

% Dispose of the scratch figure.
close(thisfig);



% Done.
end


%
% This is the end of the file.
