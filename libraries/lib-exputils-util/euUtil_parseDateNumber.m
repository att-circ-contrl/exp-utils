function [ yearnum, monthnum, monthshort monthlong, daynum ] = ...
  euUtil_parseDateNumber( packeddatenum )

% function [ yearnum, monthnum, monthshort monthlong, daynum ] = ...
%   euUtil_parseDateNumber( packeddatenum )
%
% This parses a date number that has the form YYYYMMDD, YYMMDD, or MMDD.
% This may be supplied as a number or as a character vector.
%
% "packeddatenum" is the date number to parse.
%
% "yearnum" is the year (YYYY or YY), or NaN if no year was provided.
% "monthnum" is the month number (expected to be 1-12; MM in the template).
% "monthshort" is a character vector with a three-letter month label.
% "monthlong" is a character vector with the full month name.
% "daynum" is the day number (DD in the template).

yearnum = NaN;
monthnum = NaN;
monthshort = '';
monthlong = '';
daynum = NaN;


% Convert to a number if it isn't already one.
if ischar(packeddatenum)
  packeddatenum = str2double(packeddatenum);
end


% Get raw values.
packeddatenum = floor(packeddatenum);
daynum = mod(packeddatenum, 100);
packeddatenum = floor(packeddatenum / 100);
monthnum = mod(packeddatenum, 100);
yearnum = floor(packeddatenum / 100);


% Omit the year if it isn't valid.
if yearnum < 1
  yearnum = NaN;
end


% We don't need to sanity-check the day, but we do need to force the month
% to be in the valid range if we're converting it.

if (monthnum < 1) || (monthnum > 12)
  monthnum = NaN;
else
  shortmonthlist = ...
    { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', ...
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' };
  longmonthlist = ...
    { 'January', 'February', 'March', 'April', ...
      'May', 'June', 'July', 'August', ...
      'September', 'October', 'November', 'December' };

  monthshort = shortmonthlist{monthnum};
  monthlong = longmonthlist{monthnum};
end


% Done.
end


%
% This is the end of the file.
