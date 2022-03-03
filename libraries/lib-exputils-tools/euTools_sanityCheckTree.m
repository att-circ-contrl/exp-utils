function [ reporttext folderdata ] = ...
  euTools_sanityCheckTree( startdir, config )

% function [ reporttext folderdata ] = ...
%   euTools_sanityCheckTree( startdir, config )
%
% This function searches the specified directory tree for Open Ephys and
% Intan ephys data folders, opens the ephys data files, and checks for
% signal anomalies such as drop-outs and artifacts.
%
% NOTE - This tells Field Trip to use the LoopUtil file I/O hooks. So, it'll
% only work on folders that store data in a way that these support.
%
% "startdir" is the root directory of the tree to search.
% "config" is a structure with some or all of the following fields. Missing
%   fields are set to default values.
%   "wantprogress" is true for progress reports and false otherwise.
%   "readposition" is a number between 0 and 1 indicating where to start
%     reading in the ephys data.
%   "readduration" is the number of seconds of ephys data to read.
%   "chanpatterns" is a cell array containing channel label patterns to
%     process. These are passed to ft_channelselection().
%   "notchfreqs" is a list of frequencies to notch-filter.
%   "notchbandwidth" is the notch bandwidth to use when filtering.
%   "quantization_bits" is the minimum acceptable number of bits of dynamic
%     range in the data.
%   "smoothfreq" is the approximate low-pass corner frequency for smoothing
%     before artifact and dropout checking.
%   "dropout_threshold" is the threshold for detecting drop-outs. This is a
%     multiple of the median value, and should be less than 1.
%   "artifact_threshold" is the threshold for detecting artifacts. This is
%     a multiple of the median value, and should be greater than 1.
%   "frac_samples_bad" is the minimum fraction of bad samples in a channel
%     needed for that channel to be flagged as bad.
%   "lowpasscorner" is the low-pass-filter corner used for generating LFP data.
%   "lowpassrate" is the sampling rate to use when downsampling LFP data.
%   "correlthresabs" is the absolute r-value threshold for considering
%     channels to be correlated. This should be in the range 0..1.
%   "correlthreshrel" is the relative r-value threshold for considering
%     channels to be correlated. This should be greater than 1.
%
% "reporttext" is a character vector containing a human-readable summary
%   of the sanity check.
% "folderdata" is an array of structures with the following fields:
%   "datadir" is the path containing the ephys data files.
%   "config" is a copy of the configuration structure with missing values
%     set to appropriate defaults.
%   "ftheader" is the Field Trip header for the ephys data.
%   "samprange" [min max] is the range of samples read for the test.
%   "isfloating" is a boolean vector indicating whether channels were members
%     of correlated groups (which usually means floating channels).
%   "isquantized" is a boolean vector indicating whether channel data showed
%     quantization.
%   "hadartifacts" is a boolean vector indicating whether channel data had
%     large amplitude excursions (electrical artifacts).
%   "haddropouts" is a boolean vector indicating whether channel data had
%     intervals with no data (usually a throughput problem).


%
% Fill in missing configuration values.

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

if ~isfield(config, 'notchfreqs')
  config.notchfreqs = [ 60 120 180 ];
end
if ~isfield(config, 'notchbandwidth')
  config.notchbandwidth = 2.0;
end

if ~isfield(config, 'quantization_bits')
  config.quantization_bits = 8;
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

if ~isfield(config, 'lowpasscorner')
  config.lowpasscorner = 300;
end
if ~isfield(config, 'lowpassrate')
  config.lowpassrate = 2000;
end

if ~isfield(config, 'correlthreshabs')
  % This is an absolute r-value.
  config.correlthreshabs = 0.95;
end
if ~isfield(config, 'correlthreshrel')
  % This is relative to the median r-value.
  config.correlthreshrel = 4.0;
end


%
% Get a list of Open Ephys and Intan data directories.

alldirs = dir([ startdir filesep '**' ]);
folderlist = {};
for didx = 1:length(alldirs)
  thisfile = alldirs(didx).name;
  if strcmp(thisfile, 'info.rhd') || strcmp(thisfile, 'info.rhs') ...
    || strcmp(thisfile, 'structure.oebin')
    folderlist = [ folderlist { alldirs(didx).folder } ];
  end
end


%
% Traverse the tree, checking each folder.


reporttext = '';
folderdata = struct([]);
foldercount = 0;

if config.wantprogress
  disp(sprintf( '-- Sanity-checking %d folders.', length(folderlist) ));
end

for fidx = 1:length(folderlist)

  thisfolder = folderlist{fidx};

  % If FT runs into a problem, it'll throw an exception. Tolerate that.
  try

    if config.wantprogress
      disp([ '.. Reading "' thisfolder '"...' ]);
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
      'feedback', 'no' );


    % Read the ephys data.

    ephysdata = ft_preprocessing(preproc_config);


    % Check for quantization.

    chan_bits = nlCheck_getFTSignalBits(ephysdata);
    chan_bits = chan_bits{1};
    wasquantized = chan_bits < config.quantization_bits;


    % We need to do notch filtering in order to do similarity-testing.
    % It'll also improve artifact and dropout detection.

    % De-trend. FT should already do this for us, but do it as a precaution.
    ephysdata = ft_preprocessing( ...
      struct( 'detrend', 'yes', 'feedback', 'no' ), ephysdata );

    % Notch filter every frequency we've been given.
    % Only filter the fundamental mode. The user can specify harmonics.
    freqlist = config.notchfreqs;
    for qidx = 1:length(freqlist)
      ephysdata = euFT_doBrickBandStop( ephysdata, freqlist(qidx), 1, ...
        config.notchbandwidth );
    end


    % Check for artifacts and dropouts.

    [ dropout_frac, artifact_frac ] = ...
      nlCheck_testFTDropoutsArtifacts( ephysdata, config.smoothfreq, ...
        config.dropout_threshold, config.artifact_threshold );
    dropout_frac = dropout_frac{1};
    artifact_frac = artifact_frac{1};
    haddropouts = dropout_frac >= config.frac_samples_bad;
    hadartifacts = artifact_frac >= config.frac_samples_bad;


    % Check for correlated signals at low frequency (LFP frequencies).
    % These are usually floating.

    ephysdata = ft_preprocessing( struct( 'lpfilter', 'yes', ...
      'lpfilttype', 'but', 'lpfreq', config.lowpasscorner ), ephysdata );

    % Downsample this as well.
    ephysdata = ft_resampledata( ...
      struct( 'resamplefs', config.lowpassrate, 'detrend', 'no' ), ...
      ephysdata );

    % FIXME - Don't split this by bank. Open Ephys merges it all anyways.
    [ correlgood rvalues correlbadlist ] = nlProc_findCorrelatedChannels( ...
      ephysdata.trial{1}, config.correlthreshabs, config.correlthreshrel );
    wasfloating = ~correlgood;


    % FIXME - Make sure flag vectors are consistently rows or columns.
    % Use columns, to match FT's conventions for channels.
    if ~iscolumn(wasquantized) ; wasquantized = transpose(wasquantized) ; end
    if ~iscolumn(hadartifacts) ; hadartifacts = transpose(hadartifacts) ; end
    if ~iscolumn(haddropouts) ; haddropouts = transpose(haddropouts) ; end
    if ~iscolumn(wasfloating) ; wasfloating = transpose(wasfloating) ; end


    % Build and save the output data structure for this entry.

    thisfolderdata = struct( 'datadir', thisfolder, 'config', config, ...
      'ftheader', thisheader, 'samprange', samprange, ...
      'isquantized', wasquantized, ...
      'hadartifacts', hadartifacts, 'haddropouts', haddropouts, ...
      'isfloating', wasfloating );

    foldercount = foldercount + 1;
    if isempty(folderdata)
      folderdata = thisfolderdata;
    else
      folderdata(foldercount) = thisfolderdata;
    end


    % Build and append the report for this entry.

    thisreport = sprintf('-- Folder "%s":\n', thisfolder);
    thisreport = [ thisreport sprintf( '  %d of %d channels good\n', ...
      sum(~( wasquantized | hadartifacts | haddropouts | wasfloating )), ...
      length(wasquantized) ) ];
    thisreport = [ thisreport sprintf( ...
      '  ( %d quantized, %d artifacts, %d dropouts, %d floating )\n', ...
      sum(wasquantized), sum(hadartifacts), sum(haddropouts), ...
      sum(wasfloating) ) ];

    if config.wantprogress
      disp(thisreport);
    end

    reporttext = [ reporttext thisreport ];

  catch errordetails
    disp([ '###  Exception thrown while reading "' thisfolder '".' ]);
    disp([ 'Message: "' errordetails.message '"' ]);
    for eidx = 1:length(errordetails.stack)
      disp(errordetails.stack(eidx));
    end
  end

end

if config.wantprogress
  disp('-- Finished sanity-checking folders.');
end


% Done.

end


%
% This is the end of the file.
