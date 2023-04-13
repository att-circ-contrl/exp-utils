function [ casefoms, newaggregate ] = ...
  euChris_evalTorte( signaldata, oldaggregate, evalconfig )

% function [ casefoms, newaggregate ] = ...
%   euChris_evalTorte( signaldata, oldaggregate, evalconfig )
%
% This function compiles figure-of-merit statistics for TORTE's estimation
% of magnitude and phase.
%
% "signaldata" is a structure returned by euChris_extractSignals_loop2302(),
%   with fields as described in CHRISSIGNALS.txt.
% "oldaggregate" is a structure with aggregate data returned by previous
%   calls to this function, or struct([]) for a new call.
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
% "casefoms" is a structure with the following fields:
%   "canon_v_torte_mag_rel_error" is a vector containing sampled relative
%     error of estimated magnitude vs acausal ground truth magnitude.
%   "canon_v_torte_mag_cat_vals" is a vector containing magnitude error bin
%     midpoint values corresponding to each of these relative error samples.
%   "canon_v_torte_phase_error_deg" is a vector containing sampled phase
%     error of estimated phase vs acausal ground truth phase.
%   "canon_v_torte_phase_cat_vals" is a vector containing phase error bin
%     midpoint values corresponding to each of these phase error samples.
%   "delayed_v_torte_mag_rel_error" is a vector containing sampled relative
%     error of estimated magnitude vs delayed (causal) ground truth magnitude.
%   "delayed_v_torte_mag_cat_vals" is a vector containing magnitude error bin
%     midpoint values corresponding to each of these relative error samples.
%   "delayed_v_torte_phase_error_deg" is a vector containing sampled phase
%     error of estimated phase vs delayed (causal) ground truth phase.
%   "delayed_v_torte_phase_cat_vals" is a vector containing phase error bin
%     midpoint values corresponding to each of these phase error samples.
% "newaggregate" is a copy of "oldaggregate" with the same fields as
%   "casefoms", with the values of the "casefoms" vectors appended to the
%   corresponding vectors in "oldaggregate".


% Initialize.

casefoms = struct([]);
newaggregate = oldaggregate;

evalconfig = euChris_fillDefaultsEvalTorte( evalconfig );

vector_labels = {};



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

  casefoms = struct();

  % FIXME - Discarding raw estimates and ground truth! Just saving error.

  if have_torte_mag
    casefoms.canon_v_torte_mag_rel_error = canon_torte_mag_torte_err;
    casefoms.canon_v_torte_mag_cat_vals = canon_torte_mag_catmidpoints;

    casefoms.delayed_v_torte_mag_rel_error = del_torte_mag_torte_err;
    casefoms.delayed_v_torte_mag_cat_vals = del_torte_mag_catmidpoints;

    vector_labels = [ vector_labels { ...
      'canon_v_torte_mag_rel_error', 'canon_v_torte_mag_cat_vals', ...
      'delayed_v_torte_mag_rel_error', 'delayed_v_torte_mag_cat_vals' } ];
  end

  if have_torte_phase
    casefoms.canon_v_torte_phase_error_deg = canon_torte_ph_error_deg;
    casefoms.canon_v_torte_phase_cat_vals = canon_torte_ph_catmidpoints;

    casefoms.delayed_v_torte_phase_error_deg = del_torte_ph_error_deg;
    casefoms.delayed_v_torte_phase_cat_vals = del_torte_ph_catmidpoints;

    vector_labels = [ vector_labels { ...
      'canon_v_torte_phase_error_deg', 'canon_v_torte_phase_cat_vals', ...
      'delayed_v_torte_phase_error_deg', 'delayed_v_torte_phase_cat_vals' } ];
  end

  % FIXME - Force sanity.
  for fidx = 1:length(vector_labels)
    thislabel = vector_labels{fidx};
    if ~isrow(casefoms.(thislabel))
      casefoms.(thislabel) = transpose( casefoms.(thislabel) );
    end
  end

end


% Update the aggregate data.

if isempty(newaggregate)
  newaggregate = casefoms;
else
  for fidx = 1:length(vector_labels)

    thislabel = vector_labels{fidx};

    % We've already forced these to be row vectors.

    if ~isfield(newaggregate, thislabel)
      % Handle the situation where a signal was missing from previous cases.
      newaggregate.(thislabel) = casefoms.(thislabel);
    else
      newaggregate.(thislabel) = ...
        [ newaggregate.(thislabel) casefoms.(thislabel) ];
    end

  end
end


% Done.
end


%
% This is the end of the file.
