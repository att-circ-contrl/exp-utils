function newtrialmeta = euMeta_addFrameDataToTrialMetadata( ...
  oldtrialmeta, framedatatable )

% function newtrialmeta = euMeta_addFrameDataToTrialMetadata( ...
%   oldtrialmeta, framedatatable )
%
% This function compares trial metadata derived from event codes (from
% euMeta_getTrialMetadataFromCodes) with the M-USE "framedata" table, and
% annotates the trial metadata with additional information from that table.
%
% "oldtrialmeta" is a structure array from euMeta_getTrialMetadataFromCodes().
% "framedatatable" is a table produced by euUSE_readRawFrameData().
%
% "newtrialmeta" is a copy of "oldtrialmeta" with the following additional
%   fields added:
%   "block_number" is the value from the "Block" column in framedatatable,
%     adjusted to be 1-based instead of 0-based.


% NOTE - There's more that we want to add, but it's in BlockDef.txt, not
% the frame data table.


% Initialize.
newtrialmeta = oldtrialmeta;


% Build a lookup table.

rawblocks = framedatatable.Block;
rawtrialindices = framedatatable.TrialCounter;
rawtrialnumbers = framedatatable.TrialInExperiment;

trialindices = unique(rawtrialindices);
blocknumbers = nan(size( trialindices ));

for tidx = 1:length(trialindices)
  rawidx = min(find( rawtrialindices == trialindices(tidx) ));
  if ~isempty(rawidx)
    blocknumbers(tidx) = rawblocks(rawidx);
  end
end

% NOTE - Louie confirms that the "Block" column is 0-based and the block
% numbers he uses are 1-based.
blocknumbers = blocknumbers + 1;


% Apply the lookup table.

for midx = 1:length(newtrialmeta)
  thistrialindex = newtrialmeta(midx).trial_index;
  thisblock = nan;

  if ~isnan(thistrialindex)
    lutidx = min(find( trialindices == thistrialindex ));
    if ~isempty(lutidx)
      thisblock = blocknumbers(lutidx);
    end
  end

  newtrialmeta(midx).block_number = thisblock;
end



% Done.
end


%
% This is the end of the file.
