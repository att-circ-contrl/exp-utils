function dataset = euUSE_translateGazeIntoSignals( ...
  gazetable, timecol, ignorecols, samprate )

% function dataset = euUSE_translateGazeIntoSignals( ...
%   gazetable, timecol, ignorecols, samprate )
%
% This translates tabular gaze data read from USE into a Field Trip data
% structure containing continuous waveform data.
%
% NOTE - The signal names produced by this will vary depending on the
% eye-tracker used.
%
% NOTE - Do not pick a sampling rate that exactly matches the eye-tracker
% rate. That will almost certainly result in beat frequencies in the data.
%
% "gazetable" is a table containing raw USE gaze data.
% "timecol" is the label of the table column to read timestamps from.
% "ignorecols" is a cell array containing labels of columns to not copy.
% "samprate" is the sampling rate to use for the output data.
%
% "dataset" is a ft_datatype_raw structure containing gaze data signals.


%
% Get a list of columns we're keeping.

keepcols = gazetable.Properties.VariableNames;

keepmask = ~strcmp(timecol, keepcols);
for cidx = 1:length(ignorecols)
  keepmask = keepmask & (~strcmp(ignorecols{cidx}, keepcols));
end

keepcols = keepcols(keepmask);



%
% Build interpolated data.

% NOTE - Using linear interpolation rather than filter-based resampling.
% Filtering can take a lot of time and/or memory and give peculiar results.

origtimes = gazetable.(timecol);
firsttime = min(origtimes);
lasttime = max(origtimes);
sampcount = 1 + round ( (lasttime - firsttime) * samprate );

newtimes = 1:sampcount;
newtimes = (newtimes - 1) / samprate;

chancount = length(keepcols);

% Preallocate the output.
wavedata = zeros(chancount,sampcount);

% Build the output channel by channel.
for cidx = 1:chancount
  origdata = gazetable.(keepcols{cidx});
  wavedata(cidx,:) = ...
    interp1( origtimes, origdata, newtimes, 'linear', 'extrap' );
end



%
% Build a plausible-looking header.

if ~iscolumn(keepcols)
  keepcols = transpose(keepcols);
end

chantype = cell(size(keepcols));
chanunit = cell(size(keepcols));
chantype(:) = { 'analog' };
chanunit(:) = { 'unknown' };

% Guess at which columns are flags. This is mostly-cosmetic.
boolmask = contains(keepcols, 'valid');
chantype(boolmask) = { 'boolean' };
chanunit(boolmask) = { 'boolean' };

header = struct( 'Fs', samprate, 'nChans', chancount, ...
  'nSamples', sampcount, 'nSamplesPre', 0, 'nTrials', 1 );

header.label = keepcols;
header.chantype = chantype;
header.chanunit = chanunit;



%
% Build the output data structure.

% Remember to wrap cell arrays in {}.

dataset = struct( 'label', {keepcols}, 'time', {{newtimes}}, ...
  'trial', {{wavedata}}, 'hdr', header );

% FIXME - Not running this through "ft_datatype_raw()". That would force
% sanity/consistency but would also duplicate the data.



% Done.

end


%
% This is the end of the file.
