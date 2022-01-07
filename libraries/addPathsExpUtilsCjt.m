function addPathsExpUtilsCjt

% function addPathsExpUtilsCjt
%
% This function detects its own path and adds appropriate child paths to
% Matlab's search path.
%
% No arguments or return value.


% Detect the current path.

fullname = which('addPathsExpUtilsCjt');
[ thisdir fname fext ] = fileparts(fullname);


% Add the new paths.
% (This checks for duplicates, so we don't have to.)

% FIXME - Sort these by category once we have more of them.
addpath([ thisdir filesep 'lib-evcodes' ]);
addpath([ thisdir filesep 'lib-exputils-ft' ]);


% Done.

end


%
% This is the end of the file.
