function recdata = euUtil_getLouieLogData( infile, datewanted )

% function recdata = euUtil_getLouieLogData( infile, datewanted )
%
% This function reads one of Louie's log files and extracts the record for
% the specified date.
%
% If "datewanted" is empty, all records are returned (as a struct array).
% If the date isn't matched, an empty struct array is returned.
%
% WARNING - This blindly trusts that the code in the log file is safe!
%
% Louie's epxeriment logs are Matlab functions that return a structure array
% named "D" with each day recorded in a struct.
%
% "infile" is the name of the file to read (containing Matlab code).
% "datewanted" is a character array containing the desired "date" field
%   contents, or an empty character array to return all records.
%
% "recdata" is a struct array containing zero or more matching records.


recdata = struct([]);
D = struct([]);


% Load the data.
% NOTE - Because this wasn't saved as a ".m" file, we have to load the text
% and call "eval" to process it.

if ~isfile(infile)
  disp(sprintf( '###  Unable to read from "%s".', infile ));
else
  filetext = fileread(infile);

  % Get rid of "function D = ...".
  % FIXME - Cheat.
  % The first "D =" is in the declaration; the second is "D = []".
  % Drop everything before the second instance.
  didx = strfind(filetext, 'D =');
  if length(didx) < 2
    disp(sprintf( '###  Couldn''t find second "D =" instance in "%s".', ...
      infile ));
  else
    filetext = filetext( didx(2) : length(filetext) );
    eval(filetext);
  end
end


% Find the desired records.

if ~isempty(D)
  if isempty(datewanted)

    % Return everything.
    recdata = D;

  else

    % Try to find one matching record.

    alldates = {D.date};
    matchflags = strcmp(alldates, datewanted);
    matchpos = find(matchflags);

    if isempty(matchpos)
      % Not found; return an empty struct.
      recdata = struct([]);
    else
      % Found one or more matches; pick the first.
      matchpos = matchpos(1);
      recdata = D(matchpos);
    end

  end
end


% Done.

end


%
% This is the end of the file.
