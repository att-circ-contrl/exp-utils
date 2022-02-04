function defscooked = euUSE_readEventCodeDefs( runtimedir )

% function defscooked = euUSE_readEventCodeDefs( runtimedir )
%
% This function reads the "eventcodes_USE_05.json" file and returns a
% "cooked" event code definition structure, per EVCODEDEFS.txt.
%
% "runtimedir" is the "RuntimeData" directory location.
%
% "defscooked" is a "cooked" event code definition structure.


jsonfname = 'eventcodes_USE_05.json';
fname = [ runtimedir filesep 'SessionSettings' filesep jsonfname ];

defsraw = jsondecode(fileread(fname));

evcode_overrides = euUSE_getEventCodeDefOverrides();

defscooked = euUSE_parseEventCodeDefs(defsraw, evcode_overrides);


% Done.

end


%
% This is the end of the file.
