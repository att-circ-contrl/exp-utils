function chanmap = euMeta_getOpenEphysChannelMap_v5( inputfolder )

% function chanmap = euMeta_getOpenEphysChannelMap_v5( inputfolder )
%
% This searches the specified tree looking for Open Ephys configuration
% files and channel mapping files (anything with "config" or "mapping" in
% the filename). Channel maps are extracted, and the first map found is
% returned. If no maps are found, an empty structure array is returned.
%
% NOTE - This gives priority to channel map files with the word 'correct'
% in their filename or path, per Louie and Charlie's convention.
%
% This is a wrapper for "euMeta_getOpenEphysConfigFiles",
% "nlOpenE_parseChannelMapJSON_v5", and "nlOpenE_parseChannelMapXML_v5".
%
% "inputfolder" is the top-level folder to search.
%
% "chanmap" is a structure with the following fields:
%   "oldchan" is a vector indexed by new channel number containing the old
%     channel number that maps to each new location, or NaN if none does.
%   "oldref" is a vector indexed by new channel number containing the old
%     channel number to be used as a reference for each new location, or
%     NaN if unspecified.
%   "isenabled" is a vector of boolean values indexed by new channel number
%     indicating which new channels are enabled.


% Initialize output.
chanmap = struct([]);


% Get filenames.
[ configfiles mapfiles ] = euMeta_getOpenEphysConfigFiles(inputfolder);

% Keep a record of the file that we used, for debugging purposes.
chosenfile = '';


% Our first choice is to use a JSON file.

for fidx = 1:length(mapfiles)
  thisfile = mapfiles{fidx};
  % Give priority to files with "correct" in the name.
  if isempty(chanmap) || contains(thisfile, 'correct')
    json_raw = fileread(thisfile);
    json_struct = jsondecode(json_raw);
    json_map = nlOpenE_parseChannelMapJSON_v5(json_struct);

    if ~isempty(json_map)
      chanmap = json_map(1);
      chosenfile = thisfile;
    end
  end
end


% Our second choice is to use an XML file.

have_readstruct = exist('readstruct');
if isempty(chanmap) && (~have_readstruct)
  disp('### Can''t translate Open Ephys config XML; needs R2020b or later.');
end

for fidx = 1:length(configfiles)
  thisfile = configfiles{fidx};
  % Give priority to files with "correct" in the name.
  if have_readstruct && ( isempty(chanmap) || contains(thisfile, 'correct') )
    xml_struct = readstruct(thisfile, 'FileType', 'xml');

    if ~isempty(xml_struct)
      xml_map = nlOpenE_parseChannelMapXML_v5(xml_struct);
      if ~isempty(xml_map)
        chanmap = xml_map(1);
        chosenfile = thisfile;
      end
    end
  end
end

% FIXME - Diagnostics.
%disp([ 'xxx  Used OE channel map from:  ' chosenfile ]);

% Done.

end


%
% This is the end of the file.
