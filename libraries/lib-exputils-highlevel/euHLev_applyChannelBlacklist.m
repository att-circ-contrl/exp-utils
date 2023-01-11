function keepmask = ...
  euHLev_applyChannelBlacklist( chanlist, classfile, userconfig )

% function keepmask = ...
%   euHLev_applyChannelBlacklist( chanlist, classfile, userconfig )
%
% This reads a file containing hand-annotated channel classes and applies
% a blacklist or whitelist to identify channels that should be kept. The
% supplied channel list is masked using the resulting rules.
%
% Only channels mentioned in the file are kept. If no such file exists,
% all channels are kept.
%
% "chanlist" is a cell array containing the list of channel names to filter.
% "classfile" is the name of a CSV file containing hand-annotated channel
%   types, per euUtil_readChannelClasses().
% "userconfig" is an optional argument containing a structure with key/value
%   pairs to override. Relevant fields (keys) are:
%   "chancolumn" is the name of the column containing channel names.
%   "typecolumn" is the name of the column to read annotated types from.
%   "whitelist" is a cell array containing acceptable type values.
%   "blacklist" is a cell array containing unacceptable type values.
%
% "keepmask" is a vector of boolean values that's true for entries in
%   "chanlist" that should be kept.
%
% If a non-empty whitelist is supplied, it's used. Otherwise the blacklist
% is used.


% Get the configuration.

config = euHLev_getDefaultChannelBlacklistConfig();

if exist('userconfig', 'var')
  flist = fieldnames(userconfig);
  for fidx = 1:length(flist)
    config.(flist{fidx}) = userconfig.(flist{fidx});
  end
end


% For now, default to "keep all".
keepmask = true(size(chanlist));


% If the file exists, build a mask based on it.

if (~isempty(classfile)) && isfile(classfile)

  [ filechans, fileclasses ] = euUtil_readChannelClasses( ...
    classfile, config.chancolumn, config.typecolumn );

  % Convert channel numbers into channel labels.
  if ~iscell(filechans)
    % FIXME - Assume the default Open Ephys bank name.
    filechans = nlFT_makeLabelsFromNumbers( 'CH', filechans );
  end


  % Get a list of channels to keep.
  % We're only keeping channels mentioned in the file.
  % Use a whitelist if we have one; blacklist otherwise.

  scratchmask = false(size(filechans));

  if ~isempty(config.whitelist)
    for lidx = 1:length(config.whitelist)
      scratchmask = scratchmask | ...
        strcmp( config.whitelist{lidx}, fileclasses );
    end
  else
    for lidx = 1:length(config.blacklist)
      scratchmask = scratchmask | ...
        strcmp( config.blacklist{lidx}, fileclasses );
    end

    scratchmask = ~scratchmask;
  end

  filechans = filechans(scratchmask);


  % Keep only the selected channels.

  keepmask = false(size(chanlist));

  for lidx = 1:length(filechans)
    keepmask = keepmask | strcmp( filechans{lidx}, chanlist );
  end

end


% Done.

end


%
% This is the end of the file.
