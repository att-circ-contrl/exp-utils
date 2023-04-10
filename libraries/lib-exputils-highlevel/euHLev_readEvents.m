function [ event_ftdata event_waves wave_times event_edges ] = ...
  euHLev_readEvents( folder, event_chans, trim_fraction )

% function [ event_ftdata event_waves wave_times event_edges ] = ...
%   euHLev_readEvents( folder, event_chans, trim_fraction )
%
% This reads Field Trip event data from the specified folder, trimming to
% the specified window, and returning events in several formats.
%
% NOTE - Channel names specified as '' are skipped (removed from the list
% before calling FT's read functions).
%
% NOTE - This assumes all of the requested data can fit in memory. Since
% this includes waveform reconstructions, that might be a poor assumpion.
%
% NOTE - Events and waveforms have timestamps relative to the start of the
% recording, not the start of the trim window.
%
% "folder" is the folder to read from.
% "event_chans" is a cell array containing event channel names to read. If
%   this is empty, no events are read (an empty cell array is returned).
% "trim_fraction" (in the range 0 to 0.5) is the amount of time to trim from
%   the start and end of the ephys data as a fraction of the untrimmed length.
%
% "event_ftdata" is a cell array with the same number of elements as
%   "event_chans". Each cell contains a vector of Field Trip event records
%   (per "nlFT_readEvents") from the associated event channel.
% "event_waves" is a cell array with the same number of elements as
%   "event_chans". Each cell contains a logical vector holding sampled values
%   of the event signal interpreted as a TTL waveform.
% "wave_times" is a vector holding sample timestamps. This is the same for
%   all waves contained in "event_waves".
% "event_edges" is a cell array with the same number of elements as
%   "event_chans". Each cell contains a structure with fields "risetimes",
%   "falltimes", and "bothtimes", containing vectors holding event timestamps
%   for rising edges, falling edges, and all edges, respectively.


event_ftdata = {};
event_waves = {};
wave_times = [];
event_edges = {};


if ~isempty(event_chans)

  % Give valid return data no matter what.
  for cidx = 1:length(event_chans)
    event_ftdata{cidx} = nlFT_makeEmptyEventList();
    event_waves{cidx} = logical([]);
    event_edges{cidx} = ...
      struct( 'risetimes', [], 'falltimes', [], 'bothtimes', [] );
  end


  % Read the header; we need metadata from it.
  header = ft_read_header( folder, 'headerformat', 'nlFT_readHeader' );

  % Get the TTL sample span using the same function that the signal reader
  % uses.
  [ sampfirst samplast ] = ...
    nlUtil_getTrimmedSampleSpan( header.nSamples, trim_fraction );

  % Package this information usefully.

  ttl_samprange = [ sampfirst samplast ];
  ttl_timerange = ttl_samprange / header.Fs;

  wave_times = sampfirst:samplast;
  wave_times = wave_times / header.Fs;


  % Read all events, and copy the ones we wanted.

  events_raw = ft_read_event( folder, ...
    'headerformat', 'nlFT_readHeader', 'eventformat', 'nlFT_readEvents' );

  if ~isempty(events_raw)
    event_labels = { events_raw(:).type };

    for cidx = 1:length(event_chans)
      thislabel = event_chans{cidx};
      if ~isempty(thislabel)
        % Get events from this specific channel. There might be none.
        this_ftdata = events_raw( strcmp(event_labels, event_chans{cidx}) );

        % Remove adjacent duplicates.
        this_ftdata = nlFT_pruneFTEvents(this_ftdata);

        % Get a waveform version of this signal.
        this_wave = ...
          nlFT_eventListToWaveform( this_ftdata, '', ttl_samprange );

        % Get edge lists.
        [ this_rise, this_fall, this_both ] = ...
          nlFT_getEventEdges( this_ftdata, '', header.Fs );

        % Apply the time window to the edge lists.
        this_rise = nlProc_trimTimeSequence( this_rise, ttl_timerange );
        this_fall = nlProc_trimTimeSequence( this_fall, ttl_timerange );
        this_both = nlProc_trimTimeSequence( this_both, ttl_timerange );

        % Record this signal's data.
        event_ftdata{cidx} = this_ftdata;
        event_waves{cidx} = this_wave;
        event_edges{cidx} = struct( 'risetimes', this_rise, ...
          'falltimes', this_fall, 'bothtimes', this_both );
      end
    end
  end

end


% Done.
end



%
% Helper Functions

function [ newwave fracbad ] = ...
  helper_iterate_artifacts( artparams, oldwave, samprate )

  % Don't keep NaNs (interpolate instead), and don't re-reference.
  [ newwave fracbad ] = nlChan_applyArtifactReject( ...
    oldwave, [], samprate, artparams, false );

end



%
% This is the end of the file.
