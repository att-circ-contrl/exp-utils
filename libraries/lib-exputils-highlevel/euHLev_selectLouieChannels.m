function newchans_raw = euHLev_selectLouieChannels( ...
  logfile, logdate, oldchans_raw, chanmap_raw, chanmap_cooked )

% function newchans_raw = euHLev_selectLouieChannels( ...
%   logfile, logdate, oldchans_raw, chanmap_raw, chanmap_cooked )
%
% This selects the subset of channels that Louie flagged as "good" in a
% dataset.
%
% If a non-empty channel map is supplied Louie's channel numbers are assumed
% to be cooked channel numbers and the old/new channel lists are assumed to
% be raw channel numbers.
%
% If the channel map is empty then the old/new channel lists and the log file
% are assumed to use the same numbering scheme.
%
% "logfile" is the log file to read.
% "logdate" is the datestamp to look for in the log file.
% "oldchans_raw" is the channel list before pruning.
% "chanmap_raw" is a list of raw channel names to be translated.
% "chanmap_cooked" is a list of corresponding cooked channel names.
%
% "newchans_raw" is a copy of "oldchans_raw" that only contains channels
%   that Louie identified as "good".


% Default to "use all channels".
newchans_raw = oldchans_raw;


% This will throw an error if there are any typos in the file.
try
  thisrec = euUtil_getLouieLogData(logfile, logdate);
catch errordetails
  disp(sprintf( '###  Exception thrown while reading "%s".', logfile ));
  disp(sprintf( 'Message: "%s"', errordetails.message ));

  thisrec = struct([]);
end


if isempty(thisrec)
  disp(sprintf( ...
    '###  Couldn''t find date "%s" in "%s". Using all channels.', ...
    logdate, logfile ));
else
  channums = horzcat(thisrec.PROBE_goodchannels{:});

  % FIXME - Assume a bank name.
  % The right thing to do is to call "nlFT_parseFTName" to get that.
  chanlabels = nlFT_makeLabelsFromNumbers( 'CH', channums );

  if isempty(chanlabels)
    disp('###  Couldn''t get a list of good channels. Using all channels.');
  else
    disp('-- Selecting channels marked as "good".');

    % Turn the specified (cooked) channel names into raw channel names.
    if (~isempty(chanmap_raw)) && (~isempty(chanmap_cooked))
      chanlabels = nlFT_mapChannelLabels( ...
        chanlabels, chanmap_cooked, chanmap_raw );
    end

    % FIXME - We aren't using wildcards, so using FT for this is overkill.
    newchans_raw = ft_channelselection( chanlabels, oldchans_raw, {} );
  end
end


% Done.

end


%
% This is the end of the file.
