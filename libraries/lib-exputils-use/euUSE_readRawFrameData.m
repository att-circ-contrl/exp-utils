function framedata = euUSE_readRawFrameData( runtimedir )

% function framedata = euUSE_readRawFrameData( runtimedir )
%
% This function looks for "*_Trial_(number).txt" files in the FrameData folder
% in the specified directory, and converts them into an aggregated Matlab
% table with rows sorted by timestamp.
%
% New timestamp columns ("SystemTimeSeconds" and "EyetrackerTimeSeconds")
% are generated from the respective native timestamp columns.
%
% "runtimedir" is the "RuntimeData" directory location.
%
% "framedata" is an aggregated data table.


% Make note of timestamp metadata.

% Unity computer timestamps.
unitytimecolumn = 'FrameStartSystem';
unitytick = 1e-7;

% Eye-tracker timestamps.
% FIXME - The timestamp column and time quantum will vary depending on the
% type of eye-tracker used!
eyetimecolumn = 'EyetrackerTimeStamp';
eyetick = 1.0e-6;


% Load the data table.

filepattern = [ runtimedir filesep 'FrameData' filesep '*_Trial_*txt' ];
framedata = euUSE_aggregateTrialFiles(filepattern, unitytimecolumn);


% Augment the table with timestamps in seconds.

framedata.SystemTimeSeconds = framedata.(unitytimecolumn) * unitytick;
framedata.EyetrackerTimeSeconds = framedata.(eyetimecolumn) * eyetick;


% Done.

end


%
% This is the end of the file.
