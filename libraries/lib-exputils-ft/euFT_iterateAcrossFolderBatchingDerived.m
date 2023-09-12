function auxdata = euFT_iterateAcrossFolderBatchingDerived( ...
  config_load, iterfunc_derived, chanbatchsize, trialbatchsize, ...
  artparams, notch_freqs, notch_bw, lfp_corner, lfp_rate, ...
  spike_corner, mua_band, mua_corner, mua_rate, ...
  verbosity )

% function auxdata = euFT_iterateAcrossFolderBatchingDerived( ...
%   config_load, iterfunc_derived, chanbatchsize, trialbatchsize, ...
%   artparams, notch_freqs, notch_bw, lfp_corner, lfp_rate, ...
%   spike_corner, mua_band, mua_corner, mua_rate, ...
%   verbosity )
%
% This iterates across a Field Trip dataset, loading a few channels at a time
% and performing built-in and user-specified processing. Processing output
% is aggregated and returned.
%
% The idea is to be able to process a dataset much larger than can fit in
% memory. At 30 ksps the footprint is typically about 1 GB per channel-hour.
%
% Built-in processing is artifact rejection followed by notch filtering
% followed by calling euFT_getDerivedSignals() to get LFP, spike, and MUA
% waveforms. These are passed (with the wideband waveform) to a user-specified
% function for futher processing.
%
% The user-specified iteration function handle is of the type described in
% FT_ITERFUNC_DERIVED.txt. Return values are aggregated in "auxdata".
%
% "config_load" is a Field Trip configuration structure to be passed to
%   ft_preprocessing() to load the data. The "channel" field is split into
%   batches when iterating.
% "iterfunc_derived" is a function handle used to transform derived waveform
%   data into "result" data, per FT_ITERFUNC_DERIVED.txt.
% "chanbatchsize" is the number of channels to process at a time. Set this to
%   inf to process all channels at once.
% "trialbatchsize" is the number of trials to process at a time. Set this to
%   inf to process all trials at once.
% "artparams" is a structure containing configuration parameters for
%   nlChan_applyArtifactReject(). Pass "struct([])" to disable artifact
%   rejection.
%   FIXME - This needs to be overhauled to support other artifact options.
% "notch_freqs" is a vector containing frequencies to notch-filter. This can
%   be empty to disable notch filtering.
% "notch_bw" is the bandwidth of the notch filter to use.
% "lfp_corner" is the low-pass corner frequency to use when generating the LFP.
% "lfp_rate" is the rate to downsample the LFP waveform to.
% "spike_corner" is the high-pass corner frequency to use when generating the
%   "spikes only" signal.
% "mua_band" [low high] is the band-pass frequency range to use when
%   generating the multi-unit activity signal prior to rectification.
% "mua_corner" is the low-pass corner frequency to use when generating the
%   multi-unit activity signal after rectification.
% "mua_rate" is the rate to downsample the rectified MUA signal to.
% "verbosity" is an optional argument. It can be set to 'none' (no console
%   output), 'terse' (reporting the number of channels processed), or 'full'
%   (reporting the names of channels processed). The default is 'none'.
%
% "auxdata" is a cell array indexed by {trial,channel} containing the
%   output returned by iterfunc_derived.


if ~exist('verbosity', 'var')
  verbosity = 'none';
end


% Wrap the batch processing function.
% We're not producing new Field Trip data, so just discard that return value.

iterfunc_batched = @( ftdata_old, chanindices_orig, trialindices_orig ) ...
  helper_do_batch_iteration( ftdata_old, chanindices_orig, ...
    trialindices_orig, iterfunc_derived, ...
    artparams, notch_freqs, notch_bw, lfp_corner, lfp_rate, ...
    spike_corner, mua_band, mua_corner, mua_rate );

[ ftdata_new auxdata ] = nlFT_iterateAcrossFolderBatching( ...
  config_load, iterfunc_batched, chanbatchsize, trialbatchsize, verbosity );


% Done.
end


%
% Helper Functions

function [ newwave fracbad ] = ...
  helper_iterate_artifacts( artparams, oldwave, samprate )

  % Don't keep NaNs (interpolate instead), and don't re-reference.
  [ newwave fracbad ] = nlChan_applyArtifactReject( ...
    oldwave, [], samprate, artparams, false );

end


function [ ftdata_new auxdata ] = helper_do_batch_iteration( ...
  ftdata_old, chanindices_orig, trialindices_orig, iterfunc_derived, ...
  artparams, notch_freqs, notch_bw, lfp_corner, lfp_rate, ...
  spike_corner, mua_band, mua_corner, mua_rate )


  % Initialize output.
  ftdata_new = struct([]);
  auxdata = {};


  % We've been given a slice of the larger dataset. Process it.

  trialcount = length(ftdata_old.time);
  chancount = length(ftdata_old.label);


  % Artifact removal happens before any filtering.

  fracbad = zeros(trialcount,chancount);
  fracbad = num2cell(fracbad);

  if ~isempty(artparams)
    iterfunc_art = ...
      @( wavedata, timedata, samprate, trialidx, chanidx, chanlabel ) ...
        helper_iterate_artifacts( artparams, wavedata, samprate );

    [ newtrials fracbad ] = ...
       nlFT_iterateAcrossData( ftdata_old, iterfunc_art );
    ftdata_old.trial = newtrials;
  end


  % Notch filtering.

  if ~isempty(notch_freqs)
    ftdata_old = ...
      euFT_doBrickNotchRemoval( ftdata_old, notch_freqs, notch_bw );
  end


  % Derived signal extraction.

  [ ftdata_lfp ftdata_spike ftdata_mua ] = euFT_getDerivedSignals( ...
    ftdata_old, lfp_corner, lfp_rate, spike_corner, ...
    mua_band, mua_corner, mua_rate );


  % Iterate the user-supplied function across trials and channels.

  % FIXME - We have to do this manually, since we're iterating over several
  % FT datasets rather than a single FT dataset!

  for tidx = 1:trialcount
    realtrial = trialindices_orig(tidx);

    datawb = ftdata_old.trial{tidx};
    timewb = ftdata_old.time{tidx};
    datalfp = ftdata_lfp.trial{tidx};
    timelfp = ftdata_lfp.time{tidx};
    dataspike = ftdata_spike.trial{tidx};
    timespike = ftdata_spike.time{tidx};
    datamua = ftdata_mua.trial{tidx};
    timemua = ftdata_mua.time{tidx};

    for cidx = 1:chancount

      realchan = chanindices_orig(cidx);

      serieswb = datawb(cidx,:);
      serieslfp = datalfp(cidx,:);
      seriesspike = dataspike(cidx,:);
      seriesmua = datamua(cidx,:);

      thisaux = iterfunc_derived( serieswb, timewb, ftdata_old.fsample, ...
        serieslfp, timelfp, ftdata_lfp.fsample, ...
        seriesspike, timespike, ftdata_spike.fsample, ...
        seriesmua, timemua, ftdata_mua.fsample, ...
        realtrial, realchan, ftdata_old.label{cidx} );

      auxdata{tidx,cidx} = thisaux;

    end
  end

end


%
% This is the end of the file.
