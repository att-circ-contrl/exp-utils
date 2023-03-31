function foldermeta = euHLev_getAllMetadata_OpenEv5(thisfolder)

% function foldermeta = euHLev_getAllMetadata_OpenEv5(thisfolder)
%
% This function processes a folder that contains a single structure.oebin
% file, and calls helper functions to return all relevant metadata
% (field trip information, channel list and channel map, open ephys signal
% chain metadata, etc).
%
% "thisfolder" is the name of the folder that contains structure.oebin, as
%   returned by euUtil_getExperimentFolders().
%
% "foldermeta" is a structure with contents described in RAWFOLDERMETA.txt.


foldermeta = struct( 'folder', thisfolder, 'type', 'openephys' );


% Get Field Trip information.

[ header_ft, chans_ephys, chans_digital, map_raw, map_cooked ] = ...
  euHLev_getOpenEHeaderChannels( '', thisfolder );

foldermeta.header_ft = header_ft;
foldermeta.chans_an = chans_ephys;
foldermeta.chans_dig = chans_digital;
foldermeta.chanmap_raw = map_raw;
foldermeta.chanmap_cooked = map_cooked;


% Get Open Ephys information.

settingsfile = nlOpenE_getSettingsFileFromDataFolder_v5(thisfolder);

% NOTE - Bulletproof this.
settings_oe = struct([]);
if isempty(settingsfile)
  disp([ '###  Can''t find settings file for folder "' thisfolder '".' ]);
elseif ~isfile(settingsfile)
  disp([ '###  Can''t open "' settingsfile '".' ]);
elseif ~exist('readstruct')
  disp('###  Can''t read "settings.xml"; needs R2020b or later.');
else
  settings_oe = readstruct(settingsfile, 'FileType', 'xml');
end

foldermeta.settings = settings_oe;

foldermeta.oebufinfo = nlOpenE_parseConfigAudioBufferInfo_v5(settings_oe);
foldermeta.oesigchain = nlOpenE_parseConfigProcessorsXML_v5(settings_oe);


% Done.
end


%
% This is the end of the file.
