function [ header chans_ephys chans_digital chanmap_raw chanmap_cooked ] = ...
  euHLev_getOpenEHeaderChannels( configfolder, ephysfolder )

% function [ header chans_ephys chans_digital chanmap_raw chanmap_cooked ] = ...
%   euHLev_getOpenEHeaderChannels( configfolder, ephysfolder )
%
% This fetches the FT header and relevant channel names from the specified
% ephys folder, and also searches the config folder and ephys folder to
% fetch the channel map that was used.
%
% This is a wrapper for various Field Trip and euUtil_ functions.
%
% NOTE - "ephysfolder" can be a cell array ("configfolder" shouldn't be).
% If "ephysfolder" is a cell array, each entry is treated as a folder to be
% checked, and all return values are also per-folder cell arrays.
%
% "configfolder" is the folder to search for the channel map. Empty to skip.
% "ephysfolder" is the folder to search for ephys metadata.
%
% "header" is the Field Trip ephys header.
% "chans_ephys" is a list of channels containing ephys data.
% "chans_digital" is a list of channels containing digital event data.
% "chanmap_raw" is a list of raw ephys channel names to be mapped.
% "chanmap_cooked" is a list of corresponding cooked ephys channel names.


if iscell(ephysfolder)

  % Testing multiple folders. Recurse.

  header = {};
  chans_ephys = {};
  chans_digital = {};
  chanmap_raw = {};
  chanmap_cooked = {};

  for fidx = 1:length(ephysfolder)
    [ thisheader thisephys thisdigital thisraw thiscooked ] = ...
      euHLev_getOpenEHeaderChannels( configfolder, ephysfolder{fidx} );

    header{fidx} = thisheader;
    chans_ephys{fidx} = thisephys;
    chans_digital{fidx} = thisdigital;
    chanmap_raw{fidx} = thisraw;
    chanmap_cooked{fidx} = thiscooked;
  end

else

  % Testing a single folder.

  header = ft_read_header( ephysfolder, 'headerformat', 'nlFT_readHeader' );

  [ pat_ephys pat_digital pat_stimcurrent pat_stimflags ] = ...
    euFT_getChannelNamePatterns();

  chans_ephys = ft_channelselection( pat_ephys, header.label, {} );
  chans_digital = ft_channelselection( pat_digital, header.label, {} );

  chanmap_raw = {};
  chanmap_cooked = {};
  if ~isempty(configfolder)
    [ chanmap_raw chanmap_cooked ] = ...
      euUtil_getLabelChannelMap_OEv5( configfolder, ephysfolder );
  end

end


% Done.
end


%
% This is the end of the file.
