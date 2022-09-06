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

addpath([ thisdir filesep 'lib-exputils-align' ]);
addpath([ thisdir filesep 'lib-exputils-ft' ]);
addpath([ thisdir filesep 'lib-exputils-plot' ]);
addpath([ thisdir filesep 'lib-exputils-tools' ]);
addpath([ thisdir filesep 'lib-exputils-use' ]);
addpath([ thisdir filesep 'lib-exputils-util' ]);


% Done.

end


%
% This is the end of the file.
