function htdata = euInfo_calcHTStats( ...
  ftdata_first, ftdata_second, win_params, flags )

euUtil_warnDeprecated( 'Call eiCalc_calcHTStats().' );

htdata = eiCalc_calcHTStats( ...
  ftdata_first, ftdata_second, win_params, flags );

end

%
% This is the end of the file.
