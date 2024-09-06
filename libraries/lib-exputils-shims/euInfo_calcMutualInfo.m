function midata = euInfo_calcMutualInfo( ...
  ftdata_dest, ftdata_src, win_params, flags, ...
  bin_count_dest, bin_count_src, exparams, phase_params )

euUtil_warnDeprecated( 'Call eiCalc_calcMutualInfo().' );

% "phase_params" is an optional argument.

if exist('phase_params', 'var')
  midata = eiCalc_calcMutualInfo( ...
    ftdata_dest, ftdata_src, win_params, flags, ...
    bin_count_dest, bin_count_src, exparams, phase_params );
else
  midata = eiCalc_calcMutualInfo( ...
    ftdata_dest, ftdata_src, win_params, flags, ...
    bin_count_dest, bin_count_src, exparams );
end

%
% This is the end of the file.
