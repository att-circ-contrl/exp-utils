% Field Trip sample script / test script - Time alignment and trial defs.
% Written by Christopher Thomas.

% This reads Unity event data and TTL data, time-aligns them, and creates
% trial definitions for segmentation.
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
%   usedata_gaze


%
% == Raw data.

% We're either loading this from ephys/unity or loading a cached version.

fname_raw = [ datadir filesep 'alignraw.mat' ];


if want_cache_align_raw && isfile(fname_raw)

  %
  % Load raw data from disk.

  disp('-- Loading raw Unity and TTL events.');
  load(fname_raw);
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

    disp('-- Reading Unity event data.');

    [ sentdata recvdata ] = euUSE_readRawSerialData(thisdataset.unityfile);
    [ boxsynchA boxsynchB boxrwdA boxrwdB boxcodes_raw ] = ...
      euUSE_parseSerialRecvData(recvdata, 'dupbyte');
    [ gamerwdA gamerwdB gamecodes_raw ] = ...
      euUSE_parseSerialSentData(sentdata, 'dupbyte');

    evcodedefs = euUSE_readEventCodeDefs(thisdataset.unityfile);

    % Translate raw code bytes into cooked codes.
    [ boxcodes origlocations ] = euUSE_reassembleEventCodes( ...
      boxcodes_raw, evcodedefs, evcodebytes, evcodeendian, 'codeValue' );
    [ gamecodes origlocations ] = euUSE_reassembleEventCodes( ...
      gamecodes_raw, evcodedefs, evcodebytes, evcodeendian, 'codeValue' );

    disp('-- Finished reading Unity event data.');


    disp('-- Reading Unity gaze data.');

    % FIXME - This should be turned into waveform data. For now, keep it
    % as a not-quite-uniformly-sampled data table.
    % NOTE - This uses its own timestamps and time quantum, not unity's.
    % The loading function gives us a 'time_seconds' column.
    gamegaze_raw = euUSE_readRawGazeData(thisdataset.unityfile);

    disp('-- Finished reading Unity gaze data.');

  end


  %
  % Read TTL data from ephys recorders.


  % First, get the ephys TTL events themselves if we don't already have them.

  % NOTE - Field Trip will throw an exception if this fails. Wrap this to
  % catch exceptions.

  try

    disp('-- Reading ephys digital events.');

    if exist('have_recevents_dig', 'var') && have_recevents_dig
      disp('.. Already have events from the recorder.');
    else
      disp('.. Reading from recorder.');

      recevents_dig = ft_read_event( thisdataset.recfile, ...
        'headerformat', 'nlFT_readHeader', 'eventformat', 'nlFT_readEvents' );

      if isempty(recevents_dig)
        disp('.. No recorder events found. Trying again using waveforms.');
        recevents_dig = ft_read_event( thisdataset.recfile, ...
          'headerformat', 'nlFT_readHeader', ...
          'eventformat', 'nlFT_readEventsContinuous' );
      end

      have_recevents_dig = true;
    end

    if exist('have_stimevents_dig', 'var') && have_stimevents_dig
      disp('.. Already have events from the stimulator.');
    else
      disp('.. Reading from stimulator.');

      stimevents_dig = ft_read_event( thisdataset.stimfile, ...
        'headerformat', 'nlFT_readHeader', 'eventformat', 'nlFT_readEvents' );

      if isempty(stimevents_dig)
        disp('.. No stimulator events found. Trying again using waveforms.');
        stimevents_dig = ft_read_event( thisdataset.stimfile, ...
          'headerformat', 'nlFT_readHeader', ...
          'eventformat', 'nlFT_readEventsContinuous' );
      end

      have_stimevents_dig = true;
    end

    disp('-- Finished reading ephys digital events.');

  catch errordetails
    disp(sprintf( ...
      '###  Exception thrown while reading "%s".', thisdataset.title));
    disp(sprintf('Message: "%s"', errordetails.message));

    % Abort the script and send the user back to the Matlab prompt.
    error('Couldn''t read events; bailing out.');
  end


  % Finished loading raw data.


  %
  % Isolate the signals we're interested in.


  disp('-- Looking for SynchBox signals in ephys data.');

  synchboxsignals = struct();
  if isfield(thisdataset, 'synchbox')
    synchboxsignals = thisdataset.synchbox;
  end

  % FIXME - This only works for LoopUtil events.
  % Those events store the channel name as the event "type" field.


  % Recorder single-bit signals.

  [ recrwdA have_recrwdA ] = euFT_getSingleBitEvent( ...
    synchboxsignals, 'recrwdA', rechdr.label, recevents_dig );
  [ recrwdB have_recrwdB ] = euFT_getSingleBitEvent( ...
    synchboxsignals, 'recrwdB', rechdr.label, recevents_dig );
  [ recsynchA have_recsynchA ] = euFT_getSingleBitEvent( ...
    synchboxsignals, 'recsynchA', rechdr.label, recevents_dig );
  [ recsynchB have_recsynchB ] = euFT_getSingleBitEvent( ...
    synchboxsignals, 'recsynchB', rechdr.label, recevents_dig );

  % Keep only rising-edge events.
  if have_recrwdA
    recrwdA = recrwdA(recrwdA.value > 0,:);
  end
  if have_recrwdB
    recrwdB = recrwdB(recrwdB.value > 0,:);
  end
  if have_recsynchA
    recsynchA = recsynchA(recsynchA.value > 0,:);
  end
  if have_recsynchB
    recsynchB = recsynchB(recsynchB.value > 0,:);
  end


  % Stimulator single-bit signals.

  [ stimrwdA have_stimrwdA ] = euFT_getSingleBitEvent( ...
    synchboxsignals, 'stimrwdA', stimhdr.label, stimevents_dig );
  [ stimrwdB have_stimrwdB ] = euFT_getSingleBitEvent( ...
    synchboxsignals, 'stimrwdB', stimhdr.label, stimevents_dig );
  [ stimsynchA have_stimsynchA ] = euFT_getSingleBitEvent( ...
    synchboxsignals, 'stimsynchA', stimhdr.label, stimevents_dig );
  [ stimsynchB have_stimsynchB ] = euFT_getSingleBitEvent( ...
    synchboxsignals, 'stimsynchB', stimhdr.label, stimevents_dig );

  % Keep only rising-edge events.
  if have_stimrwdA
    stimrwdA = stimrwdA(stimrwdA.value > 0,:);
  end
  if have_stimrwdB
    stimrwdB = stimrwdB(stimrwdB.value > 0,:);
  end
  if have_stimsynchA
    stimsynchA = stimsynchA(stimsynchA.value > 0,:);
  end
  if have_stimsynchB
    stimsynchB = stimsynchB(stimsynchB.value > 0,:);
  end


  % Event codes from both devices.

  % FIXME - We have to keep the raw event codes as well.
  % The alignment routines misbehave trying to line up the SynchBox with
  % the ephys machines based on cooked codes, due to a large number of
  % dropped bytes (the synchbox-to-unity reply link is saturated).

  % FIXME - The only situation where we have to assemble from bits is with
  % the Intan machine, and channel numbering starts at 1 in that situation.
  firstbit = 1;

  [ reccodes_raw have_reccodes ] = euFT_getCodeWordEvent( ...
    synchboxsignals, 'reccodes', 'reccodebits', firstbit, 'recshift', ...
    rechdr.label, recevents_dig );

  [ stimcodes_raw have_stimcodes ] = euFT_getCodeWordEvent( ...
    synchboxsignals, 'stimcodes', 'stimcodebits', firstbit, 'stimshift', ...
    stimhdr.label, stimevents_dig );


  % Squash event code values of zero; that's the idle state.
  % Merge codes that repeat the same timestamp or that are one sample apart.
  % These use the FT event column labels ("sample", "value", "type",
  % "offset", "duration").
  reccodes_raw = euUSE_cleanEventsTabular( reccodes_raw, 'value', 'sample' );
  stimcodes_raw = euUSE_cleanEventsTabular( stimcodes_raw, 'value', 'sample' );


  % Translate raw code bytes into cooked codes.
  if ~have_unity
    disp( ...
      '###  Can''t reassemble event codes without USE''s code definitions!');
  else
    [ reccodes origlocations ] = euUSE_reassembleEventCodes( ...
      reccodes_raw, evcodedefs, evcodebytes, evcodeendian, 'value' );
    [ stimcodes origlocations ] = euUSE_reassembleEventCodes( ...
      stimcodes_raw, evcodedefs, evcodebytes, evcodeendian, 'value' );
  end

  % Done.

  disp('-- Finished looking for SynchBox signals in ephys data.');


  %
  % Save the results to disk, if requested.

  if want_save_data
    if isfile(fname_raw)
      delete(fname_raw);
    end

    disp('-- Saving raw Unity and TTL event data.');

    save( fname_raw, ...
      'have_unity', 'evcodedefs', ...
      'boxsynchA', 'boxsynchB', 'boxrwdA', 'boxrwdB', ...
      'boxcodes', 'boxcodes_raw', ...
      'gamerwdA', 'gamerwdB', 'gamecodes', 'gamecodes_raw', ...
      'have_recevents_dig', 'recevents_dig', ...
      'have_stimevents_dig', 'stimevents_dig', ...
      'have_recrwdA', 'recrwdA', 'have_recrwdB', 'recrwdB', ...
      'have_recsynchA', 'recsynchA', 'have_recsynchB', 'recsynchB', ...
      'have_reccodes', 'reccodes', 'reccodes_raw', ...
      'have_stimrwdA', 'stimrwdA', 'have_stimrwdB', 'stimrwdB', ...
      'have_stimsynchA', 'stimsynchA', 'have_stimsynchB', 'stimsynchB', ...
      'have_stimcodes', 'stimcodes', 'stimcodes_raw', ...
      'gamegaze_raw' );

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
    end

  else
    disp('-- Not enough information to align the recorder with Unity.');
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
% Propagate recorder timestamps to the SynchBox.

% Recorder and synchbox timestamps do drift but can be aligned to about 0.1ms
% precision locally (using raw, not cooked, event codes).

% Do alignment using event codes if possible. Failing that, using reward
% lines. We can't usefully align based on periodic synch signals.
% FIXME - Reward line alignment will take much longer due to not being able
% to filter based on data values.


% NOTE - Event code alignment with the SynchBox has to use raw codes.
% The alignment routines misbehave trying to line up the SynchBox with
% the ephys machines based on cooked codes, due to a large number of
% dropped bytes (the synchbox-to-unity reply link is saturated).

% NOTE - We can fall back to reward alignment but not synch pulse alignment.
% The synch pulses are at regular intervals, so alignment is ambiguous.

times_recorder_synchbox = table();

if (~isempty(reccodes_raw)) && (~isempty(boxcodes_raw))
  disp('.. Aligning SynchBox and recorder using event codes.');

  [ boxcodes_raw, reccodes_raw, boxmatchmask, recmatchmask, ...
    times_recorder_synchbox ] = ...
    evCodes_alignTables( boxcodes_raw, reccodes_raw, ...
      'synchBoxTime', 'recTime', 'codeValue', 'value', ...
      aligncoarsewindows, alignmedwindows, alignfinewindow, ...
      alignoutliersigma, alignverbosity );

  disp('.. Finished aligning.');
elseif (~isempty(recrwdA)) && (~isempty(boxrwdA))
  disp('.. Aligning SynchBox and recorder using Reward A.');

  [ boxrwdA, recrwdA, boxmatchmask, recmatchmask, ...
    times_recorder_synchbox ] = ...
    evCodes_alignTables( boxrwdA, recrwdA, ...
      'synchBoxTime', 'recTime', '', '', ...
      aligncoarsewindows, alignmedwindows, alignfinewindow, ...
      alignoutliersigma, alignverbosity );

  disp('.. Finished aligning.');
elseif (~isempty(recrwdB)) && (~isempty(boxrwdB))
  disp('.. Aligning SynchBox and recorder using Reward B.');

  [ boxrwdB, recrwdB, boxmatchmask, recmatchmask, ...
    times_recorder_synchbox ] = ...
    evCodes_alignTables( boxrwdB, recrwdB, ...
      'synchBoxTime', 'recTime', '', '', ...
      aligncoarsewindows, alignmedwindows, alignfinewindow, ...
      alignoutliersigma, alignverbosity );

  disp('.. Finished aligning.');
else
  disp('###  Not enough information to align recorder and SynchBox!');
end


% If we've aligned the recorder and synchbox, augment all synchbox data
% that doesn't already have recorder timestamps with recorder timestamps.

if ~isempty(times_recorder_synchbox)

  % This checks for cases where translation can't be done or where the
  % new timestamps are already present.

  boxcodes_raw = evCodes_addTimesToTable( boxcodes_raw, ...
    'synchBoxTime', 'recTime', times_recorder_synchbox );

  boxcodes = evCodes_addTimesToTable( boxcodes, ...
    'synchBoxTime', 'recTime', times_recorder_synchbox );

  boxrwdA = evCodes_addTimesToTable( boxrwdA, ...
    'synchBoxTime', 'recTime', times_recorder_synchbox );

  boxrwdB = evCodes_addTimesToTable( boxrwdB, ...
    'synchBoxTime', 'recTime', times_recorder_synchbox );

  boxsynchA = evCodes_addTimesToTable( boxsynchA, ...
    'synchBoxTime', 'recTime', times_recorder_synchbox );

  boxsynchB = evCodes_addTimesToTable( boxsynchB, ...
    'synchBoxTime', 'recTime', times_recorder_synchbox );

end



%
% Propagate recorder timestamps to USE.

% Unity timestamps have a lot more jitter (about 1.0 to 1.5 ms total).

% Do alignment using event codes if possible. Failing that, using reward
% lines.
% FIXME - Reward line alignment will take much longer due to not being able
% to filter based on data values.

% NOTE - USE's record of event codes is complete, so we can align on cooked
% codes without problems.

times_recorder_game = table();

if (~isempty(reccodes)) && (~isempty(gamecodes))
  disp('.. Aligning USE and recorder using event codes.');

  [ gamecodes, reccodes, gamematchmask, recmatchmask, ...
    times_recorder_game ] = ...
    evCodes_alignTables( gamecodes, reccodes, ...
      'unityTime', 'recTime', 'codeWord', 'codeWord', ...
      aligncoarsewindows, alignmedwindows, alignfinewindow, ...
      alignoutliersigma, alignverbosity );

  disp('.. Finished aligning.');
elseif (~isempty(recrwdA)) && (~isempty(gamerwdA))
  disp('.. Aligning USE and recorder using Reward A.');

  [ gamerwdA, recrwdA, gamematchmask, recmatchmask, ...
    times_recorder_game ] = ...
    evCodes_alignTables( gamerwdA, recrwdA, ...
      'unityTime', 'recTime', '', '', ...
      aligncoarsewindows, alignmedwindows, alignfinewindow, ...
      alignoutliersigma, alignverbosity );

  disp('.. Finished aligning.');
elseif (~isempty(recrwdB)) && (~isempty(gamerwdB))
  disp('.. Aligning USE and recorder using Reward B.');

  [ gamerwdB, recrwdB, gamematchmask, recmatchmask, ...
    times_recorder_game ] = ...
    evCodes_alignTables( gamerwdB, recrwdB, ...
      'unityTime', 'recTime', '', '', ...
      aligncoarsewindows, alignmedwindows, alignfinewindow, ...
      alignoutliersigma, alignverbosity );

  disp('.. Finished aligning.');
else
  disp('###  Not enough information to align recorder and USE!');
end


% If we've aligned the recorder and USE, augment all game data that doesn't
% already have recorder timestamps with recorder timestamps.

if ~isempty(times_recorder_game)

  % This checks for cases where translation can't be done or where the
  % new timestamps are already present.

  gamecodes_raw = evCodes_addTimesToTable( gamecodes_raw, ...
    'unityTime', 'recTime', times_recorder_game );

  gamecodes = evCodes_addTimesToTable( gamecodes, ...
    'unityTime', 'recTime', times_recorder_game );

  gamerwdA = evCodes_addTimesToTable( gamerwdA, ...
    'unityTime', 'recTime', times_recorder_game );

  gamerwdB = evCodes_addTimesToTable( gamerwdB, ...
    'unityTime', 'recTime', times_recorder_game );

end



% FIXME - NYI. Stopped here.



%
% This is the end of the file.
