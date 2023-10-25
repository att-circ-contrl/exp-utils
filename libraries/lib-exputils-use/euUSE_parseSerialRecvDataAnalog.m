function analogdata = euUSE_parseSerialRecvDataAnalog( serialrecvdata )

% function analogdata = euUSE_parseSerialRecvDataAnalog( serialrecvdata )
%
% This function parses the "SerialRecvData" table from a "serialData"
% structure, read from the "SerialData.mat" file produced by the USE
% processing scripts. It may alternatively be read by using the
% euUSE_readRawSerialData() function.
%
% This extracts analog data sent by the synchbox. To extract event
% information, use euUSE_parseSerialDecvData().
%
% "serialrecvdata" is the data table containing raw inbound serial data.
%
% "analogdata" is a tale containing five analog channels and two flags.
%   Table columns are 'unityTime', 'synchBoxTime', 'joyX', 'joyY', 'joyZ',
%   'lightL', 'lightR', 'flagL', and 'flagR'.


% Constants.

unity_clock_tick = 1.0e-7;
synchbox_clock_tick = 1.0e-4;



% Extract relevant columns from the received data table.

recvtimes = serialrecvdata.SystemTimestamp;
recvmsgs = serialrecvdata.Message;

% Convert Unity timestamps to seconds.
recvtimes = recvtimes * unity_clock_tick;



% Initialize scratch versions of table columns.

utimes = [];
stimes = [];

joyxvals = [];
joyyvals = [];
joyzvals = [];

lightlvals = [];
lightrvals = [];

flagsl = logical([]);
flagsr = logical([]);

foundcount = 0;


% Walk through event records, parsing messages.
% Anything we recognize gets stored in the relevant table columns.
% Convery SynchBox timestamps to seconds while doing this.

for ridx = 1:length(recvtimes)

  thisutime = recvtimes(ridx);
  thismsg = recvmsgs{ridx};


  % We'll get zero or one token lists, and eight token values.
  % Test each of four possible formats.

  % Verbose.
  tokenlist = regexp( thismsg, ...
    [ 'Time: (\w+)\s+Joy \S+ (\w+) (\w+) (\w+)\s+' ...
      'Opt \S+ (\w+) (\w+) (\w)\w\w (\w)\w\w' ], ...
    'tokens' );

  % Terse.
  if isempty(tokenlist)
    tokenlist = regexp( thismsg, ...
      'T: (\w+)\s+XYC: (\w+) (\w+) (\w+)\s+LR: (\w+) (\w+) (\w) (\w)', ...
      'tokens' );
  end

  % Packed with 16-bit analog.
  if isempty(tokenlist)
    tokenlist = regexp( thismsg, ...
      [ 'T(\w+)J(\w\w\w\w)(\w\w\w\w)(\w\w\w\w)' ...
        'L(\w\w\w\w)(\w\w\w\w)(\w)(\w)' ], ...
      'tokens' );
  end

  % Packed with 8-bit analog.
  if isempty(tokenlist)
    tokenlist = regexp( thismsg, ...
      [ 'T(\w+)J(\w\w)(\w\w)(\w\w)' ...
        'L(\w\w)(\w\w)(\w)(\w)' ], ...
      'tokens' );
  end


  % If we had a match, parse the extracted fields.
  if ~isempty(tokenlist)

    foundcount = foundcount + 1;

    utimes(foundcount) = thisutime;
    % Timestamp in hex.
    stimes(foundcount) = hex2dec(tokenlist{1}{1}) * synchbox_clock_tick;

    % Analog joystick values in hex.
    joyxvals(foundcount) = hex2dec(tokenlist{1}{2});
    joyyvals(foundcount) = hex2dec(tokenlist{1}{3});
    joyzvals(foundcount) = hex2dec(tokenlist{1}{4});

    % Analog light sensor values in hex.
    lightlvals(foundcount) = hex2dec(tokenlist{1}{5});
    lightrvals(foundcount) = hex2dec(tokenlist{1}{6});

    % Either "B" or "W", depending on whether light is above or below
    % the auto-set threshold.
    flagsl(foundcount) = strcmpi(tokenlist{1}{7}, 'w');
    flagsr(foundcount) = strcmpi(tokenlist{1}{8}, 'w');

  end
end


% Build the output tables.

% NOTE - We need to transpose the data row vectors to make table columns.

analogdata = table( transpose(utimes), transpose(stimes), ...
  transpose(joyxvals), transpose(joyyvals), transpose(joyzvals), ...
  transpose(lightlvals), transpose(lightrvals), ...
  transpose(flagsl), transpose(flagsr), ...
  'VariableNames', { 'unityTime', 'synchBoxTime', ...
    'joyX', 'joyY', 'joyZ', 'lightL', 'lightR', 'flagL', 'flagR' } );


% Done.

end


%
% This is the end of the file.
