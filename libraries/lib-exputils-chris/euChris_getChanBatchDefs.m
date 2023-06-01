function [ batchdefs batchlabels batchtitles ] = ...
  euChris_getChanBatchDefs( hintdata, want_batch_chans )

% function [ batchdefs batchlabels batchtitles ] = ...
%   euChris_getChanBatchDefs( hintdata, want_batch_chans )
%
% This processes case definition hint data, building a list of channel
% groups (batches) to process.
%
% "hintdata" is a hint structure from a case definition (per
%   CHRISCASEMETA.txt).
% "want_batch_chans" is true to return channel lists based on the
%   "chanbatches" hint field and false otherwise (just returning trigger
%   channel and the channels decribed in the "extrachans" hint field).
%   If batches are wanted but none are defined, 'all' is returned.
%
% "batchdefs" is a cell array containing batch definitions, per
%   CHRISBATCHDEFS.txt. Each batch definition is either a cell array or a
%   character vector. If it's a cell array, it contains a list of names of
%   channels to be read. If it's a character vector, it's 'trig', 'hint', or
%   'all'.
% "batchlabels" is a cell array containing filename-safe labels for each
%   batch.
% "batchtitles" is a cell array containing human-readable plot-safe names
%   for each batch.


batchdefs = {};
batchlabels = {};
batchtitles = {};


if want_batch_chans

  if isfield(hintdata, 'chanbatches')

    rawbatchlist = hintdata.chanbatches;

    for ridx = 1:5:length(rawbatchlist)
      batchlabels = [ batchlabels { rawbatchlist{ridx} } ];
      batchtitles = [ batchtitles { rawbatchlist{ridx + 1} } ];

      batchpattern = rawbatchlist{ridx + 2};
      batchchans = rawbatchlist{ridx + 3};
      batchbad = rawbatchlist{ridx + 4};

      batchchans = ...
        batchchans( ~ismember(batchchans, batchbad) );

      thischanlist = ...
        euChris_makeBatchChanLabels( batchpattern, batchchans );
      batchdefs = [ batchdefs { thischanlist } ] ;
    end

  else
    batchdefs = { 'all' };
    batchlabels = { 'all' };
    batchtitles = { 'All' };
  end

else

  batchdefs = { 'trig' };
  batchlabels = { 'trig' };
  batchtitles = { 'Trig' };

  if isfield(hintdata, 'extrachans')
    batchdefs = [ batchdefs { 'hint' } ];
    batchlabels = [ batchlabels { 'extra' } ];
    batchtitles = [ batchtitles { 'Extra' } ];
  end

end


% Done.
end


%
% This is the end of the file.
