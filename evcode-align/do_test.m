% Quick and dirty test script for event code time alignment.
% Written by Christopher Thomas.

%
% Includes

% Add root paths.
addpath('lib-exp-utils-cjt');
addpath('lib-looputil');
addpath('lib-fieldtrip');
addpath('openephys-tools');
addpath('npy-matlab');

% Add sub-folders.
addPathsExpUtilsCjt;
addPathsLoopUtil;

% Wrap this in "evalc" to avoid the annoying banner.
evalc('ft_defaults');


%
% Behaviour switches.

% Time alignment steps to perform.
want_align_synchbox_ephys = true;
want_align_unity_ephys = true;

% This is used for USB jitter measurement plots and not much else.
want_align_unity_synchbox = true;

% Behavior switch for time alignment (suppresses data value matching).
want_blind_alignment = false;

% This removes unmatched event code entries from their respective tables.
want_remove_unmatched = false;


% Verbosity levels are 'quiet', 'normal', and 'verbose'.
%verbosity_codes = 'normal';
verbosity_codes = 'verbose';
verbosity_align = 'normal';

% Canonical event code source.
code_source = 'ephys';
%code_source = 'synchbox';
%code_source = 'unity';



%
%
% Constants

% Output folders.
folder_plots = 'plots';


% This should be the folder with "SerialData.mat" and other processed data.
folder_usedata = 'datasets/exp-si-20210914-use/ProcessedData';

% This should be the "SessionSettings" folder in the USE tree.
folder_usesettings = ...
  'datasets/exp-si-20210914-use/RuntimeData/SessionSettings';


% This should be the folder with "settings.xml".
folder_ephysroot = 'datasets/exp-si-20210914-openephys';

% If we're using binary format, this should be the folder with
% "structure.oebin". Otherwise it should be the empty string.
%folder_ephysbinary = '';
folder_ephysbinary = sprintf('%s/experiment1/recording1', folder_ephysroot);


% Lookup table for building event codes.
% Bits that don't contribute should be set to 0.
% This is Matlab's default fill value, so we can do that implicitly.
evcode_ttl_bits = [];
evcode_ttl_bits(9) = 0x01;
evcode_ttl_bits(10) = 0x02;
evcode_ttl_bits(11) = 0x04;
evcode_ttl_bits(12) = 0x08;
evcode_ttl_bits(13) = 0x10;
evcode_ttl_bits(14) = 0x20;
evcode_ttl_bits(15) = 0x40;
evcode_ttl_bits(16) = 0x80;


% Overrides table for ranged event codes.
% NOTE - BlockCondition is 501..599. Leave it alone; it appears in
% other data files as-is.
evcode_overrides = struct( ...
  'Dimensionality', struct('offset', 200), ...
  'RewardValidity', struct('offset', 100), ...
  'TrialIndex', struct('offset', 4000), ...
  'TrialNumber', struct('offset', 12000), ...
  'TokensAdded', struct('offset', 70) );

% Event code encoding.
bytespercode = 2;
codeendian = 'big';


% Time alignment configuration.

% Columns to pull data from, for data matching during alignment.
firstdatacol = 'codeValue';
seconddatacol = 'codeValue';

% We have the option of ignoring data and matching on timestamps alone.
if want_blind_alignment
  firstdatacol = '';
  seconddatacol = '';
end


% Time alignment tuning parameters.

% Worst-case drift is 1000 ppm. Worst-case trace length is 1e+4 sec.
% Frames last 17 ms. Once we're localized to within half a frame or better,
% we can use the fine search (which freezes mapping).

% Global fixed-offset pass gives 10 sec accuracy.
% Coarse pass uses a 100 sec window and gives 0.1 sec accuracy.
% Medium pass uses a 1 sec window and gives 1 ms accuracy.
% (In practice this might be limited to one-frame accuracy, depending on
% which timestamps are being aligned.)
% Fine pass uses a 100 ms window and gives 0.1 ms accuracy.

% For coarse alignment windows, the window slides in steps equal to the
% window radius. We pick one representative sample near the middle of the
% window and consider alignment candidates for it.

% An alignment using a constant global delay is performed using the first
% coarse window value, in addition to sliding-window alignment.

% For medium alignment windows, each sample in turn is used as the center
% of the sliding window, and alignment candidates are considered for the
% central sample.

% For fine alignment, each sample in turn is used as the center of the
% sliding window, and all samples within the window are matched against
% their nearest candidates. Time offset is optimized to minimize the cost
% of all of these matchings. The resulting offset is taken as the center
% sample's true time offset.

coarsewindows = [ 100.0 ];
medwindows = [ 1.0 ];
finewindow = 0.1;

% A filtering pass is performed to remove outlier time-deltas.
% These would otherwise substantially skew time estimates around them.
outliersigma = 4.0;



%
%
% Main Program


%
%
% First step: Load event-related data.


%
% Load and parse the USE data.

disp('-- Loading SynchBox data...');

load( [ folder_usedata filesep 'SerialData.mat' ], 'serialData');
[ boxsynchA boxsynchB boxrwdA boxrwdB boxcodes ] = ...
  euUSE_parseSerialRecvData(serialData.SerialRecvData, 'dupbyte');
[ gamerwdA gamerwdB gamecodes ] = ...
  euUSE_parseSerialSentData(serialData.SerialSentData, 'dupbyte');


% FIXME - FrameData contains columns of interest:
% EventCodes, SplitEventCodes, PreSplitEventCodes, ArduinoTimeStamp,
% FrameStartUnity, FrameStartSystem


% Load the event code definition JSON file and process it.

disp('-- Loading event code definitions...');

fname = [ folder_usesettings filesep 'eventcodes_USE_05.json' ];
evcodedefsraw = jsondecode(fileread(fname));

% This parses individual codes and "Min"/"Max" range codes.
evcodedefs = euUSE_parseEventCodeDefs(evcodedefsraw, evcode_overrides);



%
% Load the TTL data and assemble event code bytes.

disp('-- Loading TTL events...');

% FIXME - Suppress NPy warnings.
warnstate = warning('off');


% The header gives us the sampling rate.
rechdr = ...
  ft_read_header(folder_ephysbinary, 'headerformat', 'nlFT_readHeader');

% This reads all events.
recevents_dig = ...
  ft_read_event( folder_ephysbinary, 'headerformat', 'nlFT_readHeader', ...
    'eventformat', 'nlFT_readEvents' );

% We only care about events from the 'DigWordsA_000' channel.
evchans = { recevents_dig.type };
evmask = strcmp(evchans, 'DigWordsA_000');
recevents_dig = recevents_dig(evmask);


% FIXME - Restore warnings.
warning(warnstate);


% Extract relevant parts of the data.

disp('-- Assembling event codes...');

ttlsamprate = rechdr.Fs;

ttlrawdata = [ recevents_dig.value ];
ttlrawtimes = [ recevents_dig.sample ];

% We have the correct bit order, but we only need the top 8 bits.
% We know that the original data is 16-bit.
evcodevals = bitshift(ttlrawdata, -8, 'uint16');

% Timestamps are fine as-is.
evcodesamps = ttlrawtimes;

% Merge codes that repeat the same timestamp or that are one sample apart.
[evcodevals, evcodesamps] = euUSE_deglitchEvents(evcodevals, evcodesamps);

% Remove codes with value 0, as that's the idle state.
keepidx = (evcodevals > 0);
evcodesamps = evcodesamps(keepidx);
evcodevals = evcodevals(keepidx);

% Get timestamps in seconds.
evcodetimes = evcodesamps;
if (~isnan(ttlsamprate)) && (~isempty(evcodesamps))
  evcodetimes = evcodesamps / ttlsamprate;
end


% Turn this into a data table.
% NOTE - Make sure we're dealing with column vectors when building the table.

ephyscodes = table();
if ~isempty(evcodevals)
  if isrow(evcodevals) ; evcodevals = transpose(evcodevals); end
  if isrow(evcodesamps) ; evcodesamps = transpose(evcodesamps); end
  if isrow(evcodetimes) ; evcodetimes = transpose(evcodetimes); end

  if ~isnan(ttlsamprate)
    % We have timestamps in seconds as well.
    ephyscodes = table( evcodevals, evcodesamps, evcodetimes, ...
      'VariableNames', {'codeValue', 'ephysSample', 'ephysTime'} );
  else
    % We only have sample indices.
    ephyscodes = table( evcodevals, evcodesamps, ...
      'VariableNames', {'codeValue', 'ephysSample'} );
  end
end



%
% FIXME - Remove enormous offsets from time series.

% The real problem is the Unity timestamps, which are relative to 1 Jan 1970.
% So, pick a common offset for each _type_ of timestamp, and subtract that
% offset from all relevant table columns.

% FIXME - Just leave synchbox and ephys as-is.
synchboxoffset = 0;
ephysoffset = 0;

% Calculate a Unity timestamp offset.
% Negative values are okay, so just pick from one series.
unityoffset = min(gamecodes.unityTime);

% Apply the Unity timestamp offset.

boxcodes.unityTime = boxcodes.unityTime - unityoffset;
gamecodes.unityTime = gamecodes.unityTime - unityoffset;

if ~isempty(gamerwdA)
  gamerwdA.unityTime = gamerwdA.unityTime - unityoffset;
end
if ~isempty(gamerwdB)
  gamerwdB.unityTime = gamerwdB.unityTime - unityoffset;
end

if ~isempty(boxrwdA)
  boxrwdA.unityTime = boxrwdA.unityTime - unityoffset;
end
if ~isempty(boxrwdB)
  boxrwdB.unityTime = boxrwdB.unityTime - unityoffset;
end

if ~isempty(boxsynchA)
  boxsynchA.unityTime = boxsynchA.unityTime - unityoffset;
end
if ~isempty(boxsynchB)
  boxsynchB.unityTime = boxsynchB.unityTime - unityoffset;
end



%
%
% Second step: Do time alignment between SynchBox and ephys.

% This adds ephys timestamps to the SynchBox table and vice versa.

% This has to use the raw event bytes to get decent precision.
% Enough bytes are dropped that we get horrible mismatches with cooked
% event code words.

% Do Unity/SynchBox jitter measurements in this step too.


times_synchbox_ephys = table();

if want_align_synchbox_ephys

  %
  % SynchBox times (from replies to Unity) vs ephys times.

  % This is dominated by long-term drift in the SynchBox's clock crystal.


  disp('-- Aligning SynchBox with Ephys.');

  [ boxcodes, ephyscodes, boxmatchmask, boxephysmatchmask, ...
    times_synchbox_ephys ] = ...
    euAlign_alignTables( boxcodes, ephyscodes, ...
      'synchBoxTime', 'ephysTime', firstdatacol, seconddatacol, ...
      coarsewindows, medwindows, finewindow, ...
      outliersigma, verbosity_align );


  % Report event hit/miss rate.

  matchcount = sum(boxmatchmask);
  misscountfirst = sum(~boxmatchmask);
  misscountsecond = sum(~boxephysmatchmask);

  disp(sprintf( ...
    '.. Matched %d events; missed %d SynchBox and %d ephys.', ...
    matchcount, misscountfirst, misscountsecond ));


  % Add a time shift column. This is just ephysTime - synchBoxTime.

  boxcodes.('boxShift') = boxcodes.ephysTime - boxcodes.synchBoxTime;
  ephyscodes.('boxShift') = ephyscodes.ephysTime - ephyscodes.synchBoxTime;


  % Make plots.

  disp('-- Plotting.');

  % SynchBox timestamps vs Ephys timestamps.
  % FIXME - 2-sigma is good with raw codes, but as soon as we reassemble
  % them we get a multimodal distribution that needs 4-sigma.

  % Get match and miss tables.
  eventsboxmatch = boxcodes(boxmatchmask, :);
  eventsboxmiss = boxcodes(~boxmatchmask, :);
  eventsboxopenmiss = ephyscodes(~boxephysmatchmask, :);

  doPlotTimeStats( sprintf('%s/test-boxreply', folder_plots), ...
    struct( 'match', eventsboxmatch, ...
      'synchmiss', eventsboxmiss, 'ephysmiss', eventsboxopenmiss), ...
    { 'synchmiss', 'ephysmiss' }, ...
    struct( 'synchbox', 'synchBoxTime', 'ephys', 'ephysTime' ), ...
    struct( 'delta', ...
      struct('timelabel', 'ephysTime', 'deltalabel', 'boxShift') ), ...
    4.0 );


  % Remove unmatched entries, if requested.

  if want_remove_unmatched
    boxcodes = boxcodes(boxmatchmask,:);
    ephyscodes = ephyscodes(boxephysmatchmask,:);
  end

end


if want_align_unity_synchbox
  %
  % Unity times vs SynchBox times (from SynchBox replies to Unity).

  % This has multimodal jitter due to buffering in the USB serial link.
  % That's pretty much what this test is intended to measure.

  disp('-- Measuring SynchBox-to-Unity communications jitter.');

  scratchtab = boxcodes;
  scratchtab.('serialShift') = ...
    scratchtab.('synchBoxTime') - scratchtab.('unityTime');

  doPlotTimeStats( sprintf('%s/test-unityloopback', folder_plots), ...
    struct( 'boxreply', scratchtab ), {}, ...
    struct( 'unity', 'unityTime', 'synchbox', 'synchBoxTime' ), ...
    struct( 'delta', ...
      struct('timelabel', 'synchBoxTime', 'deltalabel', 'serialShift') ), ...
    4.0 );
end



%
%
% Third step: Reconstruct and translate event codes.

disp('-- Rebuilding event codes.');

[ ephyscodes ephyscodeindices ] = euUSE_reassembleEventCodes( ...
  ephyscodes, evcodedefs, bytespercode, codeendian, 'codeValue' );
[ boxcodes boxcodeindices ] = euUSE_reassembleEventCodes( ...
  boxcodes, evcodedefs, bytespercode, codeendian, 'codeValue' );
[ gamecodes gamecodeindices ] = euUSE_reassembleEventCodes( ...
  gamecodes, evcodedefs, bytespercode, codeendian, 'codeValue' );

% Diagnostics.
disp(sprintf( ...
  '... Found %d ephys codes, %d SynchBox codes, %d Unity codes.', ...
  length(ephyscodeindices), length(boxcodeindices), ...
  length(gamecodeindices) ));


% Copy the canonical set of codes for statistics reporting.

cookedcodes = table();

if strcmp(code_source, 'ephys')
  cookedcodes = ephyscodes;
elseif strcmp(code_source, 'synchbox')
  cookedcodes = boxcodes;
elseif strcmp(code_source, 'unity')
  cookedcodes = gamecodes;
else
  disp(sprintf( '### Unknown event code source "%s"; using ephys codes.', ...
    code_source ));
  code_source = 'ephys';
  cookedcodes = ephyscodes;
end


% Get statistics for the canonical code list.

[ totalcount goodcount goodunique gooddesc ...
  badcount badunique baddesc ] = ...
  doGetEventStatistics( cookedcodes, sprintf('%s/test', folder_plots) );

if totalcount < 1
  disp(sprintf( '.. No codes found in code source "%s".', code_source ));
elseif ~strcmp('quiet', verbosity_codes)

  disp(sprintf( ...
    '... Code source "%s" has %d good codes and %d bad codes (total %d)', ...
    code_source, goodcount, badcount, totalcount ));

  % Statistics on bad codes.
  if badcount > 0
    disp(sprintf( '... %d unique "bad" codes.', length(badunique) ));

    if strcmp('verbose', verbosity_codes)
      % Use fprintf, not disp(), since we have trailing newlines.
      fprintf('%s', baddesc);
    end
  end

  % Statistics on good codes.
  if goodcount > 0
    disp(sprintf( '... %d unique "good" codes.', length(goodunique) ));

    if strcmp('verbose', verbosity_codes)
      % Use fprintf, not disp(), since we have trailing newlines.
      fprintf('%s', gooddesc);
    end
  end

end



%
%
% Fourth step: Do time alignment between Unity and ephys.

% This adds Unity timestamps to the ephys table and vice versa.

times_unity_ephys = table();

if want_align_unity_ephys

  %
  % Unity times (from commands to synchbox) vs ephys times.

  % This is surprisingly clean; sub-ms accuracy with few outliers.

  disp('-- Aligning Unity with Ephys.');

  [ gamecodes, ephyscodes, gamematchmask, gameephysmatchmask, ...
    times_unity_ephys ] = ...
    euAlign_alignTables( gamecodes, ephyscodes, ...
      'unityTime', 'ephysTime', firstdatacol, seconddatacol, ...
      coarsewindows, medwindows, finewindow, outliersigma, ...
      verbosity_align );


  % Report event hit/miss rate.

  matchcount = sum(gamematchmask);
  misscountfirst = sum(~gamematchmask);
  misscountsecond = sum(~gameephysmatchmask);

  disp(sprintf( '.. Matched %d events; missed %d Unity and %d ephys.', ...
    matchcount, misscountfirst, misscountsecond ));


  % Add a time shift column. This is just ephysTime - unityBoxTime.

  gamecodes.('unityShift') = gamecodes.ephysTime - gamecodes.unityTime;
  ephyscodes.('unityShift') = ephyscodes.ephysTime - ephyscodes.unityTime;


  % Make plots.

  disp('-- Plotting.');

  % Unity timestamps vs Ephys timestamps.

  % Get match and miss tables.
  eventsgamematch = gamecodes(gamematchmask, :);
  eventsgamemiss = gamecodes(~gamematchmask, :);
  eventsgameopenmiss = ephyscodes(~gameephysmatchmask, :);

  doPlotTimeStats( sprintf('%s/test-unitysend', folder_plots), ...
    struct( 'match', eventsgamematch, ...
      'unitymiss', eventsgamemiss, 'ephysmiss', eventsgameopenmiss), ...
    { 'unitymiss', 'ephysmiss' }, ...
    struct( 'unity', 'unityTime', 'ephys', 'ephysTime' ), ...
    struct( 'delta', ...
      struct('timelabel', 'ephysTime', 'deltalabel', 'unityShift') ), ...
    4.0 );


  % Remove unmatched entries, if requested.

  if want_remove_unmatched
    gamecodes = gamecodes(gamematchmask,:);
    ephyscodes = ephyscodes(gameephysmatchmask,:);
  end

end



%
%
% Fifth step: Copy the canonical set of events, if we have one.

codesaligned = table();

if strcmp(code_source, 'ephys')
  codesaligned = ephyscodes;
elseif strcmp(code_source, 'synchbox')
  codesaligned = boxcodes;
elseif strcmp(code_source, 'unity')
  codesaligned = gamecodes;
else
  % This shouldn't happen; we'd have caught it the first time around.
  disp(sprintf( '### Unknown event code source "%s"; using ephys codes.', ...
    code_source ));
  code_source = 'ephys';
  codesaligned = ephyscodes;
end

% Complain if we didn't store anything.
if isempty(codesaligned)
  disp('###  Warning - No time-aligned events!');
end


%
% This is the end of the file.
