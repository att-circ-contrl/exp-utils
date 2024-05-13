function result = euInfo_helper_analyzeMutual( ...
  wavedest, wavesrc, samprate, delaylist, params )

% function result = euInfo_helper_analyzeMutual( ...
%   wavedest, wavesrc, samprate, delaylist, params )
%
% This is an analysis function, per TIMEWINLAGFUNCS.txt.
%
% This calculates time-lagged mutual information between the supplied
% signals. If multiple trials are supplied, the trials are concatenated.
%
% "wavedest" and "wavesrc" are expected to contain waveform data that's
%   either continuous real-valued or discrete-valued.
% "params" contains the following fields:
%   "discrete_dest" and "discrete_src" indicate whether the destination
%     and source channels are discrete (auto-binned if so).
%   "bins_dest" and "bins_src" specify the number of bins to use when
%     binning continuous-valued data.
%   "want_extrap" is true to perform extrapolation, false otherwise.
%   "extrap_config" is an extrapolation configuration structure.
%   "want_parallel" is true to use the multithreaded implementation and
%     false otherwise.


  % Package the data.

  if ~isrow(wavedest)
    wavedest = transpose(wavedest);
  end
  if ~isrow(wavesrc)
    wavesrc = transpose(wavesrc);
  end

  scratchdata = [ wavedest ; wavesrc ];


  % Get histogram bins.
  % To handle the discrete case, always generate bins here and pass them
  % via cell array.

  binlist = {};

  if params.discrete_dest
    binlist{1} = cEn_getHistBinsDiscrete( wavedest );
  else
    binlist{1} = cEn_getHistBinsEqPop( wavedest, params.bins_dest );
  end

  if params.discrete_src
    binlist{2} = cEn_getHistBinsDiscrete( wavesrc );
  else
    binlist{2} = cEn_getHistBinsEqPop( wavesrc, params.bins_src );
  end


  % Calculate time-lagged mututal information.

% FIXME - Diagnostics.
%tic;
  if params.want_extrap
    mvals = cEn_calcLaggedMutualInfo( scratchdata, delaylist, binlist, ...
      params.extrap_config );
  else
    mvals = cEn_calcLaggedMutualInfo( scratchdata, delaylist, binlist );
  end
% FIXME - Diagnostics.
%durstring = nlUtil_makePrettyTime(toc);
%disp([ 'xx Probe completed in ' durstring '.' ]);


  % Store this in an appropriately-named field.
  result = struct();
  result.mutual = mvals;

end


%
% This is the end of the file.
