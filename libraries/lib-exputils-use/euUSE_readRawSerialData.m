function [ sentdata recvdata ] = euUSE_readRawSerialData( runtimedir )

% function [ sentdata recvdata ] = euUSE_readRawSerialData( runtimedir )
%
% This function looks for "*_Trial_(number).txt" files in the SerialSent
% and SerialRecv folders in the specified directory, and converts them
% into aggregated Matlab tables with rows sorted by Unity timestamp.
%
% "runtimedir" is the "RuntimeData" directory location.
%
% "sentdata" is aggregated data from trial files in the "SerialSent" folder.
% "recvdata" is aggregated data from trial files in the "SerialRecv" folder.


filepattern = [ runtimedir filesep 'SerialSent' filesep '*_Trial_*txt' ];
sentdata = euUSE_aggregateTrialFiles(filepattern, 'SystemTimestamp');

filepattern = [ runtimedir filesep 'SerialRecv' filesep '*_Trial_*txt' ];
recvdata = euUSE_aggregateTrialFiles(filepattern, 'SystemTimestamp');


% Done.

end


%
% This is the end of the file.
