function [ reportshort reportlong folderdata ] = ...
  euTools_sanityCheckTree( startdir, config )

% function [ reportshort reportlong folderdata ] = ...
%   euTools_sanityCheckTree( startdir, config )
%
% This function searches the specified directory tree for Open Ephys and
% Intan ephys data folders, opens the ephys data files, and checks for
% signal anomalies such as drop-outs and artifacts.
%
% NOTE - This tells Field Trip to use the LoopUtil file I/O hooks. So, it'll
% only work on folders that store data in a way that these support.
%
% NOTE - Channel correlation time goes up as the square of the number of
% channels!
%
% NOTE - Channel correlation may give misleading results if different probes
% are compared to each other. The workaround is to call this function with
% "chanpatterns" set to match a single probe's channels, if that becomes a
% problem.
%
% "startdir" is the root directory of the tree to search.
% "config" is a structure with some or all of the following fields. Missing
%   fields are set to default values.
%
%   "wantprogress" is true for progress reports and false otherwise.
%   "readposition" is a number between 0 and 1 indicating where to start
%     reading in the ephys data.
%   "readduration" is the number of seconds of ephys data to read.
%   "chanpatterns" is a cell array containing channel label patterns to
%     process. These are passed to ft_channelselection().
%
%   "notchfreqs" is a list of frequencies to notch-filter.
%   "notchbandwidth" is the notch bandwidth to use when filtering.
%   "lowpasscorner" is the low-pass-filter corner used for separating LFP
%     and spike data.
%   "lowpassrate" is the sampling rate to use when downsampling LFP data.
%
%   "wantquantization" is true to check for quantization and false otherwise.
%   "quantization_bits" is the minimum acceptable number of bits of dynamic
%     range in the data.
%
%   "wantartifacts" is true to check for artifacts and drop-outs and false
%     otherwise.
%   "smoothfreq" is the approximate low-pass corner frequency for smoothing
%     before artifact and dropout checking.
%   "dropout_threshold" is the threshold for detecting drop-outs. This is a
%     multiple of the median value, and should be less than 1.
%   "artifact_threshold" is the threshold for detecting artifacts. This is
%     a multiple of the median value, and should be greater than 1.
%   "frac_samples_bad" is the minimum fraction of bad samples in a channel
%     needed for that channel to be flagged as bad.
%
%   "wantcorrel" is true to check for correlated groups of channels and false
%     otherwise.
%   "correlthreshabs" is the absolute r-value threshold for considering
%     channels to be correlated. This should be in the range 0..1.
%   "correlthreshrel" is the relative r-value threshold for considering
%     channels to be correlated. This should be greater than 1.
%
%   "wantspect" is true to check the LFP power spectrum and false otherwise.
%   "spectrange" [ min max ] is the range of frequencies to perform the LFP
%     power spectrum fit over.
%   "spectbinwidth" is the relative width of LFP power spectrum frequency
%     bins. A value of 0.1 would mean a bin width of 0.1 times each bin's
%     center frequency.
%
% "reportshort" is a character vector containing a human-readable summary
%   of the sanity check.
% "reportlong" is a character vector containing a much more detailed
%   human-readable summary of the sanity check.
% "folderdata" is an array of structures with the following fields:
%
%   "datadir" is the path containing the ephys data files.
%   "config" is a copy of the configuration structure with missing values
%     set to appropriate defaults.
%   "ftheader" is the Field Trip header for the ephys data.
%   "samprange" [min max] is the range of samples read for the test.
%   "chanlist" is a cell array with the names of selected channels.
%
%   "isquantized" is a boolean vector indicating whether channel data showed
%     quantization.
%   "hadartifacts" is a boolean vector indicating whether channel data had
%     large amplitude excursions (electrical artifacts).
%   "haddropouts" is a boolean vector indicating whether channel data had
%     intervals with no data (usually a throughput problem).
%
%   "lfpchangroups" is a vector indicating which correlated LFP groups
%      channels were members of. Contacts on the same probe or from probes
%      that are very close to each other will tend to have correlated LFPs.
%      Channels that don't strongly correlate have NaN as a group.
%   "lfpgroupdefs" is a cell array with one cell per LFP group containing
%      vectors indicating which channels (from "chanlist") were in the group.
%   "rvalues_lfp" is a square matrix containing correlation coefficients
%      between LFP channels.
%   "spikechangroups" is a vector indicating which correlated spike groups
%      channels were members of. Floating channels in the same probe or
%      headstage will tend to have correlated high-frequency signals.
%      Channels that don't strongly correlate have NaN as a group.
%   "spikegroupdefs" is a cell array with one cell per spike group containing
%      vectors indicating which channels (from "chanlist") were in the group.
%   "rvalues_spike" is a square matrix containing correlation coefficients
%      between LFP channels.
%
%   "lfpfitexponents" is a vector containing the exponent of power-law fits
%      to each channel's LFP power spectrum. A clean LFP should be -1 to -2.
%   "lfpfitlabels" is a cell array containing a human-readable type label
%      for each channel's LFP power spectrum, per nlProc_examineLFPSpectrum.


%
% Fill in missing configuration values.


% General config.

if ~isfield(config, 'wantprogress')
  config.wantprogress = true;
end

if ~isfield(config, 'readposition')
  config.readposition = 0.5;
end
if ~isfield(config, 'readduration')
  config.readduration = 20;
end

if ~isfield(config, 'chanpatterns')
  % NOTE - These are device-specific and the user can usually modify them.
  config.chanpatterns = { 'Amp*', 'CH*' };
end


% Signal conditioning.

if ~isfield(config, 'notchfreqs')
  config.notchfreqs = [ 60 120 180 ];
end
if ~isfield(config, 'notchbandwidth')
  config.notchbandwidth = 2.0;
end

if ~isfield(config, 'lowpasscorner')
  config.lowpasscorner = 300;
end
if ~isfield(config, 'lowpassrate')
  config.lowpassrate = 2000;
end


% Quantization checking.

if ~isfield(config, 'wantquantization')
  config.wantquantization = true;
end

if ~isfield(config, 'quantization_bits')
  config.quantization_bits = 8;
end


% Artifact and dropout checking.

if ~isfield(config, 'wantartifacts')
  config.wantartifacts = true;
end

if ~isfield(config, 'smoothfreq')
  config.smoothfreq = 50;
end
if ~isfield(config, 'dropout_threshold')
  config.dropout_threshold = 0.3;
end
if ~isfield(config, 'artifact_threshold')
  config.artifact_threshold = 5;
end
if ~isfield(config, 'frac_samples_bad')
  config.frac_samples_bad = 0.01;
end


% Correlated channel group checking.

if ~isfield(config, 'wantcorrel')
  config.wantcorrel = true;
end

if ~isfield(config, 'correlthreshabs')
  % This is an absolute r-value.
  config.correlthreshabs = 0.95;
end
if ~isfield(config, 'correlthreshrel')
  % This is relative to the median r-value.
  config.correlthreshrel = 4.0;
end


% LFP power spectrum checking.

if ~isfield(config, 'wantspect')
  config.wantspect = true;
end

if ~isfield(config, 'spectrange')
  config.spectrange = [ 4 200 ];
end
if ~isfield(config, 'spectbinwidth')
  config.spectbinwidth = 0.03;
end


%
% Get a list of Open Ephys and Intan data directories.

[ dirs_opene dirs_intanrec dirs_intanstim dirs_use ] = ...
  euUtil_getExperimentFolders( startdir );

folderlist = [ dirs_opene dirs_intanrec dirs_intanstim ];



%
% Traverse the tree, checking each folder.


reportshort = '';
reportlong = '';

folderdata = struct([]);
foldercount = 0;

if config.wantprogress
  disp(sprintf( '-- Sanity-checking %d folders.', length(folderlist) ));
end

for fidx = 1:length(folderlist)

  thisfolder = folderlist{fidx};

  % If FT runs into a problem, it'll throw an exception. Tolerate that.
%  try

    if config.wantprogress
      disp([ '-- Reading "' thisfolder '".' ]);
    end

    % Read the FT header.
    thisheader = ...
      ft_read_header( thisfolder, 'headerformat', 'nlFT_readHeader' );


    % Get appropriate metadata from the header, and use it to get any auxiliary
    % information we need.

    % NOTE - We're assuming continuous data (only touching the first trial).

    chancount = thisheader.nChans;
    sampcount = thisheader.nSamples;
    samprate = thisheader.Fs;

    firstsamp = round(config.readposition * sampcount);
    lastsamp = firstsamp + round(config.readduration * samprate);
    lastsamp = min(lastsamp, sampcount);
    firstsamp = min(firstsamp, lastsamp);
    samprange = [ firstsamp lastsamp ];


    % Build a configuration structure for reading data.
    % NOTE - We're reading in native format. This loses scale information
    % but lets us check for quantization. It's promoted to double either way.

    chanlist = ...
      ft_channelselection( config.chanpatterns, thisheader.label, {} );

    if isempty(chanlist)
      disp(sprintf( '###  0 of %d channels selected!', ...
        length(thisheader.label) ));

      % FIXME - Bail out of this loop iteration to avoid trying to read
      % zero channels. FT doesn't like that.
      continue;
    elseif true && config.wantprogress
      % FIXME - Diagnostics.
      disp(sprintf( '.. %d of %d channels selected.', ...
        length(chanlist), length(thisheader.label) ));
    end

    preproc_config = struct( ...
      'headerfile', thisfolder, 'headerformat', 'nlFT_readHeader', ...
      'datafile', thisfolder, 'dataformat', 'nlFT_readDataNative', ...
      'channel', {chanlist}, 'trl', [ firstsamp lastsamp 0 ], ...
      'detrend', 'yes', 'feedback', 'no' );

    % Update channel count to reflect selected channels.
    chancount = length(chanlist);


    % Initialize the per-folder reports and output data.

    thisreportshort = sprintf('-- Folder "%s":\n', thisfolder);
    thisreportlong = sprintf('-- Folder "%s":\n', thisfolder);

    % Remember to wrap cell arrays.
    thisfolderdata = struct( 'datadir', thisfolder, 'config', config, ...
      'ftheader', thisheader, 'samprange', samprange, ...
      'chanlist', {chanlist} );


    % Read the ephys data.

    ephysdata = ft_preprocessing(preproc_config);


    % Check for quantization.
    % Do this before notch filtering.

    if config.wantquantization

      if config.wantprogress
        disp('.. Checking for quantization...');
      end

      chan_bits = nlCheck_getFTSignalBits(ephysdata);
      chan_bits = chan_bits{1};

      wasquantized = chan_bits < config.quantization_bits;

      % Make this a column vector to match FT's conventions.
      if ~iscolumn(wasquantized)
         wasquantized = transpose(wasquantized);
      end

      thisfolderdata.('isquantized') = wasquantized;

    end


    % NOTE - Doing notch filtering before checking for artifacts and dropouts.
    % Ringing from the filter _may_ mask dropouts, but the narrow-band signal
    % that we're getting rid of _will_ mask artifacts (it's usually loud).

    if config.wantprogress
      disp('.. Performing notch filtering...');
    end

    ephysdata = euFT_doBrickNotchRemoval( ...
      ephysdata, config.notchfreqs, config.notchbandwidth );


    % Check for artifacts and dropouts.

    if config.wantartifacts

      if config.wantprogress
        disp('.. Checking for artifacts and drop-outs...');
      end

      [ dropout_frac, artifact_frac ] = ...
        nlCheck_testFTDropoutsArtifacts( ephysdata, config.smoothfreq, ...
          config.dropout_threshold, config.artifact_threshold );

      dropout_frac = dropout_frac{1};
      artifact_frac = artifact_frac{1};
      haddropouts = dropout_frac >= config.frac_samples_bad;
      hadartifacts = artifact_frac >= config.frac_samples_bad;

      % Make these column vectors to match FT's conventions.
      if ~iscolumn(hadartifacts)
        hadartifacts = transpose(hadartifacts);
      end
      if ~iscolumn(haddropouts)
        haddropouts = transpose(haddropouts);
      end

      thisfolderdata.('haddropouts') = haddropouts;
      thisfolderdata.('hadartifacts') = hadartifacts;

    end


    % Make a readable summary of quantization, artifacts, and dropouts.

    % Make placeholders for tests we didn't do.
    if ~(config.wantquantization)
      wasquantized = false(chancount, 1);
    end
    if ~(config.wantartifacts)
      haddropouts = false(chancount, 1);
      hadartifacts = false(chancount, 1);
    end

    scratch = sprintf( '  %d of %d channels valid\n', ...
      sum(~( wasquantized | hadartifacts | haddropouts )), ...
      length(wasquantized) );
    scratch = [ scratch sprintf( ...
      '  ( %d quantized, %d artifacts, %d dropouts )\n', ...
      sum(wasquantized), sum(hadartifacts), sum(haddropouts) ) ];

    thisreportshort = [ thisreportshort scratch ];
    thisreportlong = [ thisreportlong scratch ];

    thisreportlong = [ thisreportlong sprintf('  Quantized:\n    ') ...
      helper_listFlaggedChans( wasquantized, chanlist ) ];
    thisreportlong = [ thisreportlong sprintf('\n  Artifacts:\n    ') ...
      helper_listFlaggedChans( hadartifacts, chanlist ) ];
    thisreportlong = [ thisreportlong sprintf('\n  Drop-outs:\n    ') ...
      helper_listFlaggedChans( haddropouts, chanlist ) ];
    thisreportlong = [ thisreportlong sprintf('\n  End of list.\n') ];


    % Get the LFP if we're looking at spectra or correlations.

    if config.wantcorrel || config.wantspect

      if config.wantprogress
        disp('.. Extracting LFP signals...');
      end

      thisconfig = struct( 'feedback', 'no', 'lpfilter', 'yes', ...
        'lpfilttype', 'but', 'lpfreq', config.lowpasscorner );
      lfpdata = ft_preprocessing( thisconfig, ephysdata );

      thisconfig = struct( 'feedback', 'no', ...
        'resamplefs', config.lowpassrate, 'detrend', 'no' );
      lfpdata = ft_resampledata( thisconfig, lfpdata );

    end


    % Check for correlated signals at low frequency (LFP frequencies) and
    % high frequencies (spike frequencies).
    % Correlated high-frequency signals are usually floating or grounded.
    % Correlated LFP signals belong to the same probe or are from two probes
    % at nearly the same position.

    if config.wantcorrel

      % Get the high-pass (spike) waveform.
      % Overwrite the wideband waveform, as we've finished with that.

      if config.wantprogress
        disp('.. Extracting high-pass signals...');
      end

      thisconfig = struct( 'feedback', 'no', 'hpfilter', 'yes', ...
        'hpfilttype', 'but', 'hpfreq', config.lowpasscorner );
      ephysdata = ft_preprocessing( thisconfig, ephysdata );


      % Finally, do correlation.
      % FIXME - This can take a very long time!

      if config.wantprogress
        disp('.. Checking for LFP correlations...');
        tic;
      end

      [ lfpchangroups rvalues_lfp lfpgroupdefs ] = ...
        nlProc_findCorrelatedChannels( lfpdata.trial{1}, ...
        config.correlthreshabs, config.correlthreshrel );

      if config.wantprogress
        disp(sprintf( '.. Finished in %d seconds.', round(toc) ));
        disp('.. Checking for high-pass correlations...');
        tic;
      end

      [ spikechangroups rvalues_spike spikegroupdefs ] = ...
        nlProc_findCorrelatedChannels( ephysdata.trial{1}, ...
        config.correlthreshabs, config.correlthreshrel );

      if config.wantprogress
        disp(sprintf( '.. Finished in %d seconds.', round(toc) ));
      end


      % Make these column vectors to match FT's conventions.

      if ~iscolumn(lfpchangroups)
        lfpchangroups = transpose(lfpchangroups);
      end
      if ~iscolumn(spikechangroups)
        spikechangroups = transpose(spikechangroups);
      end

      % Add this to the data record.

      thisfolderdata.('lfpchangroups') = lfpchangroups;
      thisfolderdata.('lfpgroupdefs') = lfpgroupdefs;
      thisfolderdata.('rvalues_lfp') = rvalues_lfp;

      thisfolderdata.('spikechangroups') = spikechangroups;
      thisfolderdata.('spikegroupdefs') = spikegroupdefs;
      thisfolderdata.('rvalues_spike') = rvalues_spike;

      % Generate reports.

      scratchmask = isnan(lfpchangroups);
      scratch = sprintf( '  %d of %d LFP channels were not in a group\n', ...
        sum(scratchmask), length(scratchmask) );

      thisreportshort = [ thisreportshort scratch ];
      thisreportlong = [ thisreportlong scratch ];

      thisreportlong = [ thisreportlong sprintf('  Lone channels:\n    ') ...
        helper_listFlaggedChans( scratchmask, chanlist ) sprintf('\n') ];

      scratchmask = ~isnan(spikechangroups);
      scratch = sprintf( '  %d of %d spike channels had crosstalk\n', ...
        sum(scratchmask), length(scratchmask) );

      thisreportshort = [ thisreportshort scratch ];
      thisreportlong = [ thisreportlong scratch ];

      thisreportlong = [ thisreportlong ...
        sprintf('  Crosstalk channels:\n    ') ...
        helper_listFlaggedChans( scratchmask, chanlist ) ];

      thisreportlong = [ thisreportlong sprintf('\n  End of list.\n') ];

    end


    if config.wantspect

      if config.wantprogress
        disp('.. Curve-fitting LFP power spectrum...');
      end

      fitexponents = [];
      fitlabels = {};

      for cidx = 1:chancount
        [ isgood thislabel thisexponent ...
          powerlistraw freqlist powerlistfit ] = ...
          nlProc_examineLFPSpectrum( lfpdata.trial{1}(cidx,:), ...
            config.lowpassrate, config.spectrange, config.spectbinwidth );

        fitexponents(cidx) = thisexponent;
        fitlabels{cidx} = thislabel;
      end

      % Make these column vectors to match FT's conventions.
      if ~iscolumn(fitexponents)
        fitexponents = transpose(fitexponents);
      end
      if ~iscolumn(fitlabels)
        fitlabels = transpose(fitlabels);
      end


      % Add this to the data record.

      thisfolderdata.('lfpfitexponents') = fitexponents;
      thisfolderdata.('lfpfitlabels') = fitlabels;

      % Generate reports.

      scratchmask = strcmp('lfp', fitlabels) | strcmp('lfpbad', fitlabels);
      scratch = sprintf( '  %d of %d LFP channels look like LFPs\n', ...
        sum(scratchmask), length(scratchmask) );

      thisreportshort = [ thisreportshort scratch ];
      thisreportlong = [ thisreportlong scratch ];

      thisreportlong = [ thisreportlong sprintf('  Channel LFPs:\n') ...
        helper_listLFPs(chanlist, fitexponents, fitlabels), ...
        sprintf('  End of list.\n') ];

    end


    % Save this folder's reports and output data.

    if config.wantprogress
      disp(thisreportshort);
    end

    reportshort = [ reportshort thisreportshort ];
    reportlong = [ reportlong thisreportlong ];

    foldercount = foldercount + 1;
    if isempty(folderdata)
      folderdata = thisfolderdata;
    else
      folderdata(foldercount) = thisfolderdata;
    end


    if config.wantprogress
      disp([ '-- Finished with "' thisfolder '".' ]);
    end

%  catch errordetails
%    disp([ '###  Exception thrown while reading "' thisfolder '".' ]);
%    disp([ 'Message: "' errordetails.message '"' ]);
%    for eidx = 1:length(errordetails.stack)
%      disp(errordetails.stack(eidx));
%    end
%  end

end

if config.wantprogress
  disp('-- Finished sanity-checking folders.');
end


% Done.

end



%
% Helper Functions


function message = helper_listFlaggedChans( flagvec, chanlist )

  message = '';

  % Sort the input lists before displaying.
  [ chanlist sortidx ] = sort(chanlist);
  flagvec = flagvec(sortidx);

  for cidx = 1:length(chanlist)
    if flagvec(cidx)
      if ~isempty(message)
        message = [ message '   ' ];
      end
      message = [ message chanlist{cidx} ];
    end
  end

end


function message = helper_listLFPs( chanlist, fitexponents, fitlabels )

  message = '';

  % Sort the input lists before displaying.
  [ chanlist sortidx ] = sort(chanlist);
  fitexponents = fitexponents(sortidx);
  fitlabels = fitlabels(sortidx);

  for cidx = 1:length(chanlist)
    message = [ message sprintf( '%12s :   exp %4.1f   (%s)\n', ...
      chanlist{cidx}, fitexponents(cidx), fitlabels{cidx} ) ];
  end
end


%
% This is the end of the file.
