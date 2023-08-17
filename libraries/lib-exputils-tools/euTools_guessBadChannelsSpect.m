function [ actualconfig chanlabels changoodvec ...
  spectpower tonepower pcacoords chanclusters ] = ...
  euTools_guessBadChannelsSpect( checkfolder, checkchans, checkconfig )

% function [ checkconfig chanlabels changoodvec ...
%   spectpower tonepower pcacoords chanclusters ] = ...
%   euTools_guessBadChannelsSpect( checkfolder, checkchans, oldconfig )
%
% This attempts to identify bad channels within ephys data by looking for
% channels with abnormal spectra compared to the group as a whole.
%
% "checkfolder" is the folder to read ephys data from (via Field Trip hooks).
% "checkchans" is a cell array containing the names of channels to read.
% "checkconfig" is a structure with zero or more of the following fields.
%   Missing fields are filled with default values:
%   "wantprogress" is true to display a progress indicator while reading.
%   "freqbinedges" is a vector containing bin edges for binning frequency.
%   "pcadims" is the number of principal components to extract when
%     performing dimensionality reduction for clustering.
%
% "actualconfig" is a copy of "checkconfig" with missing values filled in.
% "chanlabels" is a cell array containing the names of the channels that
%   were actually read.
% "changoodvec" is a boolean vector of the same size as "chanlabels"
%   indicating whether or not a given channel was "good".
% "spectpower" is a nChans x nBands matrix containing the total power in
%   each spectral bin for each channel.
% "tonepower" is a nChans x nBands matrix containing the ratio of the maximum
%   spectral power to the median spectral power in each spectral bin for each
%   channel. This is the height of pure tones over the noise floor.
% "pcacoords" is a nChans x nComponents matrix containing the coordinates of
%   each channel in PCA space (dimensionally reduced space).
% "chanclusters" is a vector of the same size as "chanlabels" containing
%   cluster numbers for each channel. Clustering is performed in PCA space,
%   and the number of clusters is chosen by black magic.


% FIXME - NYI.
actualconfig = checkconfig;
chanlabels = {};
changoodvec = logical([]);
spectpower = [];
tonepower = [];
pcacoords = [];
chanclusters = {};


% Done.
end


%
% This is the end of the file.
