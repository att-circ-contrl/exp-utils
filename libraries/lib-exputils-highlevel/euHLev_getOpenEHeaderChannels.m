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
% "configfolder" is the folder to search for the channel map.
% "ephysfolder" is the folder to search for ephys metadata.
%
% "header" is the Field Trip ephys header.
% "chans_ephys" is a list of channels containing ephys data.
% "chans_digital" is a list of channels containing digital event data.
% "chanmap_raw" is a list of raw ephys channel names to be mapped.
% "chanmap_cooked" is a list of corresponding cooked ephys channel names.


header = ft_read_header( ephysfolder, 'headerformat', 'nlFT_readHeader' );

[ pat_ephys pat_digital pat_stimcurrent pat_stimflags ] = ...
  euFT_getChannelNamePatterns();

chans_ephys = ft_channelselection( pat_ephys, header.label, {} );
chans_digital = ft_channelselection( pat_digital, header.label, {} );

[ chanmap_raw chanmap_cooked ] = ...
  euUtil_getLabelChannelMap_OEv5( configfolder, ephysfolder );


% Done.
end


%
% This is the end of the file.
