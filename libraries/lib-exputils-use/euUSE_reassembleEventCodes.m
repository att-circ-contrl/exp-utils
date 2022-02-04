function [ cookedcodes cookedindices ] = euUSE_reassembleEventCodes( ...
  rawcodes, codedefs, codebytes, codeendian, rawcolumn )

% function [ cookedcodes cookedindices ] = euUSE_reassembleEventCodes( ...
%   rawcodes, codedefs, codebytes, codeendian, rawcolumn )
%
% This translates a data table containing raw (byte) event codes into a
% table containing cooked (word) event codes.
%
% This recovers from dropped bytes. Anything unrecognized (due to dropped
% bytes or just not being in the definition file) is tagged with an empty
% character array as the "codeLabel".
%
% "rawcodes" is a table containing a raw code value column and optionally
%   other columns.
% "codedefs" is a structure containing "cooked" event code definitions per
%   "parseEventCodeDefs" and "EVCODEDEFS.txt".
% "codebytes" is the number of bytes per cooked code.
% "codeendian" is 'big' if the most-significant byte is received first
%   or 'little' if the least-significant byte is received first.
% "rawcolumn" is the name of the column to read raw codes from.
%
% "cookedcodes" is a table with the following columns:
%   "codeWord" is the reconstructed event code word value.
%   "codeData" is (code number - offset) * multiplier, per "EVCODEDEFS.txt".
%   "codeLabel" is the corresponding "codedefs" field name for this code.
%     This is usually a human-readable code name.
%   Other columns from "rawcodes" are copied for rows corresponding to the
%   first byte of each cooked code. These are typically timestamps.
% "cookedindices" is a vector with length equal to the number of rows in
%   "cookedcodes", containing indices (row numbers) pointing to the
%   locations of the corresponding first code bytes in "rawcodes".


cookedcodes = table();
cookedindices = [];

if ~isempty(rawcodes)

  rawbytes = rawcodes.(rawcolumn);

  % We can test starting indices of 1..startcount.
  startcount = length(rawbytes) + 1 - codebytes;

  % After we emit a code, we ignore the next (n-1) samples.
  ignorecount = 0;
  % We keep track of the number of bad bytes we've received, emitting
  % a bogus code as soon as the run ends or we reach the byte count.
  badcount = 0;

  % Initialize output.
  cookedcount = 0;
  cookedwords = [];
  cookeddata = [];
  cookedlabels = {};

  for sidx = 1:startcount
    if ignorecount > 0
      % This is part of a previously-recognized code.
      ignorecount = ignorecount - 1;
    else

      % Translate this string of bytes.
      thiscode = rawbytes(sidx:(sidx + codebytes - 1));
      thisword = helper_translateCode(thiscode, codeendian);

      [ thisdata thislabel ] = euUSE_lookUpEventCode(thisword, codedefs);

      % If this wasn't recognized, increment the bad bytes count.
      if isempty(thislabel)
        badcount = badcount + 1;
      end

      % Emit accumulated bad bytes, if appropriate.
      % If we have too many bad bytes, we emit them.
      % If we have good bytes, we emit any accumulated bad bytes first.

      if (badcount >= codebytes) || ...
        ( (badcount > 0) && (~isempty(thislabel)) )
        badcode = rawbytes((sidx + 1 - badcount):sidx);
        badword = helper_translateCode(badcode, codeendian);

        cookedcount = cookedcount + 1;

        cookedwords(cookedcount) = badword;
        cookeddata(cookedcount) = badword;
        cookedlabels{cookedcount} = '';
        cookedindices(cookedcount) = sidx + 1 - badcount;

        % Reset the bad bytes counter.
        badcount = 0;
      end

      % If we have a valid code, emit it, and update dead-time appropriately.
      if ~isempty(thislabel)
        cookedcount = cookedcount + 1;

        cookedwords(cookedcount) = thisword;
        cookeddata(cookedcount) = thisdata;
        cookedlabels{cookedcount} = thislabel;
        cookedindices(cookedcount) = sidx;

        ignorecount = codebytes - 1;
      end

    end
  end

  % If we generated any cooked codes, build a table with them.
  if cookedcount > 0

    % First pass: copy appropriate columns from the raw table.
    % Doing this first so that they don't overwrite new columns.

    colnames = rawcodes.Properties.VariableNames;
    for cidx = 1:length(colnames)
      thiscol = colnames{cidx};
      thisdata = rawcodes.(thiscol);

      % Get only the subset corresponding to the first byte of each code.
      thisdata = thisdata(cookedindices);

      if ~strcmp(thiscol, rawcolumn)
        cookedcodes.(thiscol) = thisdata;
      end
    end


    % Second pass: Store the processed data.

    % NOTE - We need to transpose the data row vectors to make table columns.
    cookedcodes.codeWord = cookedwords';
    cookedcodes.codeData = cookeddata';
    cookedcodes.codeLabel = cookedlabels';

  end

end



% Done.

end



%
% Helper Functions

function codeword = helper_translateCode(bytelist, codeendian);

  % Force big-endian order.
  if strcmp('little', codeendian)
    bytelist = flip(bytelist);
  end

  codeword = 0;
  for bidx = 1:length(bytelist)
    thisbyte = bytelist(bidx);
    % Squash any byte values of 0.
    thisbyte = max(1,thisbyte);

    % We're using base 255, not base 256, since we can't transmit 0.
    codeword = codeword * 255;
    codeword = codeword + (thisbyte - 1);
  end

end


%
% This is the end of the file.
