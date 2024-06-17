function [ maplabelsraw maplabelscooked ] = ...
  euMeta_getLabelChannelMap_OEv5( mapdir, datadir, source )

% function [ maplabelsraw maplabelscooked ] = ...
%   euMeta_getLabelChannelMap_OEv5( mapdir, datadir, source )
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
% "source" is 'fromlabels' or 'fromsequence'. Specifying 'fromlabels' uses
%   the channel numbers stored in the "native order" table in the Open
%   Ephys metadata structure. Specifying 'fromsequence' ignores the metadata
%   channel numbers and uses the order of occurrence in the metadata list as
%   the channel number.
%
% "maplabelsraw" is a cell array containing raw channel names that correspond
%   to the names in "maplabelscooked".
% "maplabelscooked" is a cell array containing cooked channel names that
%   correspond to the names in "maplabelsraw".


% Initialize.
maplabelsraw = {};
maplabelscooked = {};


% FIXME - Backwards compatibility support.
if ~exist('source', 'var')
  source = 'fromlabels';
  disp([ '###  [euMeta_getLabelChannelMap_OEv5]  Source not specified.' ...
    ' Using "fromlabels".' ]);
end


% Try to fetch the channel mapping and the Open Ephys dataset's header.
% NOTE - This returns the first map found, if any. If there are multiple
% channel maps or configuration files, it might use the wrong one.

chanmap = euMeta_getOpenEphysChannelMap_v5(mapdir);

[ isok datameta ] = ...
  nlIO_readFolderMetadata( struct([]), 'datafolder', datadir, 'openephys' );


% Proceed if we have data.

if isok && (~isempty(chanmap))

  % Get "native channel order" metadata.

  oenative = datameta.folders.datafolder.nativeorder;

  nativebanks = { oenative.bank };
  nativechans = [ oenative.channel ];


  % Build sequence-based channel numbers.
  % We need to do this separately for each bank.

  nativeseqnums = nan(size(nativechans));

  banklist = unique(nativebanks);
  for bidx = 1:length(banklist)
    thismask = strcmp( nativebanks, banklist{bidx} );
    thiscount = sum(thismask);
    nativeseqnums(thismask) = 1:thiscount;
  end


  % Build the list of native labels, using whichever method was requested.
  nativelabels = {};

  for lidx = 1:length(oenative)
    if strcmp(source, 'fromsequence')
      nativelabels{lidx} = ...
        nlFT_makeFTName( nativebanks{lidx}, nativeseqnums(lidx) );
    else
      % Default is 'fromlabels'.
      nativelabels{lidx} = ...
        nlFT_makeFTName( nativebanks{lidx}, nativechans(lidx) );
    end
  end


  % Build the label-based channel map.
  [ maplabelsraw maplabelscooked ] = ...
    nlFT_getLabelChannelMapFromNumbers( chanmap.oldchan, ...
      nativelabels, nativelabels );
end


% Done.

end


%
% This is the end of the file.
