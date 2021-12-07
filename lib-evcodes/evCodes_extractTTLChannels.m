function [ risingsamps fallingsamps ] = ...
  evCodes_extractTTLChannels( muxeddata, timestamps )

% function [ risingsamps fallingsamps ] = ...
%   evCodes_extractTTLChannels( muxeddata, timestamps )
%
% This function demultiplexes Open Ephys TTL events, returning per-channel
% lists of edge times. Edge times are sample indices (used by Open Ephys
% as timestamps). NOTE - Sample indices are uint64, not floating-point!
%
% "muxeddata" is the TTL events "Data" field. This is "+chan" for rising
%   edges and "-chan" for falling edges.
% "timestamps" is the TTL events "Timestamps" field. This holds the sample
%   indices of the "muxeddata" events.
%
% "risingsamps" is a cell array containing one vector per channel, holding
%   sample indices of rising edges.
% "fallingsamps" is a cell array containing one vector per channel, holding
%   sample indices of falling edges.
%
% Channel numbers are 1..N, where N is the largest channel number seen in
% "muxeddata". Channels smaller than N that were not seen have empty vectors.


risingsamps = {};
fallingsamps = {};

maxchan = 0;

% Force sanity, just in case.
muxeddata = round(muxeddata);

if ~isempty(muxeddata)
  maxchan = max(abs(muxeddata));

  % This tolerates maxchan of 0.
  for cidx = 1:maxchan
    idxlist = (muxeddata == cidx);
    % This tolerates empty idxlist.
    risingsamps{cidx} = timestamps(idxlist);

    idxlist = (muxeddata == (-cidx));
    % This tolerates empty idxlist.
    fallingsamps{cidx} = timestamps(idxlist);
  end
end


% Done.

end


%
% This is the end of the file.
