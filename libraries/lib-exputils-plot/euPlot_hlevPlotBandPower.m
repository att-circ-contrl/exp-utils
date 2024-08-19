function euPlot_hlevPlotBandPower( bandpower, tonepower, normmethod, ...
  bandlabels, chanlabels, triallabels, bandpowerrange, tonepowerrange, ...
  plotswanted, titleprefix, fileprefix, markedchans )

% function euPlot_hlevPlotBandPower( bandpower, tonepower, normmethod, ...
%   bandlabels, chanlabels, triallabels, bandpowerrange, tonepowerrange, ...
%   plotswanted, titleprefix, fileprefix, markedchans )
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
% If plot ranges aren't specified, reasonable defaults are used.
%
% For most plots, data is z-scored across channels; for specific types of
% plot (noted below), z-scoring is across bands instead, or across bands
% followed by across channels. Z-scoring may be disabled by selecting a
% normalization method of 'none'.
%
% "bandpower" is a nChans x nBands x nTrials matrix containing per-band
%   total power for each channel, band, and trial.
% "tonepower" is a nChans x nBands x nTrials matrix containing the ratio
%   of maximum component power to median component power of in-band
%   frequencies.
% "normmethod" is 'zscore', 'median', 'twosided', or 'none', indicating
%   which normalization method to use (per nlProc_normalizeAcrossChannels).
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
%   'powerheatband' - As 'powerheatmap', but z-scored across bands.
%   'toneheatband' - As 'toneheatmap', but z-scored across bands.
%   'powerheatdual' - As 'powerheatmap' but z-scored across band, then channel.
%   'toneheatdual' - As 'toneheatmap' but z-scored across band, then channel.
% "titleprefix" is a prefix used when building plot titles.
% "fileprefix" is a prefix used when building output filenames.
% "markedchans" is an optional argument. If present, it's a cell array of
%   character vectors, or a vector with channel numbers. Channels in
%   "chanlabels" that are present in this list have a marker prepended to
%   them.
%
% No return value.


% Get metadata.

chancount = size(bandpower,1);
bandcount = size(bandpower,2);
trialcount = size(bandpower,3);


% Set magic ranges.

if isempty(bandpowerrange)
  if strcmp('none', normmethod)
    bandpowerrange = 'auto';
  else
    % +/- 3 sigma, with midpoint at the mean.
    bandpowerrange = [ -3 3 ];
  end
end

if isempty(tonepowerrange)
  if strcmp('none', normmethod)
    tonepowerrange = 'auto';
  else
    % Midpoint at +1 sigma, wide enough range to catch extreme values.
    % Tones from noise tend to be really strong.
    tonepowerrange = [ -4 6 ];
  end
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



% NOTE - There is no guarantee that channel labels are sorted!
% That's the caller's problem.



% Deal with the optional list of channel labels to mark.

if ~exist('markedchans', 'var')
  markedchans = {};
end

if ~iscell(markedchans)
  markedchans = nlUtil_sprintfCellArray('CH %03d', markedchans);
end

% Convert raw FT labels to the plotting label/title format.
[ scratch markedchans ] = euUtil_makeSafeStringArray( markedchans );

for cidx = 1:length(chanlabels)
  thischan = chantitles{cidx};
  if ismember(thischan, markedchans)
    chantitles{cidx} = [ 'x ' thischan ];
  end
end



%
% If we have multiple trials, make an additional "average" trial.

if trialcount > 1
  scratch = mean(bandpower, 3);
  bandpower(:,:,trialcount+1) = scratch;

  scratch = mean(tonepower, 3);
  tonepower(:,:,trialcount+1) = scratch;

  triallabels{trialcount+1} = 'avg';
  trialtitles{trialcount+1} = 'Average';

  trialcount = trialcount + 1;
end



%
% Normalize data, if requested.

bandpower_nb = bandpower;
tonepower_nb = tonepower;

bandpower_dual = bandpower;
tonepower_dual = tonepower;

if ~strcmp('none', normmethod)
  bandpower = nlProc_normalizeAcrossChannels( bandpower, normmethod );
  tonepower = nlProc_normalizeAcrossChannels( tonepower, normmethod );

  bandpower_nb = nlProc_normalizeAcrossBandTime( bandpower_nb, normmethod );
  tonepower_nb = nlProc_normalizeAcrossBandTime( tonepower_nb, normmethod );

  % Normalize a second time. The effect is to compare differences in the
  % shape of the spectrum between channels, rather than absolute amplitudes.

  bandpower_dual = nlProc_normalizeAcrossChannels( bandpower_nb, normmethod );
  tonepower_dual = nlProc_normalizeAcrossChannels( tonepower_nb, normmethod );
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

want_powerheatband = ismember('powerheatband', plotswanted);
want_toneheatband = ismember('toneheatband', plotswanted);

want_powerheatdual= ismember('powerheatdual', plotswanted);
want_toneheatdual = ismember('toneheatdual', plotswanted);


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

  % We have six different cases to plot. Instead of cutting and pasting,
  % use a helper function.


  % Z-scored across channels.

  if want_powerheat
    euPlot_hlevPlotBandPower_helper( ...
      thisfig, newpos, colmap, bandtitles, chantitles, ...
      bandpower(:,:,tidx), 'In-Band Power', bandpowerrange, ...
      [ titleprefix ' - Channel Power' trialtitlesuffix ], ...
      [ fileprefix '-chanpowerheat' triallabelsuffix '.png' ] );
  end

  if want_toneheat
    euPlot_hlevPlotBandPower_helper( ...
      thisfig, newpos, colmap, bandtitles, chantitles, ...
      tonepower(:,:,tidx), 'Tone Power', tonepowerrange, ...
      [ titleprefix ' - Tone Power' trialtitlesuffix ], ...
      [ fileprefix '-chantonesheat' triallabelsuffix '.png' ] );
  end


  % Z-scored across bands.

  if want_powerheatband
    euPlot_hlevPlotBandPower_helper( ...
      thisfig, newpos, colmap, bandtitles, chantitles, ...
      bandpower_nb(:,:,tidx), 'In-Band Power', bandpowerrange, ...
      [ titleprefix ' - Channel Power' trialtitlesuffix ], ...
      [ fileprefix '-chanpowerheat2' triallabelsuffix '.png' ] );
  end

  if want_toneheatband
    euPlot_hlevPlotBandPower_helper( ...
      thisfig, newpos, colmap, bandtitles, chantitles, ...
      tonepower_nb(:,:,tidx), 'Tone Power', tonepowerrange, ...
      [ titleprefix ' - Tone Power' trialtitlesuffix ], ...
      [ fileprefix '-chantonesheat2' triallabelsuffix '.png' ] );
  end


  % Z-scored across bands and then channels.
  % FIXME - Double the colour bar scale for these plots.

  if want_powerheatdual
    euPlot_hlevPlotBandPower_helper( ...
      thisfig, newpos, colmap, bandtitles, chantitles, ...
      bandpower_dual(:,:,tidx), 'In-Band Power', bandpowerrange * 2, ...
      [ titleprefix ' - Channel Power' trialtitlesuffix ], ...
      [ fileprefix '-chanpowerheat3' triallabelsuffix '.png' ] );
  end

  if want_toneheatdual
    euPlot_hlevPlotBandPower_helper( ...
      thisfig, newpos, colmap, bandtitles, chantitles, ...
      tonepower_dual(:,:,tidx), 'Tone Power', tonepowerrange * 2, ...
      [ titleprefix ' - Tone Power' trialtitlesuffix ], ...
      [ fileprefix '-chantonesheat3' triallabelsuffix '.png' ] );
  end

end


% Restore original figure geometry.
thisfig.Position = oldpos;

% Dispose of the scratch figure.
close(thisfig);



% Done.
end



%
% Helper Functions


% Heatmap plotting helper.

function euPlot_hlevPlotBandPower_helper( ...
  thisfig, newpos, colmap, bandtitles, chantitles, ...
  datamatrix, coltitle, colrange, figtitle, outfile )

  clf('reset');
  thisfig.Position = newpos;
  colormap(thisfig, colmap);

  nlPlot_axesPlotSurface2D( gca, datamatrix, ...
    bandtitles, chantitles, [], [], ...
    'linear', 'linear', 'linear', ...
    'Band', 'Channel', figtitle );

  clim(colrange);

  thiscol = colorbar;
  thiscol.Label.String = coltitle;

  saveas( thisfig, outfile );
end



%
% This is the end of the file.
