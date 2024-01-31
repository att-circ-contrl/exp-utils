function [ maplabelsraw maplabelscooked ] = ...
  euMeta_getLabelChannelMap_OEv5( mapdir, datadir )

% function [ maplabelsraw maplabelscooked ] = ...
%   euMeta_getLabelChannelMap_OEv5( mapdir, datadir )
%
% This function loads an Open Ephys channel map, loads a saved dataset's
% header, and translates the numeric channel map into a label-based channel
% map.
%
% This is a wrapper for "euMeta_getOpenEphysChannelMap_v5",
% "nlIO_readFolderMetadata", and "nlFT_getLabelChannelMapFromNumbers".
%
% If a channel map couldn't be built, empty cell arrays are returned.
%
%
% "mapdir" is the folder to search for channel map files (including saved
%   Open Ephys v5 configuration files).
% "datadir" is the folder to search for Open Ephys datasets.
%
% "maplabelsraw" is a cell array containing raw channel names that correspond
%   to the names in "maplabelscooked".
% "maplabelscooked" is a cell array containing cooked channel names that
%   correspond to the names in "maplabelsraw".


% Initialize.
maplabelsraw = {};
maplabelscooked = {};


% Try to fetch the channel mapping and the Open Ephys dataset's header.
% NOTE - This returns the first map found, if any. If there are multiple
% channel maps or configuration files, it might use the wrong one.

chanmap = euMeta_getOpenEphysChannelMap_v5(mapdir);

[ isok datameta ] = ...
  nlIO_readFolderMetadata( struct([]), 'datafolder', datadir, 'openephys' );


% Proceed if we have data.

if isok && (~isempty(chanmap))
  oenative = datameta.folders.datafolder.nativeorder;
  nativelabels = {};

  for lidx = 1:length(oenative)
    nativelabels{lidx} = ...
      nlFT_makeFTName( oenative(lidx).bank, oenative(lidx).channel );
  end

  [ maplabelsraw maplabelscooked ] = ...
    nlFT_getLabelChannelMapFromNumbers( chanmap.oldchan, ...
      nativelabels, nativelabels );
end


% Done.

end


%
% This is the end of the file.
