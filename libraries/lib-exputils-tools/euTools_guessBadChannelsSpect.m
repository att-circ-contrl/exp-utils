function [ actualconfig chanlabels changoodvec ...
  spectpower tonepower pcacoords ...
  spectclusters toneclusters pcaclusters ] = ...
  euTools_guessBadChannelsSpect( checkfolder, checkchans, config )

% function [ actualconfig chanlabels changoodvec ...
%   spectpower tonepower pcacoords ...
%   spectclusters toneclusters pcaclusters ] = ...
%   euTools_guessBadChannelsSpect( checkfolder, checkchans, config )
%
% This attempts to identify bad channels within ephys data by looking for
% channels with abnormal spectra compared to the group as a whole.
%
% "checkfolder" is the folder to read ephys data from (via Field Trip hooks).
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
  config.pca_kmeans_repeats = 300;
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


% NOTE - If FT runs into a problem, it'll throw an exception.
% The caller had better be prepared to catch that.

thisheader = ft_read_header( checkfolder, 'headerformat', 'nlFT_readHeader' );

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
  'headerfile', checkfolder, 'headerformat', 'nlFT_readHeader', ...
  'datafile', checkfolder, 'dataformat', 'nlFT_readDataNative', ...
  'channel', { chanlist }, 'trl', [ firstsamp lastsamp 0 ], ...
  'detrend', 'yes', 'feedback', 'no' );

ephysdata = ft_preprocessing(preproc_config);

% Figure out what channels were actually read.
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



% FIXME - NYI.



% Figure out which channels were "good" and which were "bad".

% FIXME - NYI.

changoodvec = true([ chancount 1 ]);


% Done.
end


%
% This is the end of the file.
