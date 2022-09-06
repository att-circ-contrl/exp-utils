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
% "oldstring" is the string to convert.
%
% "newlabel" is a string with only alphanumeric characters.
% "newtitle" is a string with non-alphanumeric characters replaced with spaces.


newlabel = '';
newtitle = '';

for cidx = 1:length(oldstring)
  thischar = oldstring(cidx);

  % Use "isletter" so that we're language-agnostic.
  if ( (thischar >= '0') && (thischar <= '9') ) || isletter(thischar)
    newlabel = [ newlabel thischar ];
    newtitle = [ newtitle thischar ];
  else
    newtitle = [ newtitle ' ' ];
  end
end


% Done.

end


%
% This is the end of the file.
