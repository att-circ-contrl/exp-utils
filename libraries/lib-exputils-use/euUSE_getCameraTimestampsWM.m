function [ frametimes recordtimes ] = euUSE_getCameraTimestampsWM( ...
  analogdata, timecolumn, framecolumn, recordcolumn )

% function [ frametimes recordtimes ] = euUSE_getCameraTimestampsWM( ...
%   analogdata, timecolumn, framecolumn, recordcolumn )
%
% This extracts timestamps for "camera grabbed a frame" and "system started
% recording" events for a White Matter e3Vision camera system. These systems
% output TTL pulses which are cabled to the SynchBox's analog inputs
% (typically 'joyX' and 'joyZ', respectively).
%
% If SynchBox timestamps are selected, timestamps should be accurate to
% 0.1 ms. If M-USE timestamps are selected, there's a lot more jitter.
%
% For precise M-USE timestamps, either do full time alignment in your
% processing script and then translate SynchBox timestamps into M-USE
% timestamps, or else use this function to fetch both SynchBox and M-USE
% timestamps and call nlProc_polyMapSeries() to do ramp-fit translation.
%
% "analogdata" is a table returned by euUSE_parseSerialRecvDataAnalog().
% "timecolumn" is the name of the table column with timestamps. This is
%   typically "synchBoxTime" or "unityTime".
% "framecolumn" is the name of the table column with "frame captured" pulses.
% "recordcolumn" is the name of the table column with "recording start" pulses.
%   If this is '', recording starts aren't processed.
%
% "frametimes" is a vector containing SynchBox timestamps of frame grabs.
% "recordtimes" is a vector containing SynchBox timestamps of recording
%   starts.


% Get the frame-grab waveform and process it.
% Use this to get the threshold for the recording-start waveform.

wavetimes = analogdata.(timecolumn);

waveframe = analogdata.(framecolumn);
thresh = median(waveframe);
boolframe = (waveframe > thresh);

[ scratchrise scratchfall scratchboth scratchhigh scratchlow ] = ...
  nlProc_getBooleanEdges( boolframe );
frametimes = wavetimes( scratchrise );


% Get the recording-start waveform and process it, if requested.

% Auto-thresholding will usually fail, since we either may not have a pulse
% at all or we're thresholding one brief pulse out of hours of footage.
% So, use the frame-grab threshold (TTL levels and ADC calibration should
% be similar).

recordtimes = [];
if ~isempty(recordcolumn)

  waverecord = analogdata.(recordcolumn);
  boolrecord = (waverecord > thresh);

  [ scratchrise scratchfall scratchboth scratchhigh scratchlow ] = ...
    nlProc_getBooleanEdges( boolrecord );
  recordtimes = wavetimes( scratchrise );

end


% Done.
end


%
% This is the end of the file.
