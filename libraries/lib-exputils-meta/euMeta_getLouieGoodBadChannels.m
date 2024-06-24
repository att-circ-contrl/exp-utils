function [ badchannels goodchannels ] = euMeta_getLouieGoodBadChannels( ...
  banklabel, logrecord )

% function [ badchannels goodchannels ] = euMeta_getLouieGoodBadChannels( ...
%   banklabel, logrecord )
%
% This generates lists of FT channel names for good and bad channels that
% were manually annotated in Louie's log data.
%
% "banklabel" is a character vector with the bank name to use when generating
%   Field Trip channel labels.
% "logrecord" is a structure in Louie's log format.
%
% "badchannels" is a cell array with Field Trip channel labels for channels
%   that were listed as "bad".
% "goodchannels" is a cell array with Field Trip channel labels for channels
%   that were listed as "good" (task-modulated spiking, usually).


% Initialize.
badchannels = {};
goodchannels = {};


% Fetch the raw lists.
% Louie stores these as cell arrays with per-probe channel list vectors.
% He also sometimes used "badd" instead of "bad".

rawbad = {};
if isfield(logrecord, 'PROBE_badchannels')
  rawbad = logrecord.PROBE_badchannels;
elseif isfield(logrecord, 'PROBE_baddchannels')
  rawbad = logrecord.PROBE_baddchannels;
end

rawgood = {};
if isfield(logrecord, 'PROBE_goodchannels')
  rawgood = logrecord.PROBE_goodchannels;
end


% Build the processed lists.

for lidx = 1:length(rawbad)
  thislist = nlFT_makeFTNameList( banklabel, rawbad{lidx} );
  thislist = reshape(thislist, [], 1);
  badchannels = [ badchannels ; thislist ];
end

badchannels = unique(badchannels);

for lidx = 1:length(rawgood)
  thislist = nlFT_makeFTNameList( banklabel, rawgood{lidx} );
  thislist = reshape(thislist, [], 1);
  goodchannels = [ goodchannels ; thislist ];
end

goodchannels = unique(goodchannels);


% Done.
end


%
% This is the end of the file.
