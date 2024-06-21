function [ actualconfig chanlabels changoodvec ...
  spectpower tonepower pcacoords ...
  spectclusters toneclusters pcaclusters ] = ...
  euTools_guessBadChannelsSpect( checkdata, checkchans, config )

% function [ actualconfig chanlabels changoodvec ...
%   spectpower tonepower pcacoords ...
%   spectclusters toneclusters pcaclusters ] = ...
%   euTools_guessBadChannelsSpect( checkdata, checkchans, config )
%
% This attempts to identify bad channels within ephys data by looking for
% channels with abnormal spectra compared to the group as a whole.
%
% "checkdata" is either a ft_datatype_raw structure with Field Trip ephys
%   data, or a character vector specifying the folder to read ephys data
%   from (via Field Trip hooks).
% "checkchans" is a cell array containing the names of channels to read.
%   This can contain ft_channelselection patterns. If this is empty, all
%   channels are read.
% "config" is a structure with zero or more of the following fields.
%   Missing fields are filled with default values:
%   "timestart" is the starting time to read from, in seconds.
%   "duration" is the number of seconds of data to read.
%   "freqbinedges" is a vector containing bin edges for binning frequency.
%   "pcadims" is the number of principal components to extract when
%     performing dimensionality reduction for clustering.
%   "raw_clustcounts" is a vector containing cluster counts to test when
%     clustering based on individual band or tone powers.
%   "pca_clustcounts" is a vector containing cluster counts to test when
%     clustering the PCA output.
%   "raw_kmeans_repeats" is the number of times to run k-means (the
%     "Replicates" parameter) for band and tone power clustering.
%   "pca_kmeans_repeats" is the number of times to run k-means (the
%     "Replicates" parameter) for PCA output clustering.
%   "pca_reject_threshold" is the nlProc_getOutliers() threshold to use
%     for detecting bad channels. This is a multiple of the
%     median-to-quartile distance; the default is 3.0.
%
% "actualconfig" is a copy of "config" with missing values filled in.
% "chanlabels" is a nChans x 1 cell array containing the names of the
%   channels that were actually read.
% "changoodvec" is a nChans x 1 boolean vector indicating whether each
%   channel was "good".
% "spectpower" is a nChans x nBands matrix containing the total power in
%   each spectral bin for each channel.
% "tonepower" is a nChans x nBands matrix containing the ratio of the maximum
%   spectral power to the median spectral power in each spectral bin for each
%   channel. This is the height of pure tones over the noise floor.
% "pcacoords" is a nChans x nComponents matrix containing the coordinates of
%   each channel in PCA space (dimensionally reduced space).
% "spectclusters" is a nChans x nBands matrix containing cluster numbers for
%   each channel after performing k-means clustering of spectral power for
%   channels within each band.
% "toneclusters" is a nChans x nBands matrix containing cluster numbers for
%   each channel after performing k-means clustering of tone power ratio for
%   channels within each band.
% "pcaclusters" is a nChans x 1 vector containing cluster numbers for each
%   channel after performing k-means clustering in PCA space.


%
% Fill in missing config fields.

if ~isfield(config, 'timestart')
  config.timestart = 20;
end

if ~isfield(config, 'duration')
  config.duration = 10;
end

if ~isfield(config, 'freqbinedges')
  % If these are wider than an octave, LFP pink or red noise means that
  % low frequencies will dominate.
  % At higher frequencies, pretend we have a white noise floor.

  % LFP bin midpoints are 10, 20, 40, and 80 Hz.
  config.freqbinedges = [ 7 14 30 60 120 240 500 1000 3000 ];
end
config.freqbinedges = sort(config.freqbinedges);
bincount = length(config.freqbinedges) - 1;

if ~isfield(config, 'pcadims')
  config.pcadims = 2;
end

if ~isfield(config, 'raw_clustcounts')
  config.raw_clustcounts = 2:4;
end

if ~isfield(config, 'pca_clustcounts')
  config.pca_clustcounts = 2:6;
end

if ~isfield(config, 'raw_kmeans_repeats')
  config.raw_kmeans_repeats = 30;
end

if ~isfield(config, 'pca_kmeans_repeats')
  config.pca_kmeans_repeats = 100;
end

if ~isfield(config, 'pca_reject_threshold')
  config.pca_reject_threshold = 3.0;
end



%
% Copy configuration and initialize with sane output.

actualconfig = config;
chanlabels = {};
changoodvec = logical([]);
spectpower = [];
tonepower = [];
pcacoords = [];
spectclusters = [];
toneclusters = [];
pcaclusters = [];



%
% Read the input data.


if ischar(checkdata)

  % We were given a folder to read data from; do so.

  % NOTE - If FT runs into a problem, it'll throw an exception.
  % The caller had better be prepared to catch that.

  thisheader = ft_read_header( checkdata, 'headerformat', 'nlFT_readHeader' );

  chancount = thisheader.nChans;
  sampcount = thisheader.nSamples;
  samprate = thisheader.Fs;

  firstsamp = round(config.timestart * samprate);
  lastsamp = firstsamp + round(config.duration * samprate);

  % Clamp to the actual range.
  lastsamp = min(lastsamp, sampcount);
  firstsamp = min(firstsamp, lastsamp);

  if isempty(checkchans)
    chanlist = thisheader.label;
  else
    chanlist = ft_channelselection( checkchans, thisheader.label, {} );
  end

  % We need at least one channel to proceed.
  if isempty(chanlist)
    disp(sprintf( [ '### [euTools_guessBadChannelsSpect]  ' ...
      'Selected 0 channels (of %d in data)!' ], length(thisheader.label) ));
    % Bail out.
    return;
  end

  preproc_config = struct( ...
    'headerfile', checkdata, 'headerformat', 'nlFT_readHeader', ...
    'datafile', checkdata, 'dataformat', 'nlFT_readDataNative', ...
    'channel', { chanlist }, 'trl', [ firstsamp lastsamp 0 ], ...
    'detrend', 'yes', 'feedback', 'no' );

  ephysdata = ft_preprocessing(preproc_config);

  % Figure out what channels were actually read.
  chanlabels = ephysdata.label;
  chancount = length(chanlabels);

else

  % We were passed a Field Trip data structure that was already read.

  ephysdata = checkdata;

  % If we have no trials, bail out.
  if length(ephysdata.trial) < 1
    disp('### [euTools_guessBadChannelsSpect]  No trials in dataset!');
    return;
  end


  % Select only the desired channels.

  if isempty(checkchans)
    chanlist = ephysdata.label;
  else
    chanlist = ft_channelselection( checkchans, ephysdata.label, {} );
  end

  % We need at least one channel to proceed.
  if isempty(chanlist)
    disp(sprintf( [ '### [euTools_guessBadChannelsSpect]  ' ...
      'Selected 0 channels (of %d in data)!' ], length(ephysdata.label) ));
    % Bail out.
    return;
  end

  % Do the selection. Detrend while we're here.
  preproc_config = struct( ...
    'channel', { chanlist }, 'detrend', 'yes', 'feedback', 'no' );
  ephysdata = ft_preprocessing(preproc_config, ephysdata);


  % If we have multiple trials, concatenate them.
  if length(ephysdata.trial) > 1

    oldtimes = ephysdata.time;
    oldtrials = ephysdata.trial;
    newtime = [];
    newtrial = [];

    sampcount = length(ephysdata.time);
    chancount = length(ephysdata.label);

    for tidx = 1:length(oldtrials)
      thistime = oldtimes{tidx};
      thistrial = oldtrials{tidx};

      newtime = [ newtime thistime ];

      % NOTE - Apply a roll-off window to reduce edge effects.
      % We've already detrended.
      % Taper on 10% of the total window (5% per side).
      thiswin = tukeywin(sampcount, 0.1);
      for cidx = 1:chancount
        thistrial(cidx,:) = thistrial(cidx,:) .* thiswin;
      end

      newtrial = [ newtrial thistrial ];
    end

    ephysdata.time = { newtime };
    ephysdata.trial = { newtrial };

  end

end


% Get metadata from the Field Trip data structure.
% We should have a single trial.

samprate = round( 1 / median(diff( ephysdata.time{1} )) );
sampcount = length(ephysdata.time{1});

chanlabels = ephysdata.label;
chancount = length(chanlabels);

% This should already be a column, but make sure.
if ~iscolumn(chanlabels)
  chanlabels = transpose(chanlabels);
end



%
% Get total band power and relative tone power for each bin.

% Spectpower and tonepower are nChans x nBins.

for cidx = 1:chancount

  thiswave = ephysdata.trial{1}(cidx,:);

  % Just in case of off-by-one rounding issues.
  sampcount = length(thiswave);
  duration = sampcount / samprate;

  wavespect = fft(thiswave);
  wavespect = abs(wavespect);
  wavespect = wavespect .* wavespect;

  % For a real-valued input signal, F(-w) is conj(F(w)), so the power
  % spectrum is symmetrical. We can ignore the above-Nyquist half.
  freqlist = 0:(sampcount-1);
  freqlist = freqlist / duration;

  for bidx = 1:bincount

    minfreq = config.freqbinedges(bidx);
    maxfreq = config.freqbinedges(bidx+1);
    binrange = (freqlist >= minfreq) & (freqlist <= maxfreq);

    % Initialize to values that it's safe to take the logarithm of.
    thispower = 1;
    thistone = 1;

    if ~isempty(binrange)
      thisdata = wavespect(binrange);
      thispower = sum(thisdata);
      thistone = max(thisdata) / median(thisdata);
    end

    spectpower(cidx,bidx) = thispower;
    tonepower(cidx,bidx) = thistone;

  end

end



%
% Do k-means clustering of power per-band.

kvalues = config.raw_clustcounts;
krepeats = config.raw_kmeans_repeats;

for bidx = 1:bincount

  % Total power.

  thisdata = spectpower(:,bidx);

  bestfom = -inf;
  clustlabels = NaN(size(thisdata));

  for kidx = 1:length(kvalues)
    thisclust = kmeans( thisdata, kvalues(kidx), 'Replicates', krepeats );
    thisfom = mean( silhouette(thisdata, thisclust) );

    if thisfom > bestfom
      bestfom = thisfom;
      clustlabels = thisclust;
    end
  end

  spectclusters(1:chancount,bidx) = clustlabels;


  % Relative tone power.

  thisdata = tonepower(:,bidx);

  bestfom = -inf;
  clustlabels = NaN(size(thisdata));

  for kidx = 1:length(kvalues)
    thisclust = kmeans( thisdata, kvalues(kidx), 'Replicates', krepeats );
    thisfom = mean( silhouette(thisdata, thisclust) );

    if thisfom > bestfom
      bestfom = thisfom;
      clustlabels = thisclust;
    end
  end

  toneclusters(1:chancount,bidx) = clustlabels;

end



%
% Do PCA on the total and tone power across bins and cluster that.


% Borg together all of the spectrum and tone information.
% This should be (observations) x (variables). One observation per channel.

rawdata = spectpower;
rawdata(:,(bincount+1):(bincount+bincount)) = tonepower;


% Do PCA with the requested number of basis vectors.
% "pcabasis" contains basis vectors as columns.
% "pcaweights" is nChans x nDims.

pcadims = config.pcadims;
[ pcabasis, pcaweights, ~ ] = pca( rawdata, 'NumComponents', pcadims );

% We're returning the weight matrix as-is.
pcacoords = pcaweights;


% Do k-means clustering.

kvalues = config.pca_clustcounts;
krepeats = config.pca_kmeans_repeats;

bestfom = -inf;
clustlabels = NaN([ chancount 1 ]);

for kidx = 1:length(kvalues)
  thisclust = kmeans( pcacoords, kvalues(kidx), 'Replicates', krepeats );
  thisfom = mean( silhouette(pcacoords, thisclust) );

  if thisfom > bestfom
    bestfom = thisfom;
    clustlabels = thisclust;
  end
end

pcaclusters = clustlabels;



%
%
% Figure out which channels were "good" and which were "bad".

% Do this by projecting on to each PCA axis and looking for outliers.
% This gets consistently decent results for my data.

changoodvec = true([ chancount 1 ]);

outlierperc = [ 25 75 ];
outlierreject = config.pca_reject_threshold;

for pidx = 1:pcadims
  thisvec = pcacoords(:,pidx);
  thisbad = nlProc_getOutliers( thisvec, ...
    min(outlierperc), max(outlierperc), outlierreject, outlierreject );
  changoodvec = changoodvec & (~thisbad);
end


% Done.
end


%
% This is the end of the file.
