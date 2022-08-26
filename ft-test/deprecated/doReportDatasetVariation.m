function doReportDatasetVariation(dataset)

% function doReportDatasetVariation(dataset)
%
% This is a debugging function. For each channel in the specified dataset,
% it reports the extents and standard deviation within that channel's data.
% The summary is written to the console.
%
% NOTE - This assumes a monolithic dataset.
%
% "dataset" is the dataset to process.


thisheader = dataset.hdr;
thischanlist = thisheader.label;
thistrial = dataset.trial{1};

for cidx = 1:length(thischanlist)
  thischan = thischanlist{cidx};
  thisdata = thistrial(cidx,:);
  disp(sprintf( '.. Channel %d (%s):\n      %f..%f  (deviation %f)', ...
    cidx, thischan, min(thisdata), max(thisdata), std(thisdata) ));
end


% Done.

end


%
% This is the end of the file.
