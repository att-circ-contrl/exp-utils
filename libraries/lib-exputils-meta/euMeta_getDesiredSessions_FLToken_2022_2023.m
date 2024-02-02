function metadata = euMeta_getDesiredSessions_FLToken_2022_2023

% function metadata = euMeta_getDesiredSessions_FLToken_2022_2023
%
% This returns a struct array containing information about which sessions
% and probe channels we want to process from the Frey and Wotan FLToken
% datasets from 2022 and 2023 (NeuroNexus probe datasets).
%
% This experiment used Louie's metadata format.
%
% No arguments.
%
% "metadata" is a struct array per DESIREDSESSIONS.txt.


% Initialize.
metadata = struct([]);


%
% Frey group 02.

% FIXME - This is missing RuntimeData information.
%metadata = helper_addSession( metadata, 'Fr_Probe_02_22-04-27_003_01', ...
%  struct('prACC1', [65:128]) );

metadata = helper_addSession( metadata, 'Fr_Probe_02_22-05-02_004_01', ...
  struct('prACC1', [1:64], 'prCD1', [65:128]) );

metadata = helper_addSession( metadata, 'Fr_Probe_02_22-05-03_005_01', ...
  struct('prACC1', [1:64], 'prCD1', [65:128]) );

metadata = helper_addSession( metadata, 'Fr_Probe_02_22-05-04_006_01', ...
  struct('prACC1', [1:64], 'prCD1', [65:128]) );

metadata = helper_addSession( metadata, 'Fr_Probe_02_22-05-05_007_01', ...
  struct('prACC1', [1:64], 'prCD1', [65:128]) );

metadata = helper_addSession( metadata, 'Fr_Probe_02_22-05-06_008_01', ...
  struct('prACC1', [1:64], 'prCD1', [65:128]) );

metadata = helper_addSession( metadata, 'Fr_Probe_02_22-05-09_009_01', ...
  struct('prACC1', [1:64], 'prCD1', [65:128]) );

metadata = helper_addSession( metadata, 'Fr_Probe_02_22-05-10_010_01', ...
  struct('prACC1', [1:64], 'prCD1', [65:128]) );

metadata = helper_addSession( metadata, 'Fr_Probe_02_22-05-11_011_01', ...
  struct('prACC1', [1:64], 'prCD1', [65:128]) );


%
% Frey group 03.

metadata = helper_addSession( metadata, 'Fr_Probe_03_22-06-30_001_02', ...
  struct('prCD1', [65:128], 'prCD2', [1:64]) );

% NOTE - Spreadsheet says ACC2, PFC2, and CD2 were bad.
%metadata = helper_addSession( metadata, 'Fr_Probe_03_22-07-13_002_01', ...
%  struct('prACC1', [257:320], 'prACC2', [321:384], 'prPFC1', [1:64], ...
%    'prPFC2', [65:128], 'prCD1', [129:192], 'prCD2', [193:256]) );
%
metadata = helper_addSession( metadata, 'Fr_Probe_03_22-07-13_002_01', ...
  struct('prACC1', [257:320], 'prPFC1', [1:64], 'prCD1', [129:192]) );

% NOTE - Spreadsheet says everything was bad.
%metadata = helper_addSession( metadata, 'Fr_Probe_03_22-07-15_003_01', ...
%  struct('prACC1', [257:320], 'prACC2', [321:384], 'prPFC1', [1:64], ...
%    'prCD1', [129:192]) );

metadata = helper_addSession( metadata, 'Fr_Probe_03_22-07-21_004_01', ...
  struct('prACC1', [257:320], 'prACC2', [321:384], 'prPFC1', [1:64], ...
    'prCD1', [129:192]) );


%
% Wotan group 01.

metadata = helper_addSession( metadata, 'Wo_Probe_01_23-02-13_003_01', ...
  struct('prACC1', [65:128], 'prACC2', [1:64], 'prPFC1', [193:256], ...
    'prPFC2', [129:192], 'prCD1', [321:384], 'prCD2', [257:320]) );

metadata = helper_addSession( metadata, 'Wo_Probe_01_23-02-13_003_01', ...
  struct('prACC1', [65:128], 'prACC2', [1:64], 'prPFC1', [193:256], ...
    'prCD1', [321:384]) );

metadata = helper_addSession( metadata, 'Wo_Probe_01_23-02-22_007_01', ...
  struct('prACC1', [65:128], 'prACC2', [1:64], 'prPFC1', [193:256], ...
    'prCD1', [321:384], 'prCD2', [257:320]) );

metadata = helper_addSession( metadata, 'Wo_Probe_01_23-02-23_008_01', ...
  struct('prACC1', [65:128], 'prACC2', [1:64], 'prPFC1', [193:256], ...
    'prCD1', [321:384], 'prCD2', [257:320]) );

metadata = helper_addSession( metadata, 'Wo_Probe_01_23-02-24_009_01', ...
  struct('prACC1', [65:128], 'prACC2', [1:64], 'prPFC1', [193:256], ...
    'prCD1', [321:384], 'prCD2', [257:320]) );

metadata = helper_addSession( metadata, 'Wo_Probe_01_23-02-27_010_01', ...
  struct('prACC1', [65:128], 'prACC2', [1:64], 'prPFC1', [193:256], ...
    'prCD1', [321:384], 'prCD2', [257:320]) );

metadata = helper_addSession( metadata, 'Wo_Probe_01_23-02-28_011_01', ...
  struct('prACC1', [65:128], 'prACC2', [1:64], 'prPFC1', [193:256], ...
    'prCD1', [321:384], 'prCD2', [257:320]) );

metadata = helper_addSession( metadata, 'Wo_Probe_01_23-03-01_012_01', ...
  struct('prACC1', [65:128], 'prACC2', [1:64], 'prPFC1', [193:256], ...
    'prCD1', [321:384], 'prCD2', [257:320]) );

metadata = helper_addSession( metadata, 'Wo_Probe_01_23-03-02_013_01', ...
  struct('prACC1', [65:128], 'prACC2', [1:64], 'prPFC1', [193:256], ...
    'prCD1', [321:384], 'prCD2', [257:320]) );

metadata = helper_addSession( metadata, 'Wo_Probe_01_23-03-03_014_01', ...
  struct('prACC1', [65:128], 'prACC2', [1:64], 'prPFC1', [193:256], ...
    'prCD1', [321:384], 'prCD2', [257:320]) );

metadata = helper_addSession( metadata, 'Wo_Probe_01_23-03-07_016_01', ...
  struct('prACC1', [65:128], 'prACC2', [129:192], 'prPFC1', [321:384], ...
    'prCD1', [449:512], 'prCD2', [385:448]) );

metadata = helper_addSession( metadata, 'Wo_Probe_01_23-03-08_017_01', ...
  struct('prACC1', [65:128], 'prACC2', [129:192], 'prPFC1', [321:384], ...
    'prCD1', [449:512], 'prCD2', [385:448]) );

metadata = helper_addSession( metadata, 'Wo_Probe_01_23-03-09_018_01', ...
  struct('prACC1', [65:128], 'prACC2', [129:192], 'prPFC1', [321:384], ...
    'prCD1', [449:512], 'prCD2', [385:448]) );



% Done.
end


%
% Helper Functions

function newmeta = helper_addSession(oldmeta, dataset, probedefs)

  thismetarec = struct();
  thismetarec.dataset = dataset;

  % Magic values for monkey ID.
  thismetarec.monkey = 'unknown';
  if contains(dataset, 'Fr_')
    thismetarec.monkey = 'Frey';
  elseif contains(dataset, 'Wo_')
    thismetarec.monkey = 'Wotan';
  end

  % Magic values for augmenting probe definitions.
  probenameformat = 'CH_%03d';
  probetitles = struct( ...
    'prACC1', 'Probe ACC 1', 'prACC2', 'Probe ACC 2', ...
    'prPFC1', 'Probe PFC 1', 'prPFC2', 'Probe PFC 2', ...
    'prCD1', 'Probe CD 1', 'prCD2', 'Probe CD 2' );

  % Probe metadata.

  thismetarec.probedefs = struct([]);

  probelabellist = fieldnames(probedefs);
  for pidx = 1:length(probelabellist)

    thislabel = probelabellist{pidx};
    thisnumberlist = probedefs.(thislabel);

    thisproberec = struct();
    thisproberec.label = thislabel;
    thisproberec.title = probetitles.(thislabel);
    thisproberec.channums = thisnumberlist;
    thisproberec.chanlabels = ...
      nlUtil_sprintfCellArray( probenameformat, thisnumberlist );

    thismetarec.probedefs = [ thismetarec.probedefs thisproberec ];

  end

  newmeta = [ oldmeta thismetarec ];

end


%
% This is the end of the file.
