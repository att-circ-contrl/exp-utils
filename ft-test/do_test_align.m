% Field Trip sample script / test script - Time alignment.
% Written by Christopher Thomas.

% This reads Unity event data and TTL data and time-aligns them.
% FIXME - Doing this by reading and setting workspace variables directly.
%
% Variables that get set:
%   have_unity
%   evcodedefs
%   boxsynchA
%   boxsynchB
%   boxrwdA
%   boxrwdB
%   boxcodes
%   boxcodes_raw
%   gamerwdA
%   gamerwdB
%   gamecodes
%   gamecodes_raw
%   have_recevents_dig
%   have_stimevents_dig
%   recevents_dig
%   stimevents_dig
%   have_recrwdA
%   have_recrwdB
%   have_recsynchA
%   have_recsynchB
%   have_reccodes
%   recrwdA
%   recrwdB
%   recsynchA
%   recsynchB
%   reccodes
%   reccodes_raw
%   have_stimrwdA
%   have_stimrwdB
%   have_stimsynchA
%   have_stimsynchB
%   have_stimcodes
%   stimrwdA
%   stimrwdB
%   stimsynchA
%   stimsynchB
%   stimcodes
%   gamegaze_raw
%   gameframedata_raw
%   times_recorder_synchbox
%   times_recorder_game
%   times_recorder_stimulator
%   times_game_eyetracker
%   times_recorder_eyetracker
%   unityreftime


%
% == Raw data.

% We're either loading this from ephys/unity or loading a cached version.

fname_rawttl = [ datadir filesep 'ttl_raw.mat' ];
fname_rawevents = [ datadir filesep 'events_raw.mat' ];
fname_rawgaze = [ datadir filesep 'gaze_raw.mat' ];
fname_rawframe = [ datadir filesep 'frame_raw.mat' ];


if want_cache_align_raw ...
  && isfile(fname_rawttl) && isfile(fname_rawevents) ...
  && isfile(fname_rawgaze) && isfile(fname_rawframe)

  %
  % Load raw data from disk.

  disp('-- Loading raw TTL events.');

  load(fname_rawttl);

  disp('-- Unpacking raw TTL events.');

  recevents_dig = struct([]);
  if have_recevents_dig
    recevents_dig = ...
      nlFT_uncompressFTEvents( recevents_dig_tab, rechdr.label );
  end
  stimevents_dig = struct([]);
  if have_stimevents_dig
    stimevents_dig = ...
      nlFT_uncompressFTEvents( stimevents_dig_tab, stimhdr.label );
  end

  disp('-- Loading raw Unity events.');

  load(fname_rawevents);

  disp('-- Loading raw Unity gaze data.');

  if debug_skip_gaze
    disp('### Skipping loading gaze data.');
    gamegaze_raw = table();
  else
    load(fname_rawgaze);
  end

  disp('-- Loading raw Unity frame data.');

  if debug_skip_frame
    disp('### Skipping loading frame data.');
    gameframedata_raw = table();
  else
    load(fname_rawframe);
  end

  disp('-- Finished loading.');

else

  %
  % Load raw data from ephys and unity folders.


  %
  % Read TTL and gaze data from Unity.

  % FIXME - These should use Field Trip wrappers!

  % FIXME - We have to keep the raw event codes as well.
  % The alignment routines misbehave trying to line up the SynchBox with
  % the ephys machines based on cooked codes, due to a large number of
  % dropped bytes (the synchbox-to-unity reply link is saturated).

  have_unity = false;
  if isfield( thisdataset, 'unityfile' )

    have_unity = true;

    %
    % Read event data.

    % Baseline version: Manually specify how event codes are encoded.
    [ boxevents gameevents evcodedefs ] = euUSE_readAllUSEEvents( ...
      thisdataset.unityfile, 'dupbyte', evcodebytes, evcodeendian );

    % Alternate version: Use default encoding.
%    [ boxevents gameevents evcodedefs ] = ...
%      euUSE_readAllUSEEvents( thisdataset.unityfile );

    % Unpack the returned structures into our global variables.

    boxsynchA = boxevents.synchA;
    boxsynchB = boxevents.synchB;
    boxrwdA = boxevents.rwdA;
    boxrwdB = boxevents.rwdB;
    boxcodes_raw = boxevents.rawcodes;
    boxcodes = boxevents.cookedcodes;;

    gamerwdA = gameevents.rwdA;
    gamerwdB = gameevents.rwdB;
    gamecodes_raw = gameevents.rawcodes;
    gamecodes = gameevents.cookedcodes;


    %
    % Read gaze and frame data.

    % These take a while.

    disp('-- Reading USE gaze data.');

    % FIXME - The raw data is nonuniformly sampled. This should be converted
    % to FT waveform data at some point.

    if debug_skip_gaze
      disp('### Skipping reading gaze data.');
      gamegaze_raw = table();
    else
      gamegaze_raw = euUSE_readRawGazeData( thisdataset.unityfile );
    end

    disp('-- Finished reading USE gaze data.');

    disp('-- Reading USE frame data.');

    if debug_skip_frame
      disp('### Skipping reading frame data.');
      gameframedata_raw = table();
    else
      gameframedata_raw = euUSE_readRawFrameData( thisdataset.unityfile );
    end

    disp('-- Finished reading USE frame data.');


  end


  %
  % Read TTL data from ephys recorders.


  % FIXME - The only situation where we have to assemble from bits is with
  % the Intan machine, and channel numbering starts at 1 in that situation.
  firstbit = 1;


  % FIXME - Kludge the old signal definition structure into new structures.

  synchboxsignals = struct();
  if isfield(thisdataset, 'synchbox')
    synchboxsignals = thisdataset.synchbox;
  end

  recbitsignals = { 'recsynchA', 'recsynchB', 'recrwdA', 'recrwdB' };
  bitsignaldefsrec = struct();
  for fidx = 1:length(recbitsignals)
    thisfield = recbitsignals{fidx};
    if isfield(synchboxsignals, thisfield)
      bitsignaldefsrec.(thisfield) = synchboxsignals.(thisfield);
    end
  end

  stimbitsignals = { 'stimsynchA', 'stimsynchB', 'stimrwdA', 'stimrwdB' };
  bitsignaldefsstim = struct();
  for fidx = 1:length(stimbitsignals)
    thisfield = stimbitsignals{fidx};
    if isfield(synchboxsignals, thisfield)
      bitsignaldefsstim.(thisfield) = synchboxsignals.(thisfield);
    end
  end

  codesignaldefsrec = struct();
  if isfield(synchboxsignals, 'reccodes')
    codesignaldefsrec = struct( ...
      'signameraw', 'reccodes_raw', 'signamecooked', 'reccodes', ...
      'channame', synchboxsignals.reccodes );
    % FIXME - If we're reading words (open ephys), the first bit is 0. Keep
    % the shift as-is. If we're reading bits (intan), add 1.
    if isfield(synchboxsignals, 'recshift')
      codesignaldefsrec.bitshift = synchboxsignals.recshift;
    elseif (firstbit > 0)
      codesignaldefsrec.bitshift = firstbit;
    end
  end

  codesignaldefsstim = struct();
  if isfield(synchboxsignals, 'stimcodes')
    codesignaldefsstim = struct( ...
      'signameraw', 'stimcodes_raw', 'signamecooked', 'stimcodes', ...
      'channame', synchboxsignals.stimcodes );
    % FIXME - If we're reading words (open ephys), the first bit is 0. Keep
    % the shift as-is. If we're reading bits (intan), add 1.
    if isfield(synchboxsignals, 'stimshift')
      codesignaldefsstim.bitshift = synchboxsignals.stimshift;
    elseif (firstbit > 0)
      codesignaldefsstim.bitshift = firstbit;
    end
  end


  % Read the events.

  [recevents_dig recevents_packed] = euUSE_readAllEphysEvents( ...
    thisdataset.recfile, bitsignaldefsrec, codesignaldefsrec, ...
    evcodedefs, evcodebytes, evcodeendian );

  [stimevents_dig stimevents_packed] = euUSE_readAllEphysEvents( ...
    thisdataset.stimfile, bitsignaldefsstim, codesignaldefsstim, ...
    evcodedefs, evcodebytes, evcodeendian );

  have_recevents_dig = ~isempty(recevents_dig);
  have_stimevents_dig = ~isempty(stimevents_dig);


  % Unpack the events.

  % FIXME - "Save" expects empty tables for missing events.
  recrwdA = table();
  recrwdB = table();
  recsynchA = table();
  recsynchB = table();
  reccodes_raw = table();
  reccodes = table();

  have_recrwdA = isfield(recevents_packed, 'recrwdA');
  have_recrwdB = isfield(recevents_packed, 'recrwdB');
  have_recsynchA = isfield(recevents_packed, 'recsynchA');
  have_recsynchB = isfield(recevents_packed, 'recsynchB');
  have_reccodes = isfield(recevents_packed, 'reccodes');

  if have_recrwdA
    recrwdA = recevents_packed.recrwdA;
  end
  if have_recrwdB
    recrwdB = recevents_packed.recrwdB;
  end
  if have_recsynchA
    recsynchA = recevents_packed.recsynchA;
  end
  if have_recsynchB
    recsynchB = recevents_packed.recsynchB;
  end
  if have_reccodes
    reccodes_raw = recevents_packed.reccodes_raw;
    reccodes = recevents_packed.reccodes;
  end

  % FIXME - "Save" expects empty tables for missing events.
  stimrwdA = table();
  stimrwdB = table();
  stimsynchA = table();
  stimsynchB = table();
  stimcodes_raw = table();
  stimcodes = table();

  have_stimrwdA = isfield(stimevents_packed, 'stimrwdA');
  have_stimrwdB = isfield(stimevents_packed, 'stimrwdB');
  have_stimsynchA = isfield(stimevents_packed, 'stimsynchA');
  have_stimsynchB = isfield(stimevents_packed, 'stimsynchB');
  have_stimcodes = isfield(stimevents_packed, 'stimcodes');

  if have_stimrwdA
    stimrwdA = stimevents_packed.stimrwdA;
  end
  if have_stimrwdB
    stimrwdB = stimevents_packed.stimrwdB;
  end
  if have_stimsynchA
    stimsynchA = stimevents_packed.stimsynchA;
  end
  if have_stimsynchB
    stimsynchB = stimevents_packed.stimsynchB;
  end
  if have_stimcodes
    stimcodes_raw = stimevents_packed.stimcodes_raw;
    stimcodes = stimevents_packed.stimcodes;
  end


  %
  % Save the results to disk, if requested.

  if want_save_data
    if isfile(fname_rawttl)    ; delete(fname_rawttl)    ; end
    if isfile(fname_rawevents) ; delete(fname_rawevents) ; end
    if isfile(fname_rawgaze)   ; delete(fname_rawgaze)   ; end
    if isfile(fname_rawframe ) ; delete(fname_rawframe)  ; end

    % NOTE - Saving TTL events in packed tabular form, as that's far smaller
    % than structure array form.

    disp('-- Compressing raw TTL events.');

    recevents_dig_tab = table();
    if have_recevents_dig
      [ recevents_dig_tab scratchlut ] = ...
        nlFT_compressFTEvents( recevents_dig, rechdr.label );
    end
    stimevents_dig_tab = table();
    if have_stimevents_dig
      [ stimevents_dig_tab scratchlut ] = ...
        nlFT_compressFTEvents( stimevents_dig, stimhdr.label );
    end

    disp('-- Saving raw TTL event data.');

    save( fname_rawttl, ...
      'have_recevents_dig', 'recevents_dig_tab', ...
      'have_stimevents_dig', 'stimevents_dig_tab', ...
      '-v7.3' );

    disp('-- Saving raw Unity event data.');

    save( fname_rawevents, ...
      'have_unity', 'evcodedefs', ...
      'boxsynchA', 'boxsynchB', 'boxrwdA', 'boxrwdB', ...
      'boxcodes', 'boxcodes_raw', ...
      'gamerwdA', 'gamerwdB', 'gamecodes', 'gamecodes_raw', ...
      'have_recrwdA', 'recrwdA', 'have_recrwdB', 'recrwdB', ...
      'have_recsynchA', 'recsynchA', 'have_recsynchB', 'recsynchB', ...
      'have_reccodes', 'reccodes', 'reccodes_raw', ...
      'have_stimrwdA', 'stimrwdA', 'have_stimrwdB', 'stimrwdB', ...
      'have_stimsynchA', 'stimsynchA', 'have_stimsynchB', 'stimsynchB', ...
      'have_stimcodes', 'stimcodes', 'stimcodes_raw', ...
      '-v7.3' );

    disp('-- Saving raw Unity gaze data.');

    if debug_skip_gaze
      disp('### Skipping saving gaze data.');
    else
      save( fname_rawgaze, 'gamegaze_raw', '-v7.3' );
    end

    disp('-- Saving raw Unity frame data.');

    if debug_skip_frame
      disp('### Skipping saving frame data.');
    else
       save( fname_rawframe, 'gameframedata_raw', '-v7.3' );
    end

    disp('-- Finished saving.');
  end

end



% FIXME - Diagnostics.

disp(sprintf( ...
'.. From SynchBox:  %d rwdA  %d rwdB  %d synchA  %d synchB  %d codes', ...
  height(boxrwdA), height(boxrwdB), ...
  height(boxsynchA), height(boxsynchB), height(boxcodes) ));
disp(sprintf( ...
  '.. From USE:  %d rwdA  %d rwdB  %d codes', ...
  height(gamerwdA), height(gamerwdB), height(gamecodes) ));

disp(sprintf( ...
  '.. From recorder:  %d rwdA  %d rwdB  %d synchA  %d synchB  %d codes', ...
  height(recrwdA), height(recrwdB), ...
  height(recsynchA), height(recsynchB), height(reccodes) ));
disp(sprintf( ...
  '.. From stimulator:  %d rwdA  %d rwdB  %d synchA  %d synchB  %d codes', ...
  height(stimrwdA), height(stimrwdB), ...
  height(stimsynchA), height(stimsynchB), height(stimcodes) ));



%
% == Time alignment.

% We're propagating recorder timestamps to all other devices and using these
% as our official set of timestamps.


%
% Check for cached data and return immediately if we find it.

fname_cookedevents = [ datadir filesep 'events_aligned.mat' ];
fname_cookedgaze = [ datadir filesep 'gaze_aligned.mat' ];
fname_cookedframe = [ datadir filesep 'frame_aligned.mat' ];

if want_cache_align_done && isfile(fname_cookedevents) ...
  && isfile(fname_cookedgaze) && isfile(fname_cookedframe)

  %
  % Load aligned data from disk.

  disp('-- Loading time-aligned Unity events and alignment tables.');

  load(fname_cookedevents);

  disp('-- Loading time-aligned gaze data.');

  load(fname_cookedgaze);

  disp('-- Loading time-aligned Unity frame data.');

  load(fname_cookedframe);

  disp('-- Finished loading.');

  % We've loaded cached results. Bail out of this portion of the script.
  return;

end


%
% If we don't have the information we need, bail out.

% We need USE and the recorder. Stimulator is optional.
% We need at least one data track in common between USE/recorder and (if
% present) USE/stimulator.

isok = false;

if ~have_unity
  disp('-- Can''t do time alignment without Unity data.');
elseif ~have_recevents_dig
  disp('-- Can''t do time alignment without recorder data.');
else
  % Make sure we have a common SynchBox/recorder pair.
  % FIXME - Not aligning on synchA/synchB. Misalignment is larger than the
  % synch pulse interval, so we'd get an ambiguous result.
  if ( (~isempty(gamecodes)) && (~isempty(reccodes)) ) ...
    || ( (~isempty(gamerwdA)) && (~isempty(recrwdA)) ) ...
    || ( (~isempty(gamerwdB)) && (~isempty(recrwdB)) )

    % We have enough information to align the recorder.
    % Check the stimulator if requested.

    if ~have_stimevents_dig
      % No stimulator; we're fine as-is.
      isok = true;
    elseif ( (~isempty(reccodes)) && (~isempty(stimcodes)) ) ...
      || ( (~isempty(recrwdA)) && (~isempty(stimrwdA)) ) ...
      || ( (~isempty(recrwdB)) && (~isempty(stimrwdB)) )
      % We have enough information to align the stimulator with the recorder.
      isok = true;
    elseif ( (~isempty(gamecodes)) && (~isempty(stimcodes)) ) ...
      || ( (~isempty(gamerwdA)) && (~isempty(stimrwdA)) ) ...
      || ( (~isempty(gamerwdB)) && (~isempty(stimrwdB)) )
      % We have enough information to align the stimulator with Unity.
      isok = true;
    else
      disp('-- Not enough information to align the stimulator.');

      if want_force_align
        disp('-- FIXME - Continuing anyways.');
        isok = true;
      end
    end

  else
    disp('-- Not enough information to align the recorder with Unity.');

    if want_force_align
      disp('-- FIXME - Continuing anyways.');
      isok = true;
    end
  end
end

if ~isok
  % End the script here if there was a problem.
  error('Couldn''t perform time alignment; bailing out.');
end



%
% Remove enormous offsets from the various time series.

% In practice, this is the Unity timestamps, which are relative to 1 Jan 1970.
% FIXME - Leaving synchbox, recorder, and stimulator, and gaze timestamps
% as-is. The offsets in these should be modest (hours at most).

% FIXME - Leaving "system timestamps" in frame and gaze data alone.
% We'll subtract the offset when resaving as "unityTime".


% Pick an arbitrary time reference. Negative offsets relative to it are fine.

unityreftime = 0;

if ~isempty(gamecodes)
  unityreftime = min(gamecodes.unityTime);
elseif ~isempty(gamerwdA)
  unityreftime = min(gamerwdA.unityTime);
elseif ~isempty(gamerwdB)
  unityreftime = min(gamerwdB.unityTime);
end

% Subtract the time offset.
% We have a "unityTime" column in the "gameXX" and "boxXX" tables.

if ~isempty(gamecodes)
  gamecodes.unityTime = gamecodes.unityTime - unityreftime;
end

if ~isempty(gamerwdA)
  gamerwdA.unityTime = gamerwdA.unityTime - unityreftime;
end
if ~isempty(gamerwdA)
  gamerwdB.unityTime = gamerwdB.unityTime - unityreftime;
end

if ~isempty(boxcodes)
  boxcodes.unityTime = boxcodes.unityTime - unityreftime;
end

if ~isempty(boxrwdA)
  boxrwdA.unityTime = boxrwdA.unityTime - unityreftime;
end
if ~isempty(boxrwdA)
  boxrwdB.unityTime = boxrwdB.unityTime - unityreftime;
end

if ~isempty(boxsynchA)
  boxsynchA.unityTime = boxsynchA.unityTime - unityreftime;
end
if ~isempty(boxsynchA)
  boxsynchB.unityTime = boxsynchB.unityTime - unityreftime;
end



%
% Augment everything that doesn't have a time in seconds with time in seconds.

% Recorder tables get "recTime", stimulator tables get "stimTime".


if ~isempty(recrwdA)
  recrwdA.recTime = recrwdA.sample / rechdr.Fs;
end
if ~isempty(recrwdB)
  recrwdB.recTime = recrwdB.sample / rechdr.Fs;
end

if ~isempty(recsynchA)
  recsynchA.recTime = recsynchA.sample / rechdr.Fs;
end
if ~isempty(recsynchB)
  recsynchB.recTime = recsynchB.sample / rechdr.Fs;
end

if ~isempty(reccodes)
  reccodes.recTime = reccodes.sample / rechdr.Fs;
end
if ~isempty(reccodes_raw)
  reccodes_raw.recTime = reccodes_raw.sample / rechdr.Fs;
end


if ~isempty(stimrwdA)
  stimrwdA.stimTime = stimrwdA.sample / stimhdr.Fs;
end
if ~isempty(stimrwdB)
  stimrwdB.stimTime = stimrwdB.sample / stimhdr.Fs;
end

if ~isempty(stimsynchA)
  stimsynchA.stimTime = stimsynchA.sample / stimhdr.Fs;
end
if ~isempty(stimsynchB)
  stimsynchB.stimTime = stimsynchB.sample / stimhdr.Fs;
end

if ~isempty(stimcodes)
  stimcodes.stimTime = stimcodes.sample / stimhdr.Fs;
end
if ~isempty(stimcodes_raw)
  stimcodes_raw.stimTime = stimcodes_raw.sample / stimhdr.Fs;
end


%
% Configuration for time alignment.

% Values from do_test_config.m.
alignconfig = struct( 'coarsewindows', aligncoarsewindows, ...
  'medwindows', alignmedwindows, 'finewindow', alignfinewindow, ...
  'outliersigma', alignoutliersigma, 'verbosity', alignverbosity );

% Defaults.
%alignconfig = struct();


%
% Propagate recorder timestamps to the SynchBox.

% Recorder and synchbox timestamps do drift but can be aligned to about 0.1ms
% precision locally (using raw, not cooked, event codes).

% Do alignment using event codes if possible. Failing that, using reward
% lines. We can't usefully align based on periodic synch signals.
% FIXME - Reward line alignment will take much longer due to not being able
% to filter based on data values.

% NOTE - We can fall back to reward alignment but not synch pulse alignment.
% The synch pulses are at regular intervals, so alignment is ambiguous.

% NOTE - Event code alignment with the SynchBox has to use raw codes.
% The alignment routines misbehave trying to line up the SynchBox with
% the ephys machines based on cooked codes, due to a large number of
% dropped bytes (the synchbox-to-unity reply link is saturated).

disp('.. Aligning SynchBox and recorder.');

% Pack the event tables. These may be empty.
eventtables = ...
  { reccodes_raw, boxcodes_raw ; recrwdA, boxrwdA ; recrwdB, boxrwdB };

% Do the alignment.
[ alignedevents times_recorder_synchbox ] = euUSE_alignTwoDevices( ...
  eventtables, 'recTime', 'synchBoxTime', alignconfig );

% Unpack the augmented event tables.
reccodes_raw = alignedevents{1,1};
recrwdA = alignedevents{2,1};
recrwdB = alignedevents{3,1};
boxcodes_raw = alignedevents{1,2};
boxrwdA = alignedevents{2,2};
boxrwdB = alignedevents{3,2};

% Propagate recorder timestamps to boxcodes, boxsynchA, and boxsynchB.
% NOTE - Not propagating box timestamps to recorder synch or cooked codes!
if ~isempty(times_recorder_synchbox)
  % This checks for cases where translation can't be done or where the
  % new timestamps are already present.

  boxcodes = euAlign_addTimesToTable( boxcodes, ...
    'synchBoxTime', 'recTime', times_recorder_synchbox );

  boxsynchA = euAlign_addTimesToTable( boxsynchA, ...
    'synchBoxTime', 'recTime', times_recorder_synchbox );

  boxsynchB = euAlign_addTimesToTable( boxsynchB, ...
    'synchBoxTime', 'recTime', times_recorder_synchbox );
end

disp('.. Finished aligning.');


%
% Propagate recorder timestamps to USE.

% Unity timestamps have a lot more jitter (about 1.0 to 1.5 ms total).

% Do alignment using event codes if possible. Failing that, using reward
% lines.
% FIXME - Reward line alignment will take much longer due to not being able
% to filter based on data values.

% NOTE - USE's record of event codes is complete, so we can align on cooked
% codes without problems.

disp('.. Aligning USE and recorder.');

% Pack the event tables. These may be empty.
eventtables = ...
  { reccodes, gamecodes ; recrwdA, gamerwdA ; recrwdB, gamerwdB };

% Do the alignment.
[ alignedevents times_recorder_game ] = euUSE_alignTwoDevices( ...
  eventtables, 'recTime', 'unityTime', alignconfig );

% Unpack the augmented event tables.
reccodes = alignedevents{1,1};
recrwdA = alignedevents{2,1};
recrwdB = alignedevents{3,1};
gamecodes = alignedevents{1,2};
gamerwdA = alignedevents{2,2};
gamerwdB = alignedevents{3,2};

% Propagate recorder timestamps to gamecodes_raw.
% NOTE - Not propagating game timestamps to recorder synch or raw codes!
if ~isempty(times_recorder_game)
  % This checks for cases where translation can't be done or where the
  % new timestamps are already present.
  gamecodes_raw = euAlign_addTimesToTable( gamecodes_raw, ...
    'unityTime', 'recTime', times_recorder_game );
end

disp('.. Finished aligning.');


%
% Propagate recorder timestamps to the stimulator.

% If we can do this directly, that's ideal. Otherwise go through the SynchBox.
% Case priority order is direct codes, synchbox codes, direct reward, then
% synchbox reward. We can't usefully align based on periodic synch signals.

% FIXME - Reward line alignment will take much longer due to not being able
% to filter based on data values.

% NOTE - SynchBox codes are incomplete, so we need to use raw rather than
% cooked for it to avoid larger disturbances from dropped codes.

disp('.. Aligning stimulator and recorder.');

% Pack the event tables. These may be empty.
% "box" tables are already augmented with recTime.
eventtables = ...
  { reccodes, stimcodes ; boxcodes_raw, stimcodes_raw ; ...
    recrwdA, stimrwdA ; recrwdB, stimrwdB ; ...
    boxrwdA, stimrwdA ; boxrwdB, stimrwdB };

% Do the alignment.
[ alignedevents times_recorder_stimulator ] = euUSE_alignTwoDevices( ...
  eventtables, 'recTime', 'stimTime', alignconfig );

% Unpack the augmented event tables.
% The two versions of "stimrwdA" and "stimrwdB" should be identical;
% we'll just take the first ones.
reccodes = alignedevents{1,1};
boxcodes_raw = alignedevents{2,1};
recrwdA = alignedevents{3,1};
recrwdB = alignedevents{4,1};
recrwdA = alignedevents{5,1};
recrwdB = alignedevents{6,1};
stimcodes = alignedevents{1,2};
stimcodes_raw = alignedevents{2,2};
stimrwdA = alignedevents{3,2};
stimrwdB = alignedevents{4,2};
% {5,2} and {6,2} are duplicates of stimrwdA and stimrwdB, respectively.

% Propagate recorder timestamps to stimsynchA and stimsynchB.
% NOTE - Not propagating stimulator timestamps to recorder synch!
if ~isempty(times_recorder_stimulator)
  % This checks for cases where translation can't be done or where the
  % new timestamps are already present.

  stimsynchA = euAlign_addTimesToTable( stimsynchA, ...
    'stimTime', 'recTime', times_recorder_stimulator );

  stimsynchB = euAlign_addTimesToTable( stimsynchB, ...
    'stimTime', 'recTime', times_recorder_stimulator );
end

disp('.. Finished aligning.');


%
% Time-align gaze data and frame data if possible.


% Align USE timestamps with eye-tracker timestamps.
% The "frame data" table has this information already; we just have to pick
% the subset of points that actually correspond.

times_game_eyetracker = table();

if ~isempty(gameframedata_raw)
  disp('.. Aligning USE and eye-tracker using FrameData table.');

  % We have two columns: "SystemTimeSeconds" and "EyetrackerTimeSeconds".
  % System timestamps (Unity) are unique; ET timestamps aren't.
  % Pick the smallest system timestamp for each ET timestamp.

  systimes_raw = gameframedata_raw.SystemTimeSeconds;
  eyetimes_raw = gameframedata_raw.EyetrackerTimeSeconds;

  eyetimes = unique(eyetimes_raw);

  systimes = [];
  for eidx = 1:length(eyetimes)
    thistime = eyetimes(eidx);
    thissys = systimes_raw(eyetimes_raw == thistime);
    systimes(eidx) = min(thissys);
  end

  if ~iscolumn(systimes)
    systimes = transpose(systimes);
  end
  if ~iscolumn(eyetimes)
    eyetimes = transpose(eyetimes);
  end

  times_game_eyetracker.unityTime = systimes;
  times_game_eyetracker.eyeTime = eyetimes;
end

if isempty(times_game_eyetracker)
  disp('###  Not enough information to align eye-tracker!');
else
  disp('.. Finished aligning.');
end


% Propagate relevant time fields to the GazeData and FrameData tables.

if ~isempty(gameframedata_raw)

  disp( ...
'.. Augmenting FrameData with recorder and interpolated gaze timestamps.' );

  % Save copies of timestamp columns with our standard names.
  % Interpolate timestamps for the ET data saved with successive Unity times.

  % NOTE - Remember to subtract the enormous offset from the Unity timestamp!

  gameframedata_raw.unityTime = ...
    gameframedata_raw.SystemTimeSeconds - unityreftime;

  % Interpolate gaze timestamps.
  % We should always have this alignment table if we have gameframedata_raw.
  if ~isempty(times_game_eyetracker)
    gameframedata_raw = euAlign_addTimesToTable( gameframedata_raw, ...
      'unityTime', 'eyeTime', times_game_eyetracker );
  end

  % Augment with the recorder timestamp.
  if ~isempty(times_recorder_game)
    gameframedata_raw = euAlign_addTimesToTable( gameframedata_raw, ...
      'unityTime', 'recTime', times_recorder_game );
  end

  disp('.. Finished augmenting.');

end

if ~isempty(gamegaze_raw)

  disp('.. Augmenting GazeData with recorder and USE timestamps.');

  % Save a renamed copy of the ET timestamp.
  gamegaze_raw.eyeTime = gamegaze_raw.time_seconds;

  % Augment with USE time if we have a translation table for that.
  % If we can get USE timestamps, augment with recorder timestamps if we
  % have a table for _that_.

  if ~isempty(times_game_eyetracker)
    gamegaze_raw = euAlign_addTimesToTable( gamegaze_raw, ...
      'eyeTime', 'unityTime', times_game_eyetracker );

    if ~isempty(times_recorder_game)
      gamegaze_raw = euAlign_addTimesToTable( gamegaze_raw, ...
        'unityTime', 'recTime', times_recorder_game );
    end
  end

  disp('.. Finished augmenting.');

end


% Build a direct mapping table from ET timestamps to recorder timestamps.

times_recorder_eyetracker = table();

if (~isempty(times_game_eyetracker)) && (~isempty(times_recorder_game))
  times_scratch = times_game_eyetracker;
  times_scratch = euAlign_addTimesToTable( times_scratch, ...
    'unityTime', 'recTime', times_recorder_game );

  times_recorder_eyetracker.recTime = times_scratch.recTime;
  times_recorder_eyetracker.eyeTime = times_scratch.eyeTime;
end



%
% Save the results to disk, if requested.

if want_save_data
  if isfile(fname_cookedevents) ; delete(fname_cookedevents) ; end
  if isfile(fname_cookedgaze)   ; delete(fname_cookedgaze)   ; end
  if isfile(fname_cookedframe)  ; delete(fname_cookedframe)  ; end

  disp('-- Saving time-aligned Unity events and alignment tables.');

  % NOTE - Only save the tables we annotated, and selected metadata.
  % In particular recevents_dig and stimevents_dig are huge and raw TTL.
  % There's no further need for them and they're alreadys saved as raw data.

  save( fname_cookedevents, ...
    'have_unity', 'evcodedefs', ...
    'boxsynchA', 'boxsynchB', 'boxrwdA', 'boxrwdB', ...
    'boxcodes', 'boxcodes_raw', ...
    'gamerwdA', 'gamerwdB', 'gamecodes', 'gamecodes_raw', ...
    'have_recrwdA', 'recrwdA', 'have_recrwdB', 'recrwdB', ...
    'have_recsynchA', 'recsynchA', 'have_recsynchB', 'recsynchB', ...
    'have_reccodes', 'reccodes', 'reccodes_raw', ...
    'have_stimrwdA', 'stimrwdA', 'have_stimrwdB', 'stimrwdB', ...
    'have_stimsynchA', 'stimsynchA', 'have_stimsynchB', 'stimsynchB', ...
    'have_stimcodes', 'stimcodes', 'stimcodes_raw', ...
    'times_recorder_synchbox', 'times_recorder_game', ...
    'times_recorder_stimulator', 'times_game_eyetracker', ...
    'times_recorder_eyetracker', 'unityreftime', ...
    '-v7.3' );

  disp('-- Saving time-aligned gaze data.');

  if debug_skip_gaze
    disp('### Skipping saving gaze data.');
  else
    save( fname_cookedgaze, 'gamegaze_raw', '-v7.3' );
  end

  disp('-- Saving time-aligned Unity frame data.');

  if debug_skip_frame
    disp('### Skipping saving frame data.');
  else
    save( fname_cookedframe, 'gameframedata_raw', '-v7.3' );
  end

  disp('-- Finished saving.');
end



%
% This is the end of the file.
