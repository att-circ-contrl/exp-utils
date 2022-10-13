function [ channames, chanclasses ] = ...
  euUtil_readChannelClasses( fname, namecolumn, classcolumn )

% function [ channames, chanclasses ] = ...
%   euUtil_readChannelClasses( fname, namecolumn, classcolumn )
%
% This function reads a CSV file that assigns hand-annotated types to ephys
% channels. This file must have column labels in the first row.
%
% NOTE - Matlab will modify table column names; this function calls
% matlab.lang.makeValidName() to translate "namecolumn" and "classcolumn"
% using the same rules.
%
% "fname" is the name of the file to read from.
% "namecolumn" is the name of the column to read channel names from.
% "classcolumn" is the name of the column to read channel types from.
%
% "channames" is a vector or cell array containing channel numbers or names,
%   respectively.
% "chanclasses" is a cell array containing channel type labels.


channames = {};
chanclasses = {};


if ~isfile(fname)
  disp( [ '###  Unable to read from "' fname '".' ] );
else
  tabdata = readtable(fname);

  namecolumn = matlab.lang.makeValidName(namecolumn);
  classcolumn = matlab.lang.makeValidName(classcolumn);

  tabcols = tabdata.Properties.VariableNames;

  if ~ismember(namecolumn, tabcols)
    disp( [ '###  No column "' namecolumn '" in table!' ] );
  elseif ~ismember(classcolumn, tabcols)
    disp( [ '###  No column "' classcolumn '" in table!' ] );
  else
    channames = tabdata.(namecolumn);
    chanclasses = tabdata.(classcolumn);
  end
end


% Done.

end


%
% This is the end of the file.
