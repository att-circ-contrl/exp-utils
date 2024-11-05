function phasedata = euInfo_calcTrialPhaseStats( ...
  ftdata_dest, ftdata_src, win_params, flags )

euUtil_warnDeprecated( 'Call eiCalc_calcTrialPhaseStats().' );

phasedata = eiCalc_calcTrialPhaseStats( ...
  ftdata_dest, ftdata_src, win_params, flags );

end

%
% This is the end of the file.
