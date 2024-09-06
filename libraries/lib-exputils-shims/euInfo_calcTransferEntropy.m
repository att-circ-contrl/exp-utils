function tedata = euInfo_calcTransferEntropy( ...
  ftdata_dest, ftdata_src, win_params, flags, ...
  bin_count_dest, bin_count_src, exparams, phase_params )

euUtil_warnDeprecated( 'Call eiCalc_calcTransferEntropy().' );

% "phase_params" is an optional argument.

if exist('phase_params', 'var')
  tedata = eiCalc_calcTransferEntropy( ...
    ftdata_dest, ftdata_src, win_params, flags, ...
    bin_count_dest, bin_count_src, exparams, phase_params );
else
  tedata = eiCalc_calcTransferEntropy( ...
    ftdata_dest, ftdata_src, win_params, flags, ...
    bin_count_dest, bin_count_src, exparams );
end

%
% This is the end of the file.
