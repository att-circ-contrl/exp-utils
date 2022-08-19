% Field Trip sample script / test script.
% Written by Christopher Thomas.


%
% Paths.

% First step: Add the library root folders.
% These should be changed to match your system's locations, or you can set
% them as part of Matlab's global configuration.

addpath('lib-exp-utils-cjt');
addpath('lib-looputil');
addpath('lib-fieldtrip');
addpath('lib-openephys');
addpath('lib-npy-matlab');

% Second step: Call various functions to add library sub-folders.

addPathsExpUtilsCjt;
addPathsLoopUtil;

% Wrap this in "evalc" to avoid the annoying banner.
evalc('ft_defaults');



%
% Load configuration parameters.

do_test_config;

% This loads dataset information, but we still have to pick a dataset.
do_test_datasets;


% Pick the dataset we want to use.

%thisdataset = dataset_big_tungsten;
thisdataset = dataset_big_silicon_20220504;



%
% Initial setup.


% Set the number of channels we want in memory at any given time.
nlFT_setMemChans(memchans);


% Turn off FT notification messages. Otherwise they get spammy.
ft_notice('off');
ft_info('off');

% FIXME - Suppress warnings too.
% Among other things, when preprocessing the auto-generated configs have
% deprecated fields that generate lots of warnings.
ft_warning('off');

% FIXME - Suppress Matlab warnings. The NPy library complains about text data.
% Use "warning(warnstate)" to restore warnings to their default state.
warnstate = warning('off');



%
% Banner.

disp(sprintf('== Processing "%s".', thisdataset.title));



%
% Read the headers and select channels and timespans.

% FIXME - This reads and sets workspace variables directly.
% The Right Way to do this is to accept and return configuration structures.

do_test_get_metadata;



%
% Try autodetecting valid/invalid channels using windowed continuous data.

if want_auto_channel_types
  do_test_autoclassify_chans;
end



%
% Read and preview monolithic data (before segmenting).

% FIXME - This reads and sets workspace variables directly.
% The Right Way to do this is to accept configuration structures and to
% write large result structures to disk.

if want_process_monolithic
  do_test_process_monolithic;
end



%
% Load Unity data and TTL data, and perform alignment.

% FIXME - This reads and sets workspace variables directly.
% The Right Way to do this is to accept configuration structures and to
% write large result structures to disk.

if want_align
  do_test_align;
end



%
% Define data segments and process the segments.

% FIXME - This reads and sets workspace variables directly.
% The Right Way to do this is to accept configuration structures and to
% write large result structures to disk.

if want_define_trials
  do_test_define_trials;
end

% This will load trial definitions from disk if we didn't define them above.
if want_process_trials
  do_test_process_trials;
end



%
% Banner.

disp(sprintf('== Finished processing "%s".', thisdataset.title));


%
% This is the end of the file.
