function recdata = euMeta_getLouieLogData( infile, datewanted )

% function recdata = euMeta_getLouieLogData( infile, datewanted )
%
% This function reads one of Louie's log files and extracts the record for
% the specified date.
%
% If "datewanted" is empty, all records are returned (as a struct array).
%
% If multiple records match the date, the first one is returned.
% If the date isn't matched, an empty struct array is returned.
%
% "infile" is the name of the file to read (containing Matlab code).
% "datewanted" is a character array containing the desired "date" field
%   contents, or an empty character array to return all records.
%
% "recdata" is a struct array containing zero or more matching records.
%
%
% Louie's epxeriment logs are Matlab functions that return a structure array
% named "D" with each day recorded in a struct.
%
% NOTE - This manually parses Louie's log into record segments and tries
% to run each segment's code individually. If any given segment fails to run
% (which happens), the location of the offending segment is reported.
%
% WARNING - This blindly trusts that the code in the log file is safe!


recdata = struct([]);
reccount = 0;


% Load the data.

% Load it as text and preprocess it, to iterate record by record.
% Then call "eval" to run each fragment.

if ~isfile(infile)
  disp(sprintf( '###  Unable to read from "%s".', infile ));
else
  filetext = fileread(infile);

  % Segment on "iD = numel(D) + 1;".

  segstarts = strfind(filetext, 'iD =');
  segcount = length(segstarts);
  segstarts = [ segstarts (length(filetext) + 1) ];

  % Build a line lookup table.
  % We have to tolerate Linux (\n), Windows (\r\n), and MacOs (\r) styles.

  linelut = [];
  thislinenum = 1;
  prevbreak = 'x';
  for cidx = 1:length(filetext)
    linelut(cidx) = thislinenum;
    thischar = filetext(cidx);

    if ismember(thischar, { char(10), char(13) })
      % Ignore any \n that follows a \r.
      if ~( (thischar == char(10)) && (prevbreak == char(13)) )
        thislinenum = thislinenum + 1;
      end
      prevbreak = thischar;
    else
      prevbreak = 'x';
    end
  end

  if segcount < 1
    disp(sprintf( '###  Couldn''t find "iD =" in "%s".', infile ));
  else

    for sidx = 1:segcount
      thisfragment = filetext( segstarts(sidx) : (segstarts(sidx+1) - 1) );

      % This will throw an error if there are any typos in the file.
      try
        D = struct([]);
        % Use "evalc" to redirect console output.
        scratch = evalc(thisfragment);

        % If we made it here, copy fields to our real struct array.
        % Fields might not be consistent, so we have to copy them one by one,
        % which automatically creates new fields in recdata.

        reccount = reccount + 1;
        fieldlist = fieldnames(D);
        for fidx = 1:length(fieldlist)
          thisfield = fieldlist{fidx};
          recdata(reccount).(thisfield) = D.(thisfield);
        end
      catch errordetails
        disp(sprintf( ...
          '###  Parse error in record starting at line %d:\n%s', ...
          linelut( segstarts(sidx) ), errordetails.message ));
      end
    end

  end
end


% Find the desired records.

if ~isempty(recdata)
  if ~isempty(datewanted)

    % Try to find one matching record.

    alldates = {recdata.date};
    matchflags = strcmp(alldates, datewanted);
    matchpos = find(matchflags);

    if isempty(matchpos)
      % Not found; return an empty struct.
      recdata = struct([]);
    else
      % Found one or more matches; pick the first.
      matchpos = matchpos(1);
      recdata = recdata(matchpos);
    end

  end
end


% Done.

end


%
% This is the end of the file.
