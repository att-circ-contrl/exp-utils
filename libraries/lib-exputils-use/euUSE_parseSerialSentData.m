function [ evrwdA evrwdB evcodes ] = ...
  euUSE_parseSerialSentData( serialsentdata, codeformat )

% function [ evrwdA evrwdB evcodes ] = ...
%   euUSE_parseSerialSentData( serialsentdata, codeformat )
%
% This function parses the "SerialSentData" table from a "serialData"
% structure, read from the "SerialData.mat" file produced by the USE
% processing scripts. It may alternatively be read by using the
% euUSE_readRawSerialData() function.
%
% This table contains communication sent from Unity to the SynchBox, which
% includes Unity timestamps (but no synchbox timestamps). Reward and event
% code messages are parsed, and are returned as separate tables. Each table
% contains Unity timestamps (converted to seconds); the reward tables also
% contain reward pulse duration in seconds, and event code tables contain
% the event code value.
%
% Event codes may be in any of several formats; "word" format codes are
% preserved as-is, while "byte" format codes are shortened to 8 bits. The
% byte may be taken from the most-significant or least-significant 8 bits
% of the code word. For "dupbyte", the most significant and least significant
% 8 bits are expected to contain the same values; any codes that don't are
% rejected.
%
% "serialsentdata" is the data table containing raw outbound serial data.
% "codeformat" is 'word' (for 16-bit words), 'hibyte' for MS bytes, 'lobyte'
%   for LS bytes, and 'dupbyte' for MS and LS both replicating a byte value.
%
% "evrwdA" and "evrwdB" are tables containing reward trigger A and B events.
%   Table columns are 'unityTime' and 'pulseDuration'.
% "evcodes" is a table containing event code events. Table columns are
%   'unityTime' and 'codeValue'.


% Constants.

unity_clock_tick = 1.0e-7;
% Needed for reward durations.
synchbox_clock_tick = 1.0e-4;



% Extract relevant columns from the sent data table.

senttimes = serialsentdata.SystemTimestamp;
sentmsgs = serialsentdata.Message;

% Convert Unity timestamps to seconds.
senttimes = senttimes * unity_clock_tick;



% Initialize scratch versions of table columns.

utimeRwdA = [];
utimeRwdB = [];
utimeCode = [];

argRwdA = [];
argRwdB = [];
argCode = [];


% Walk through event records, parsing messages.
% Anything we recognize gets stored in the relevant table columns.

for sidx = 1:length(senttimes)

  thisutime = senttimes(sidx);
  thismsg = sentmsgs{sidx};

  % We'll get zero or one token lists, and if we have a list, one token
  % value.

  tokenlist = regexp( thismsg, 'RWD\s+(\d+)', 'tokens' );
  if ~isempty(tokenlist)
    arg1 = str2double(tokenlist{1}{1});
    thiscount = 1 + length(utimeRwdA);
    utimeRwdA(thiscount) = thisutime;
    argRwdA(thiscount) = synchbox_clock_tick * arg1;
  end

  tokenlist = regexp( thismsg, 'RWB\s+(\d+)', 'tokens' );
  if ~isempty(tokenlist)
    arg1 = str2double(tokenlist{1}{1});
    thiscount = 1 + length(utimeRwdB);
    utimeRwdB(thiscount) = thisutime;
    argRwdB(thiscount) = synchbox_clock_tick * arg1;
  end

  tokenlist = regexp( thismsg, 'NEU\s+(\d+)', 'tokens' );
  if ~isempty(tokenlist)
    arg1 = str2double(tokenlist{1}{1});

    % Preprocess this according to type.
    keepcode = true;
    if strcmp('hibyte', codeformat)
      % Most significant byte.
      arg1 = bitand(arg1, 0xff00);
      arg1 = bitshift(arg1, -8);
    elseif strcmp('lobyte', codeformat)
      % Least significant byte.
      arg1 = bitand(arg1, 0x00ff);
    elseif strcmp('dupbyte', codeformat)
      % Most significant and least significant bytes must be identical.
      arg1hi = bitand(arg1, 0xff00);
      arg1hi = bitshift(arg1hi, -8);
      arg1 = bitand(arg1, 0x00ff);
      if arg1 ~= arg1hi
        keepcode = false;
      end
    else
      % Assume 16-bit word; keep it as-is.
    end

    % If this code is valid, store it.
    if keepcode
      thiscount = 1 + length(utimeCode);
      utimeCode(thiscount) = thisutime;
      argCode(thiscount) = arg1;
    end
  end
end


% Build the output tables.

% NOTE - We need to transpose the data row vectors to make table columns.

evrwdA = table( transpose(utimeRwdA), transpose(argRwdA), ...
  'VariableNames', {'unityTime', 'pulseDuration'} );
evrwdB = table( transpose(utimeRwdB), transpose(argRwdB), ...
  'VariableNames', {'unityTime', 'pulseDuration'} );
evcodes = table( transpose(utimeCode), transpose(argCode), ...
  'VariableNames', {'unityTime', 'codeValue'} );


% Done.

end


%
% This is the end of the file.
