function gazedata = euUSE_readRawGazeData( runtimedir )

% function gazedata = euUSE_readRawGazeData( runtimedir )
%
% This function looks for "*_Trial_(number).txt" files in the GazeData folder
% in the specified directory, and converts them into an aggregated Matlab
% table with rows sorted by Unity timestamp.
%
% "runtimedir" is the "RuntimeData" directory location.
%
% "gazedata" is an aggregated data table.


filepattern = [ runtimedir filesep 'GazeData' filesep '*_Trial_*txt' ];
gazedata = euUSE_aggregateTrialFiles(filepattern, 'system_time_stamp');


% Done.

end


%
% This is the end of the file.
