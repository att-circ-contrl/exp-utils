function config = euHLev_getDefaultChannelBlacklistConfig()

% function config = euHLev_getDefaultChannelBlacklistConfig()
%
% This returns a structure containing default configuration parameters for
% euHLev_applyChannelBlacklist().
%
% "config" is a structure of key/value pairs that includes the following:
%   "chancolumn" is the name of the column containing channel names.
%   "typecolumn" is the name of the column to read annotated types from.
%   "whitelist" is a cell array containing acceptable type values.
%   "blacklist" is a cell array containing unacceptable type values.

config = struct();
config.chancolumn = 'RawChannel';
config.typecolumn = 'BadChannelType';
config.whitelist = { '' };
config.blacklist = {};


% Done.

end


%
% This is the end of the file.
