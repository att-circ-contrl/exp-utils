function [ totalcount goodcount goodunique gooddesc ...
  badcount badunique baddesc ] = doGetEventStatistcs( ...
  codetable, obase )

% function [ totalcount goodcount goodunique gooddesc ...
%   badcount badunique baddesc ] = doGetEventStatistcs( ...
%   codetable, obase )
%
% This returns a human-readable digest of event code statistics. If a
% non-empty output filename is supplied, these are also written to text files.
%
% "codetable" is a table of reassembled event codes with the format
%   described in reassembleCodes(). Columns read are:
%   "codeWord" contains the code's integer value.
%   "codeData" is (code number - offset) * multiplier, per "EVCODEDEFS.txt".
%   "codeLabel" is the code definition field name for this code, if the
%     code was recognized, or '' if the code was not recognized. This is
%     usually a human-readable code name.
% "obase" is a prefix used when constructing output filenames. Use '' to
%   suppress file output.
%
% "totalcount" is the total number of events in "codetable".
% "goodcount" is the total number of events with recognized codes.
% "goodunique" is a cell array containing a list of labels associated with
%   recognized events. Each label is present only once.
% "gooddesc" is a character array containing a human-readable table of
%   event counts and data ranges for each event code label recognized. This
%   table contains newlines.
% "badcount" is the total number of events that were not recognized.
% "badunique" is a vector containing the code words that weren't recognized.
%   each code word is present only once.
% "baddesc" is a character array containing a human-readable table of event
%   counts and code word values for each unrecognized code word.


% Initialize to "nothing found".

totalcount = 0;

goodcount = 0;
goodunique = {};
gooddesc = '';

badcount = 0;
badunique = [];
baddesc = '';


if ~isempty(codetable)

  % Extract labels and see how many good/bad events we have.

  alllabels = codetable.codeLabel;
  allwords = codetable.codeWord;
  alldata = codetable.codeData;

  badmask = strcmp(alllabels, '');
  goodmask = ~badmask;

  totalcount = length(alllabels);

  badcount = sum(badmask);
  goodcount = sum(goodmask);


  % Process the "bad" list.

  if badcount > 0

    % We only care about the code words.
    % Label is always '' and data is always equal to the code word.

    badwords = allwords(badmask);
    badunique = unique(badwords);

    baddesc = '';
    for bidx = 1:length(badunique)
      thisbad = badunique(bidx);
      thiscount = sum(badwords == thisbad);
      thisdesc = sprintf( '%6d - %d times\n', thisbad, thiscount );
      baddesc = [ baddesc thisdesc ];
    end

    % Write output if requested.
    if ~isempty(obase)
      helper_writeFile( sprintf('%s-codes-bad.txt', obase), baddesc );
    end
  end


  % Process the "good" list.

  if goodcount > 0

    goodlabels = alllabels(goodmask);
    goodwords = allwords(goodmask);
    gooddata = alldata(goodmask);

    % We're going to see a lot of different values for ranged codes, so
    % walk through unique labels rather than unique code words.

    % Sorting and "unique" work just fine with string data.
    goodunique = unique(goodlabels);

    gooddesc = '';
    for gidx = 1:length(goodunique)
      thisgoodlabel = goodunique{gidx};
      thisgoodmask = strcmp(goodlabels, thisgoodlabel);
      thiscount = sum(thisgoodmask);

      % Extract data range.
      thisgooddata = gooddata(thisgoodmask);
      thisgooddata = unique(thisgooddata);

      thisdesc = '';
      if length(thisgooddata) == 1
        thisdesc = sprintf( '%24s - %d times  (data: %d)\n', ...
          thisgoodlabel, thiscount, thisgooddata );
      else
        thisdesc = sprintf( '%24s - %d times  (data: %d to %d)\n', ...
          thisgoodlabel, thiscount, min(thisgooddata), max(thisgooddata) );
      end

      gooddesc = [ gooddesc thisdesc ];
    end

    % Write output if requested.
    if ~isempty(obase)
      helper_writeFile( sprintf('%s-codes-good.txt', obase), gooddesc );
    end

  end

end


% Done.

end


%
% Helper functions.


function helper_writeFile( fname, ftext )

  fid = fopen(fname, 'w');
  if fid < 0
    disp(sprintf( '### Unable to write to "%s".', fname ));
  else
    % This is text data, so write it as text, not bytes (in case of
    % peculiar encoding).

    fprintf( fid, '%s', ftext );

    fclose(fid);
  end

end


%
% This is the end of the file.
