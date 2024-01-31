function [ foldername foldersizes ] = ...
  euMeta_pickBiggestEphysfolder( folderlist )

% function [ foldername foldersizes ] = ...
%   euMeta_pickBiggestEphysfolder( folderlist )
%
% This reads Field Trip headers for each of a list of ephys folders and
% picks the one that has the most data (nTrials * nSamples).
%
% "folderlist" is a cell array with a list of folders to test.
%
% "foldername" is the folder that had the most data.
% "foldersizes" is a vector with the same size as "folderlist" containing
%   the size (nTrials * nSamples) of each folder.


foldername = '';
foldersizes = zeros(size(folderlist));


for fidx = 1:length(folderlist)
  thishdr = ...
    ft_read_header( folderlist{fidx}, 'headerformat', 'nlFT_readHeader' );

  foldersizes(fidx) = thishdr.nSamples * thishdr.nTrials;
end


if ~isempty(foldersizes)
  biggest = max(foldersizes);

  pickidx = find(foldersizes == biggest);
  pickidx = pickidx(1);

  foldername = folderlist{pickidx};
end


% Done.
end


%
% This is the end of the file.
