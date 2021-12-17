function [ ttlevents ttlsamptimes ttlsamprate ] = ...
  evCodes_loadTTLOpenEBinary( foldername )

% function [ ttlevents ttlsamptimes ttlsamprate ] = ...
%   evCodes_loadTTLOpenEBinary( foldername )
%
% This function parses event data stored in Open Ephys binary format and
% extracts a TTL event series. NOTE - There's usually only one of these.
% This extracts the last such series it finds.
%
% If it can't read TTL data, it returns empty arrays and NaN sampling rate.
%
% "foldername" is the path to the folder containing "structure.oebin".
%
% "ttlevents" is a series of integers representing TTL state changes. These
%   are "+chan" for rising edges and "-chan" for falling edges, with channel
%   numbers starting at 1.
% "ttlsamptimes" is a series of Open Ephys timestamps (sample numbers)
%   corresponding to the events in "ttlevents".
% "ttlsamprate" is the sampling rate at which TTL data was acquired.


% Initialize.

ttlevents = [];
ttlsamptimes = [];
ttlsamprate = NaN;


% Monolithic binary format.

binmetafile = sprintf( '%s/structure.oebin', foldername );

% TTL data sources are event-type sources with "TTL" in the label.
% FIXME - Assume there's only one of these.
% The last one seen takes priority.

listevents = list_open_ephys_binary( binmetafile, 'events' );

for didx = 1:length(listevents)
  % Look for upper-case "TTL" only.
  startindices = regexp(listevents{didx}, 'TTL');

  if ~isempty(startindices)

    % We found a TTL event list. Overwrite any previous list.
    disp(sprintf('-- Loading Open Ephys "%s"...', listevents{didx}'));

    ttlscratch = load_open_ephys_binary( binmetafile, 'events', didx );

    ttlsamprate = ttlscratch.Header.sample_rate;

    % This is "+chan" for a rising edge and "-chan" for a falling edge.
    ttlevents = ttlscratch.Data;

    % These are sample indices. FIXME: 0-based or 1-based?
    ttlsamptimes = ttlscratch.Timestamps;
  end
end


% Done.

end


%
% This is the end of the file.
