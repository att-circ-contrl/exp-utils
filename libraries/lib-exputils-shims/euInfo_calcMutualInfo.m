function midata = euInfo_calcMutualInfo( ...
  ftdata_dest, ftdata_src, win_params, flags, ...
  bin_count_dest, bin_count_src, exparams, phase_params )

euUtil_warnDeprecated( 'Call eiCalc_calcMutualInfo().' );

midata = eiCalc_calcMutualInfo( ...
  ftdata_dest, ftdata_src, win_params, flags, ...
  bin_count_dest, bin_count_src, exparams, phase_params );

%
% This is the end of the file.
