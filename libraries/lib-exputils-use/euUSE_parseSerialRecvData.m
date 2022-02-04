function [ evsynchA evsynchB evrwdA evrwdB evcodes ] = ...
  euUSE_parseSerialRecvData( serialrecvdata, codeformat )

% function [ evsynchA evsynchB evrwdA evrwdB evcodes ] = ...
%   euUSE_parseSerialRecvData( serialrecvdata, codeformat )
%
% This function parses the "SerialRecvData" table from a "serialData"
% structure, read from the "SerialData.mat" file produced by the USE
% processing scripts. It may alternatively be read by using the
% euUSE_readRawSerialData() function.
%
% This table contains communication received by Unity from the SynchBox,
% which includes Unity and SynchBox timestamps. Timing, reward, and event
% code messages are parsed, and are returned as separate tables. Each table
% contains Unity and SynchBox timestamps (converted to seconds); the reward
% tables also contain reward pulse duration in seconds, and event code
% tables contain the event code value.
%
% Event codes may be in any of several formats; "word" format codes are
% preserved as-is, while "byte" format codes are shortened to 8 bits. The
% byte may be taken from the most-significant or least-significant 8 bits
% of the code word. For "dupbyte", the most significant and least significant
% 8 bits are expected to contain the same values; any codes that don't are
% rejected.
%
% "serialrecvdata" is the data table containing raw inbound serial data.
% "codeformat" is 'word' (for 16-bit words), 'hibyte' for MS bytes, 'lobyte'
%   for LS bytes, and 'dupbyte' for MS and LS both replicating a byte value.
%
% "evsynchA" and "evsynchB" are tables containing timing A and B events.
%   Table columns are 'unityTime' and 'synchBoxTime'.
% "evrwdA" and "evrwdB" are tables containing reward trigger A and B events.
%   Table columns are 'unityTime', 'synchBoxTime', and 'pulseDuration'.
% "evcodes" is a table containing event code events. Table columns are
%   'unityTime', 'synchBoxTime', and 'codeValue'.


% Constants.

unity_clock_tick = 1.0e-7;
synchbox_clock_tick = 1.0e-4;



% Extract relevant columns from the received data table.

recvtimes = serialrecvdata.SystemTimestamp;
recvmsgs = serialrecvdata.Message;

% Convert Unity timestamps to seconds.
recvtimes = recvtimes * unity_clock_tick;



% Initialize scratch versions of table columns.

utimeSynchA = [];
utimeSynchB = [];
utimeRwdA = [];
utimeRwdB = [];
utimeCode = [];

stimeSynchA = [];
stimeSynchB = [];
stimeRwdA = [];
stimeRwdB = [];
stimeCode = [];

argRwdA = [];
argRwdB = [];
argCode = [];


% Walk through event records, parsing messages.
% Anything we recognize gets stored in the relevant table columns.
% Convery SynchBox timestamps to seconds while doing this.

for ridx = 1:length(recvtimes)

  thisutime = recvtimes(ridx);
  thismsg = recvmsgs{ridx};

  % We'll get zero or one token lists, and if we have a list, one or two
  % token values.

  tokenlist = regexp( thismsg, 'Synch:\s+(\S+)', 'tokens' );
  if ~isempty(tokenlist)
    arg1 = hex2dec(tokenlist{1}{1});
    thiscount = 1 + length(utimeSynchA);
    utimeSynchA(thiscount) = thisutime;
    stimeSynchA(thiscount) = synchbox_clock_tick * arg1;
  end

  tokenlist = regexp( thismsg, 'Synch 2:\s+(\S+)', 'tokens' );
  if ~isempty(tokenlist)
    arg1 = hex2dec(tokenlist{1}{1});
    thiscount = 1 + length(utimeSynchB);
    utimeSynchB(thiscount) = thisutime;
    stimeSynchB(thiscount) = synchbox_clock_tick * arg1;
  end

  tokenlist = regexp( thismsg, 'Reward:\s+(\S+)\s+(\S+)', 'tokens' );
  if ~isempty(tokenlist)
    arg1 = hex2dec(tokenlist{1}{1});
    arg2 = hex2dec(tokenlist{1}{2});
    thiscount = 1 + length(utimeRwdA);
    utimeRwdA(thiscount) = thisutime;
    stimeRwdA(thiscount) = synchbox_clock_tick * arg1;
    argRwdA(thiscount) = synchbox_clock_tick * arg2;
  end

  tokenlist = regexp( thismsg, 'Reward 2:\s+(\S+)\s+(\S+)', 'tokens' );
  if ~isempty(tokenlist)
    arg1 = hex2dec(tokenlist{1}{1});
    arg2 = hex2dec(tokenlist{1}{2});
    thiscount = 1 + length(utimeRwdB);
    utimeRwdB(thiscount) = thisutime;
    stimeRwdB(thiscount) = synchbox_clock_tick * arg1;
    argRwdB(thiscount) = synchbox_clock_tick * arg2;
  end

  tokenlist = regexp( thismsg, 'Code:\s+(\S+)\s+(\S+)', 'tokens' );
  if ~isempty(tokenlist)
    arg1 = hex2dec(tokenlist{1}{1});
    arg2 = hex2dec(tokenlist{1}{2});

    % Preprocess this according to type.
    keepcode = true;
    if strcmp('hibyte', codeformat)
      % Most significant byte.
      arg2 = bitand(arg2, 0xff00);
      arg2 = bitshift(arg2, -8);
    elseif strcmp('lobyte', codeformat)
      % Least significant byte.
      arg2 = bitand(arg2, 0x00ff);
    elseif strcmp('dupbyte', codeformat)
      % Most significant and least significant bytes must be identical.
      arg2hi = bitand(arg2, 0xff00);
      arg2hi = bitshift(arg2hi, -8);
      arg2 = bitand(arg2, 0x00ff);
      if arg2 ~= arg2hi
        keepcode = false;
      end
    else
      % Assume 16-bit word; keep it as-is.
    end

    % If this code is valid, store it.
    if keepcode
      thiscount = 1 + length(utimeCode);
      utimeCode(thiscount) = thisutime;
      stimeCode(thiscount) = synchbox_clock_tick * arg1;
      % Code is an integer, not a timestamp.
      argCode(thiscount) = arg2;
    end
  end
end


% Build the output tables.

% NOTE - We need to transpose the data row vectors to make table columns.

evsynchA = table( transpose(utimeSynchA), transpose(stimeSynchA), ...
  'VariableNames', {'unityTime', 'synchBoxTime'} );
evsynchB = table( transpose(utimeSynchB), transpose(stimeSynchB), ...
  'VariableNames', {'unityTime', 'synchBoxTime'} );
evrwdA = table( transpose(utimeRwdA), transpose(stimeRwdA), ...
  transpose(argRwdA), ...
  'VariableNames', {'unityTime', 'synchBoxTime', 'pulseDuration'} );
evrwdB = table( transpose(utimeRwdB), transpose(stimeRwdB), ...
  transpose(argRwdB), ...
  'VariableNames', {'unityTime', 'synchBoxTime', 'pulseDuration'} );
evcodes = table( transpose(utimeCode), transpose(stimeCode), ...
  transpose(argCode), ...
  'VariableNames', {'unityTime', 'synchBoxTime', 'codeValue'} );


% Done.

end


%
% This is the end of the file.
