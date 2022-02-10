function gazedata = euUSE_readRawGazeData( runtimedir )

% function gazedata = euUSE_readRawGazeData( runtimedir )
%
% This function looks for "*_Trial_(number).txt" files in the GazeData folder
% in the specified directory, and converts them into an aggregated Matlab
% table with rows sorted by timestamp.
%
% A new timestamp column ("time_seconds") is generated from the native gaze
% timestamp column.
%
% "runtimedir" is the "RuntimeData" directory location.
%
% "gazedata" is an aggregated data table.


filepattern = [ runtimedir filesep 'GazeData' filesep '*_Trial_*txt' ];

% FIXME - The timestamp column and time quantum will vary depending on the
% type of eye-tracker used!
timecolumn = 'system_time_stamp';
timetick = 1.0e-6;

gazedata = euUSE_aggregateTrialFiles(filepattern, timecolumn);

gazedata.('time_seconds') = gazedata.(timecolumn) * timetick;


% Done.

end


%
% This is the end of the file.
