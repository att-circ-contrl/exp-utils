function tortefoms = euChris_evalTorte( signaldata, evalconfig )

% function tortefoms = euChris_evalTorte( signaldata, evalconfig )
%
% This function compiles figure-of-merit statistics for TORTE's estimation
% of magnitude and phase.
%
% "signaldata" is a structure returned by euChris_extractSignals_loop2302(),
%   with fields as described in CHRISSIGNALS.txt.
% "evalconfig" is a structure specifying analysis parameters. Missing fields
%   are set to reasonable default values. Fields and defaults are:
%   "resample_ms" (default: 1.0) is the sampling interval for comparing
%     estimated and ground truth waves (which were recorded from different
%     nodes, and so need to be aligned and resampled).
%   "average_tau" (default: 10.0) is the smoothing time constant used for
%     computing the (acausal) running average of magnitude.
%   "magcategory_edges" (default: [ 0.1 0.3 0.7 1.5 3.0 10.0 ]) is a set of
%     bin edges used for binning by average-normalized canon magnitude
%     before computing magnitude estimation statistics.
%   "phasecategory_count" (default: 8) is the number of phase bins to use
%     when binning canon phase before computing phase estimation statistics.
%
% "tortefoms" is a structure with the following fields:
%   "canon_v_torte_mag_ideal" is a vector containing sampled acausal ground
%     truth magnitudes, normalized to the ground truth running average.
%   "canon_v_torte_mag_torte" is a vector containing sampled estimated
%     magnitudes, normalized to the acausal ground truth running average.
%   "canon_v_torte_mag_rel_error" is a vector containing sampled relative
%     error of estimated magnitude vs acausal ground truth magnitude.
%   "canon_v_torte_mag_cat_vals" is a vector containing magnitude error bin
%     midpoint values corresponding to each of these relative error samples.
%   "canon_v_torte_phase_error_deg" is a vector containing sampled phase
%     error of estimated phase vs acausal ground truth phase.
%   "canon_v_torte_phase_cat_vals" is a vector containing phase error bin
%     midpoint values corresponding to each of these phase error samples.
%   "delayed_v_torte_mag_ideal" is a vector containing sampled delayed
%     (causal) ground truth magnitudes, normalized to the ground truth
%     running average.
%   "delayed_v_torte_mag_torte" is a vector containing sampled estimated
%     magnitudes, normalized to the delayed (causal) ground truth average.
%   "delayed_v_torte_mag_rel_error" is a vector containing sampled relative
%     error of estimated magnitude vs delayed (causal) ground truth magnitude.
%   "delayed_v_torte_mag_cat_vals" is a vector containing magnitude error bin
%     midpoint values corresponding to each of these relative error samples.
%   "delayed_v_torte_phase_error_deg" is a vector containing sampled phase
%     error of estimated phase vs delayed (causal) ground truth phase.
%   "delayed_v_torte_phase_cat_vals" is a vector containing phase error bin
%     midpoint values corresponding to each of these phase error samples.


% Initialize.

tortefoms = struct([]);

evalconfig = euChris_fillDefaultsEvalTorte( evalconfig );



% Figure out what signals we have.
% If we have any canon signals, we have all of the canon and delayed signals.
% If we have torte magnitude or phase, we have torte time.

have_canon = isfield(signaldata, 'canon_time');

have_torte_mag = isfield(signaldata, 'torte_mag');
have_torte_phase = isfield(signaldata, 'torte_phase');


% Proceed only if we have the signals we need.

if have_canon && (have_torte_mag || have_torte_phase)

  % Extract relevant signals.
  % Assume that these exist if the time series did.

  % Remember that we have to resample to compare TORTE and ground truth,
  % since they were captured by different nodes.


  %
  % Canon vs torte.

  if have_torte_mag
    [ canon_torte_mag_time, canon_torte_mag_canon, canon_torte_mag_torte ] ...
      = euAlign_getResampledOverlappedWaves( ...
        signaldata.canon_time, signaldata.canon_mag, ...
        signaldata.torte_time, signaldata.torte_mag, ...
        evalconfig.resample_ms * 1e-3 );

    % Get a smoothed average.
    [ canon_torte_mag_avg, scratch ] = nlProc_calcSmoothedRMS( ...
      canon_torte_mag_canon, evalconfig.average_tau );

    % Get derived magnitude values.
    canon_torte_mag_canon_rel = canon_torte_mag_canon ./ canon_torte_mag_avg;
    canon_torte_mag_torte_err = ...
      canon_torte_mag_torte ./ canon_torte_mag_canon;
    % Get estimated magnitude normalized the same way reference magnitude was.
    canon_torte_mag_torte_rel = canon_torte_mag_torte ./ canon_torte_mag_avg;
  end

  if have_torte_phase
    % NOTE - We have to unwrap phase before resampling.
    canon_phase_unwrapped = unwrap( signaldata.canon_phase );
    torte_phase_unwrapped = unwrap( signaldata.torte_phase );
    [ canon_torte_ph_time, canon_torte_ph_canon, canon_torte_ph_torte ] = ...
      euAlign_getResampledOverlappedWaves( ...
        signaldata.canon_time, canon_phase_unwrapped, ...
        signaldata.torte_time, torte_phase_unwrapped, ...
        evalconfig.resample_ms * 1e-3 );

    % Compute the phase error and re-wrap everything to +/- pi.

    canon_torte_ph_error = canon_torte_ph_torte - canon_torte_ph_canon;

    canon_torte_ph_canon = mod(canon_torte_ph_canon + pi, 2*pi) - pi;
    canon_torte_ph_torte = mod(canon_torte_ph_torte + pi, 2*pi) - pi;
    canon_torte_ph_error = mod(canon_torte_ph_error + pi, 2*pi) - pi;
  end


  %
  % Delayed (causal) vs torte.

  if have_torte_mag
    [ del_torte_mag_time, del_torte_mag_canon, del_torte_mag_torte ] = ...
      euAlign_getResampledOverlappedWaves( ...
        signaldata.delayed_time, signaldata.delayed_mag, ...
        signaldata.torte_time, signaldata.torte_mag, ...
        evalconfig.resample_ms * 1e-3 );

    % Get a smoothed average.
    [ del_torte_mag_avg, scratch ] = nlProc_calcSmoothedRMS( ...
      del_torte_mag_canon, evalconfig.average_tau );

    % Get derived magnitude values.
    del_torte_mag_canon_rel = del_torte_mag_canon ./ del_torte_mag_avg;
    del_torte_mag_torte_err = del_torte_mag_torte ./ del_torte_mag_canon;
    % Get estimated magnitude normalized the same way reference magnitude was.
    del_torte_mag_torte_rel = del_torte_mag_torte ./ del_torte_mag_avg;
  end

  if have_torte_phase
    % NOTE - We have to unwrap phase before resampling.
    del_phase_unwrapped = unwrap( signaldata.delayed_phase );
    torte_phase_unwrapped = unwrap( signaldata.torte_phase );
    [ del_torte_ph_time, del_torte_ph_canon, del_torte_ph_torte ] = ...
      euAlign_getResampledOverlappedWaves( ...
        signaldata.delayed_time, del_phase_unwrapped, ...
        signaldata.torte_time, torte_phase_unwrapped, ...
        evalconfig.resample_ms * 1e-3 );

    % Compute the phase error and re-wrap everything to +/- pi.

    del_torte_ph_error = del_torte_ph_torte - del_torte_ph_canon;

    del_torte_ph_canon = mod(del_torte_ph_canon + pi, 2*pi) - pi;
    del_torte_ph_torte = mod(del_torte_ph_torte + pi, 2*pi) - pi;
    del_torte_ph_error = mod(del_torte_ph_error + pi, 2*pi) - pi;
  end


  %
  % Build box chart data.


  % Magnitude is straightforward.
  % We're categorizing using canon magnitude relative to the running average.

  if have_torte_mag
    [ canon_torte_mag_catindices, canon_torte_mag_catmidpoints ] = ...
      euPlot_getBoxChartGroups( ...
        canon_torte_mag_canon_rel, evalconfig.magcategory_edges );

    [ del_torte_mag_catindices, del_torte_mag_catmidpoints ] = ...
      euPlot_getBoxChartGroups( ...
        del_torte_mag_canon_rel, evalconfig.magcategory_edges );
  end


  % For phase, re-wrap the canon input so that the discontinuity is at a
  % bin edge. Phase error stays -pi..pi.
  % Also convert to degrees, to make box plotting more readable.

  if have_torte_phase

    phasecount = evalconfig.phasecategory_count;
    wedge_size = 360.0 / phasecount;

    phasecategory_edges = (-phasecount):2:phasecount;
    phasecategory_edges = (phasecategory_edges + 1) / 2.0;
    phasecategory_edges = phasecategory_edges * wedge_size;
    phase_bin_start = phasecategory_edges(1);

    canon_torte_ph_canon_deg = canon_torte_ph_canon * 180 / pi;
    canon_torte_ph_canon_deg = ...
      mod( canon_torte_ph_canon_deg - phase_bin_start, 360 ) + phase_bin_start;
    canon_torte_ph_error_deg = canon_torte_ph_error * 180 / pi;

    [ canon_torte_ph_catindices, canon_torte_ph_catmidpoints ] = ...
      euPlot_getBoxChartGroups( ...
        canon_torte_ph_canon_deg, phasecategory_edges );

    del_torte_ph_canon_deg = del_torte_ph_canon * 180 / pi;
    del_torte_ph_canon_deg = ...
      mod( del_torte_ph_canon_deg - phase_bin_start, 360 ) + phase_bin_start;
    del_torte_ph_error_deg = del_torte_ph_error * 180 / pi;

    [ del_torte_ph_catindices, del_torte_ph_catmidpoints ] = ...
      euPlot_getBoxChartGroups( del_torte_ph_canon_deg, phasecategory_edges );

  end


  %
  % FIXME - Not building histogram counts, as histograms aren't very useful
  % for this data.


  %
  % Store everything we'd want to save or plot in the FOMs structure.

  tortefoms = struct();

  % Saving normalized estimated and ground truth magnitude.
  % Not saving phase estimates or ground truth.
  % Saving error for magnitude and phase.

  if have_torte_mag
    tortefoms.canon_v_torte_mag_ideal = canon_torte_mag_canon_rel;
    tortefoms.canon_v_torte_mag_torte = canon_torte_mag_torte_rel;
    tortefoms.canon_v_torte_mag_rel_error = canon_torte_mag_torte_err;
    tortefoms.canon_v_torte_mag_cat_vals = canon_torte_mag_catmidpoints;

    tortefoms.delayed_v_torte_mag_ideal = del_torte_mag_canon_rel;
    tortefoms.delayed_v_torte_mag_torte = del_torte_mag_torte_rel;
    tortefoms.delayed_v_torte_mag_rel_error = del_torte_mag_torte_err;
    tortefoms.delayed_v_torte_mag_cat_vals = del_torte_mag_catmidpoints;
  end

  if have_torte_phase
    tortefoms.canon_v_torte_phase_error_deg = canon_torte_ph_error_deg;
    tortefoms.canon_v_torte_phase_cat_vals = canon_torte_ph_catmidpoints;

    tortefoms.delayed_v_torte_phase_error_deg = del_torte_ph_error_deg;
    tortefoms.delayed_v_torte_phase_cat_vals = del_torte_ph_catmidpoints;
  end


  % Force geometry to row vectors, just in case it's inconsistent.
  fomlabels = fieldnames(tortefoms);
  for fidx = 1:length(fomlabels)
    thislabel = fomlabels{fidx};
    if ~isrow(tortefoms.(thislabel))
      tortefoms.(thislabel) = transpose( tortefoms.(thislabel) );
    end
  end

end


% Done.
end


%
% This is the end of the file.
