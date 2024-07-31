function euUtil_warnDeprecated( funcname, message )

% function euUtil_warnDeprecated( funcname, message )
%
% This emits a "(function) is deprecated" message, optionally followed
% by a user-specified additional message.
%
% This checks to see if a given deprecated function has already been
% reported. Only the first call for a given function name will be reported.
%
% "funcname" is the name of the deprecated function.
% "message" is an optional argument. If present, it contains a character
%   vector to be appended to the deprecation message.
%
% No return value.


global euUtilWarnDeprecatedList;

if ~iscell(euUtilWarnDeprecatedList)
  euUtilWarnDeprecatedList = {};
end


if ~ismember( funcname, euUtilWarnDeprecatedList )

  euUtilWarnDeprecatedList = [ euUtilWarnDeprecatedList { funcname } ];

  thismessage = [ '###  Function "' funcname '" is deprecated.' ];
  if exist('message', 'var')
    thismessage = [ thismessage ' ' message ];
  end

  disp(thismessage);

end


% Done.
end


%
% This is the end of the file.
