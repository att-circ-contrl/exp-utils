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


  % Progress banner.
  disp([ '.. Reading "' thiscase.folder '".' ]);


  [ folders_openephys folders_intanrec folders_intanstim folders_unity ] = ...
    euUtil_getExperimentFolders(thiscase.folder);

  thisrawmetalist = {};

  for fidx = 1:length(folders_openephys)
    thisfolder = folders_openephys{fidx};
    thisrawmetalist{fidx} = euHLev_getAllMetadata_OpenEv5(thisfolder);
  end


  % This will return an empty structure if it couldn't figure out the config.

  [ thismeta errmsgs ] = ...
    euChris_parseExperimentConfig( thisrawmetalist, thistype, thishint );

  % FIXME - Debugging. Force this to return something even on error.
  if isempty(thismeta)
%    thismeta = struct();
  end

  if ~isempty(thismeta)
    % Debugging - Copy the case information as well.
    % Raw metadata is already saved by parseExperimentConfig().
    thismeta.caseinfo = thiscase;
  end

  if ~isempty(errmsgs)
    disp( euUtil_concatenateCellStrings( errmsgs ) );
  end

  casemetalist{cidx} = thismeta;

end


% Progress banner.
disp('.. Finished reading metadata for all experiments.');


% Done.

end


%
% This is the end of the file.
