function casemetalist = euHLev_getChrisMetadata( caselist )

% function casemetalist = euHLev_getChrisMetadata( caselist )
%
% This iterates through a list of experiment cases for Chris's tests, and
% extracts signal chain metadata and Open Ephys metadata for each case.
%
% "caselist" is a struct array with the following fields:
%   'folder' is a character array with the top-level save file path.
%   'prefix' is a filename-safe label for per-case filenames.
%   'title' is a plot-safe human-readable per-case label.
%   'setprefix' is a filename-safe label for the set of cases this case
%     belongs to.
%   'settitle' is a plot-safe human-readable title for the set of cases
%     this case belongs to.
%   'settype' is a character array specifying the parser to use for
%     processing this configuration, or '' for the default.
%   'hint' is a structure containing hints for parsing. This may be a
%     structure with no fields or an empty structure array.
%
% "casemetalist" is a cell array with one element per case, containing
%   the metadata structures returned when parsing each case.
%
% FIXME - Metadata for different set types goes here!
% - loop2302xx


casemetalist = {};

for cidx = 1:length(caselist)

  thiscase = caselist(cidx);

  thistype = thiscase.settype;
  thishint = thiscase.hint;


  [ folders_openephys folders_intanrec folders_intanstim folders_unity ] = ...
    euUtil_getExperimentFolders(thiscase.folder);

  thisrawmeta = struct();

  for fidx = 1:length(folders_openephys)

    thisfolder = folders_openephys{fidx};

    % Field Trip information.
    % We just want the header and channel lists, not the channel map.
    [ header_ft, chans_ephys, chans_digital, map_raw, map_cooked ] = ...
      euHLev_getOpenEHeaderChannels( '', thisfolder );

    % Open Ephys signal chain configuration.
    % FIXME - Cheat. The settings file is two levels up from here in v0.5.
    settingsfile = ...
      [ thisfolder filesep '..' filesep '..' filesep 'settings.xml' ];
    settings_oe = struct([]);
    if ~isfile(settingsfile)
      disp([ '###  Can''t open "' settingsfile '".' ]);
    elseif ~exist('readstruct')
      disp('### Can''t read "settings.xml"; needs R2020b or later.');
    else
      settings_oe = readstruct(settingsfile, 'FileType', 'xml');
    end

    % Aggregate this folder's raw metadata.
    thisrawmeta(fidx).folder = thisfolder;
    thisrawmeta(fidx).header = header_ft;
    thisrawmeta(fidx).chans_an = chans_ephys;
    thisrawmeta(fidx).chans_dig = chans_digital;
    thisrawmeta(fidx).settings = settings_oe;
    thisrawmeta(fidx).type = 'openephys';

  end


  % This will return an empty structure if it couldn't figure out the config.

  [ thismeta errmsgs ] = ...
    euChris_parseExperimentConfig( thisrawmeta, thistype, thishint );

  % FIXME - Debugging. Force this to return something even on error.
  if isempty(thismeta)
%    thismeta = struct();
  end

  if ~isempty(thismeta)
    % Debugging - Copy the case information and raw metadata as well.
    thismeta.caseinfo = thiscase;
    thismeta.rawmeta = thisrawmeta;
  end

  if ~isempty(errmsgs)
    disp(errmsgs);
  end

  casemetalist{cidx} = thismeta;

end


% Done.

end


%
% This is the end of the file.
