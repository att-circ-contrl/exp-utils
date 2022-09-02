function [ boxevents gameevents evcodedefs ] = ...
  euUSE_readAllUSEEvents( runtimefolder, codeformat, codebytes, codeendian )

% function [ boxevents gameevents evcodedefs ] = ...
%   euUSE_readAllUSEEvents( runtimefolder, codeformat, codebytes, codeendian )
%
% This function reads and parses serial data from a USE "RuntimeData" folder.
% This gives events and timestamps from USE and from the SynchBox.
%
% This is a wrapper for the following functions:
%   euUSE_readRawSerialData()
%   euUSE_parseSerialRecvData()
%   euUSE_parseSerialSentData()
%   euUSE_readEventCodeDefs()
%   euUSE_reassembleEventCodes()
%
% "runtimefolder" is the path to the "RuntimeData" folder.
% "codeformat" is the event code format used by the SynchBox. This is 'word',
%   'hibyte', 'lobyte', or 'dupbyte', per euUSE_parseSerialRecvData().
%   This defaults to 'dupbyte' if unspecified.
% "codebytes" is the number of bytes used to encode each event code.
%   This defaults to 2 if unspecified.
% "codeendian" is 'big' if the most significant byte is received first or
%   'little' if the least-significant byte is received first.
%    This defaults to 'big' if unspecified.
%
% "boxevents" is a structure with fields "synchA", "synchB", "rwdA", "rwdB",
%   "rawcodes", and "cookedcodes". These each contain tables of events.
%   Common columns are 'unityTime' and 'synchBoxTime'. Additional columns are
%   'pulseDuration' (for rewards), 'codeValue' (for raw codes), and
%   'codeWord', 'codeData', and 'codeLabel' (for cooked codes).
% "gameevents" is a structure with fields "rwdA", "rwdB", "rawcodes", and
%   "cookedcodes". These each contain tables of events. All tables contain
%   a 'unityTime' column. Additional columns are 'pulseDuration' (for
%   rewards), 'codeValue' (for raw codes), and 'codeWord', 'codeData', and
%   'codeLabel' (for cooked codes).
% "evcodedefs" is a USE event code definition structure per EVCODEDEFS.txt.


disp('-- Reading USE serial event data.');


% FIXME - Set defaults if not specified.

if ~exist('codeformat', 'var')
  codeformat = 'dupbyte';
end

if ~exist('codebytes', 'var')
  codebytes = 2;
end

if ~exist('codeendian', 'var')
  codeendian = 'big';
end


% Read and parse serial data.

[ sentdata recvdata ] = euUSE_readRawSerialData(runtimefolder);

[ boxsynchA boxsynchB boxrwdA boxrwdB boxcodes_raw ] = ...
  euUSE_parseSerialRecvData(recvdata, codeformat);
[ gamerwdA gamerwdB gamecodes_raw ] = ...
  euUSE_parseSerialSentData(sentdata, codeformat);


% Translate raw code bytes into cooked codes.

evcodedefs = euUSE_readEventCodeDefs(runtimefolder);

[ boxcodes_cooked origlocations ] = euUSE_reassembleEventCodes( ...
  boxcodes_raw, evcodedefs, codebytes, codeendian, 'codeValue' );
[ gamecodes_cooked origlocations ] = euUSE_reassembleEventCodes( ...
  gamecodes_raw, evcodedefs, codebytes, codeendian, 'codeValue' );


% Package box and game events into structures.

boxevents = struct();
boxevents.synchA = boxsynchA;
boxevents.synchB = boxsynchB;
boxevents.rwdA = boxrwdA;
boxevents.rwdB = boxrwdB;
boxevents.rawcodes = boxcodes_raw;
boxevents.cookedcodes = boxcodes_cooked;

gameevents = struct();
gameevents.rwdA = gamerwdA;
gameevents.rwdB = gamerwdB;
gameevents.rawcodes = gamecodes_raw;
gameevents.cookedcodes = gamecodes_cooked;


disp('-- Finished reading USE serial event data.');


% Done.

end


%
% This is the end of the file.
