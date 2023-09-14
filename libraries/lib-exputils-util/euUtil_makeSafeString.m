function [ newlabel newtitle ] = euUtil_makeSafeString( oldstring )

% function [ newlabel newtitle ] = euUtil_makeSafeString( oldstring )
%
% This function makes label- and title-safe versions of an input string.
% The label-safe version strips anything that's not alphanumeric.
% The title-safe version replaces stripped characters with spaces.
%
% This is more aggressive than filename- or fieldname-safe strings; in
% particular, underscores are interpreted as typesetting metacharacters
% in plot labels and titles.
%
% "oldstring" is a character vector to convert.
%
% "newlabel" is a character vector with only alphanumeric characters.
% "newtitle" is a character vector with non-alphanumeric characters replaced
%   with spaces.


% Use vector operations instead of going letter by letter.

digitmask = (oldstring >= '0') & (oldstring <= '9');
lettermask = isletter(oldstring);
keepmask = digitmask | lettermask;

% For the label, discard anything that wasn't alphanumeric.
newlabel = oldstring(keepmask);

% For the title, replace anything that wasn't alphanumeric with spaces.
newtitle = oldstring;
newtitle(~keepmask) = ' ';


% Done.

end


%
% This is the end of the file.
