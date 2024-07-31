function recdata = euUtil_getLouieLogData( infile, datewanted )

% This was moved to euMeta_xx.

euUtil_warnDeprecated( 'Call euMeta_getLouieLogData().' );

recdata = euMeta_getLouieLogData(infile, datewanted);

end

%
% This is the end of the file.
