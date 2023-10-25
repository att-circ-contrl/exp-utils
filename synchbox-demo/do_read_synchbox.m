% Quick and dirty test program for parsing USE synchbox traffic.

addpath('lib-exp-utils-cjt');
addPathsExpUtilsCjt;


%
% Configuration.

%rawfolder = 'samples-louie';
rawfolder = 'samples-marcus';

outdir = 'output';


%
% Main program.


disp('-- Reading raw serial data.');
disp(char(datetime));

[ sentdata recvdata ] = euUSE_readRawSerialData(rawfolder);

disp(char(datetime));
disp(sprintf( '.. %d lines sent, %d lines received.', ...
  height(sentdata), height(recvdata) ));


disp('-- Parsing events from sent and received data.');

[ sentrwdA sentrwdB sentcodes ] = ...
  euUSE_parseSerialSentData( sentdata, 'dupbyte' );
[ recvsynchA recvsynchB recvrwdA recvrwdB recvcodes ] = ...
  euUSE_parseSerialRecvData( recvdata, 'dupbyte' );

disp(sprintf( '.. Sent:   %d rwdA   %d rwdB   %d codes', ...
  height(sentrwdA), height(sentrwdB), height(sentcodes) ));
disp(sprintf( ...
  '.. Received:   %d synchA   %d synchB   %d rwdA   %d rwdB   %d codes', ...
  height(recvsynchA), height(recvsynchB), ...
  height(recvrwdA), height(recvrwdB), height(recvcodes) ));


disp('-- Parsing analog data from received data.');

recvanalog = euUSE_parseSerialRecvDataAnalog( recvdata );

disp(sprintf( '.. %d data points received.', height(recvanalog) ));


disp([ '-- Saving data to "' outdir '".' ]);

save( [ outdir filesep 'rawdata.mat' ], 'sentdata', 'recvdata', '-v7.3' );
save( [ outdir filesep 'sent_events.mat' ], ...
  'sentrwdA', 'sentrwdB', 'sentcodes', '-v7.3' );
save( [ outdir filesep 'recv_events.mat' ], ...
  'recvsynchA', 'recvsynchB', 'recvrwdA', 'recvrwdB', 'recvcodes', '-v7.3' );
save( [ outdir filesep 'recv_analog.mat' ], 'recvanalog', '-v7.3' );

disp('-- Done.');


%
% This is the end of the file.
