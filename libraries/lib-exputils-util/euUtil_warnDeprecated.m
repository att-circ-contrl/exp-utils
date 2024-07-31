function euUtil_warnDeprecated( message, funcname )

% function euUtil_warnDeprecated( message, funcname )
%
% This emits a "(function) is deprecated" message, optionally followed
% by a user-specified additional message.
%
% This checks to see if a given deprecated function has already been
% reported. Only the first call for a given function name will be reported.
%
% "message" is an optional argument. If present, it contains a character
%   vector to be appended to the deprecation message. If this is '', no
%   message is added.
% "funcname" is an optionalal argument. If present, it contains a character
%   vector to report as the name of the function (and to use as a key
%   to check whether the function has already been reported). If this is
%   absent, the calling function's name is read from the stack.
%
% No return value.


% Get arguments. Fill in missing arguments if necessary.

if ~exist('message', 'var')
  message = '';
end

if ~exist('funcname', 'var')
  funcname = '(unknown function)';

  st = dbstack;
  if length(st) >= 2
    % The first entry is this function. The second entry is the caller.
    funcname = st(2).name;
  end
end



% Get the "already reported" list.

global euUtilWarnDeprecatedList;

if ~iscell(euUtilWarnDeprecatedList)
  euUtilWarnDeprecatedList = {};
end



% Report this function if we haven't already.

if ~ismember( funcname, euUtilWarnDeprecatedList )

  euUtilWarnDeprecatedList = [ euUtilWarnDeprecatedList { funcname } ];

  thismessage = [ '###  Function "' funcname '" is deprecated.' ];
  if ~isempty(message)
    thismessage = [ thismessage ' ' message ];
  end

  disp(thismessage);

end


% Done.
end


%
% This is the end of the file.
