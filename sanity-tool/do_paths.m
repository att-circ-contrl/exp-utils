% This adds the various ACC Lab and external project paths.

addpath('../libs-ext/lib-exp-utils-cjt');
addpath('../libs-ext/lib-looputil');
addpath('../libs-ext/lib-fieldtrip');
addpath('../libs-ext/lib-openephys');
addpath('../libs-ext/lib-npy-matlab');

addPathsExpUtilsCjt;
addPathsLoopUtil;

% Wrap this in "evalc" to avoid the annoying banner.
evalc('ft_defaults');

% This is the end of the file.
