function doAuditStructArray(thestruct)

% function doAuditStructArray(thestruct)
%
% This checks entries of a structure array looking for ones that are
% anomalously large (usually indicating a coding error somewhere).
%
% The report is written to the console.
%
% "thestruct" is the structure array to examine.


arraybytes = whos('thestruct');
arraybytes = arraybytes.bytes;

arraylen = length(thestruct);


disp(sprintf( '.. Amortized bytes per entry:  %d', ...
  round(arraybytes/arraylen) ));


entrybytes = [];

for eidx = 1:length(thestruct)
  thisentry = thestruct(eidx);
  thisbytes = whos('thisentry');
  thisbytes = thisbytes.bytes;
  entrybytes(eidx) = thisbytes;
end

disp(sprintf( '.. Min: %d bytes   Max: %d bytes  Median: %d bytes', ...
  min(entrybytes), max(entrybytes), median(entrybytes) ));


% Done.
end


%
% This is the end of the file.
