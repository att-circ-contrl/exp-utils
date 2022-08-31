function newsignals = ...
  euFT_addEventTimestamps( oldsignals, samprate, samplabel, timelabel )

% function newsignals = ...
%   euFT_addEventTimestamps( oldsignals, samprate, samplabel, timelabel )
%
% This function processes a number of event tables or event structure arrays,
% adding a timestamp column or field derived from the "sample" column or
% field.
%
% "oldsignals" is a structure with zero or more fields. Each field contains
%   either a table with event data or a struct array with event data.
% "samprate" is the sampling rate to use when calculating timestamps.
% "samplabel" is the name of the column or field with the sample number. In
%   Field Trip event lists, this is "sample".
% "timelabel" is the name of the new column or field to add.
%
% "newsignals" is a copy of "oldsignals" where each table or struct array
%   is augmented with a column or field containing timestamps in seconds.


newsignals = struct();

signames = fieldnames(oldsignals);
for sidx = 1:length(signames)
  thissig = signames{sidx};
  thisdata = oldsignals.(thissig);

  if ~isempty(thisdata)
    was_struct = isstruct(thisdata);
    if was_struct
      thisdata = struct2table(thisdata);
    end

    % Convert the sample indices to timestamps in seconds.
    thisdata.(timelabel) = thisdata.(samplabel) / samprate;

    if was_struct
      thisdata = table2struct(thisdata);
    end
  end

  newsignals.(thissig) = thisdata;
end


% Done.

end


%
% This is the end of the file.
