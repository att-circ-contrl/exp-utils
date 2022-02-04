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
%   gamerwdA
%   gamerwdB
%   gamecodes
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


%
% Read TTL data from Unity.

% FIXME - This should use a Field Trip wrapper!

have_unity = false;
if isfield( thisdataset, 'unityfile' )

  have_unity = true;

  disp('-- Reading Unity data.');

  [ sentdata recvdata ] = euUSE_readRawSerialData(thisdataset.unityfile);
  [ boxsynchA boxsynchB boxrwdA boxrwdB boxcodes ] = ...
    euUSE_parseSerialRecvData(recvdata, 'dupbyte');
  [ gamerwdA gamerwdB gamecodes ] = ...
    euUSE_parseSerialSentData(sentdata, 'dupbyte');

  evcodedefs = euUSE_readEventCodeDefs(thisdataset.unityfile);

  % Translate raw code bytes into cooked codes.
  [ boxcodes origlocations ] = euUSE_reassembleEventCodes( ...
    boxcodes, evcodedefs, evcodebytes, evcodeendian, 'codeValue' );
  [ gamecodes origlocations ] = euUSE_reassembleEventCodes( ...
    gamecodes, evcodedefs, evcodebytes, evcodeendian, 'codeValue' );

  % FIXME - Ignoring eye-tracker data for now.

  % FIXME - Diagnostics.
  disp(sprintf( ...
    '.. From SynchBox:  %d rwdA  %d rwdB  %d synchA  %d synchB  %d codes', ...
    height(boxrwdA), height(boxrwdB), ...
    height(boxsynchA), height(boxsynchB), height(boxcodes) ));
  disp(sprintf( ...
    '.. From USE:  %d rwdA  %d rwdB  %d codes', ...
    height(gamerwdA), height(gamerwdB), height(gamecodes) ));

  disp('-- Finished reading Unity data.');

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


% Set up to isolate the signals we're interested in.

have_recrwdA = false;
have_recrwdB = false;
have_recsynchA = false;
have_recsynchB = false;
have_reccodes = false;

have_stimrwdA = false;
have_stimrwdB = false;
have_stimsynchA = false;
have_stimsynchB = false;
have_stimcodes = false;

synchboxsignals = struct();
if isfield(thisdataset, 'synchbox')
  synchboxsignals = thisdataset.synchbox;
end

disp('-- Looking for SynchBox signals in ephys data.');

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

% FIXME - The only situation where we have to assemble from bits is with
% the Intan machine, and channel numbering starts at 1 in that situation.
firstbit = 1;

[ reccodes have_reccodes ] = euFT_getCodeWordEvent( ...
  synchboxsignals, 'reccodes', 'reccodebits', firstbit, 'recshift', ...
  rechdr.label, recevents_dig );

[ stimcodes have_stimcodes ] = euFT_getCodeWordEvent( ...
  synchboxsignals, 'stimcodes', 'stimcodebits', firstbit, 'stimshift', ...
  stimhdr.label, stimevents_dig );

% Squash event code values of zero; that's the idle state.
if have_reccodes
  reccodes = reccodes(reccodes.value > 0,:);
end
if have_stimcodes
  stimcodes = stimcodes(stimcodes.value > 0,:);
end

% Translate raw code bytes into cooked codes.
if ~have_unity
  disp('###  Can''t reassemble event codes without USE''s code definitions!');
else
  [ reccodes origlocations ] = euUSE_reassembleEventCodes( ...
    reccodes, evcodedefs, evcodebytes, evcodeendian, 'value' );
  [ stimcodes origlocations ] = euUSE_reassembleEventCodes( ...
    stimcodes, evcodedefs, evcodebytes, evcodeendian, 'value' );
end


% FIXME - Diagnostics.
disp(sprintf( ...
  '.. From recorder:  %d rwdA  %d rwdB  %d synchA  %d synchB  %d codes', ...
  height(recrwdA), height(recrwdB), ...
  height(recsynchA), height(recsynchB), height(reccodes) ));
disp(sprintf( ...
  '.. From stimulator:  %d rwdA  %d rwdB  %d synchA  %d synchB  %d codes', ...
  height(stimrwdA), height(stimrwdB), ...
  height(stimsynchA), height(stimsynchB), height(stimcodes) ));

% Done.

disp('-- Finished looking for SynchBox signals in ephys data.');



%
% This is the end of the file.
