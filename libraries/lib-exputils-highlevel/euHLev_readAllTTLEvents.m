function [ boxevents gameevents evcodedefs gamereftime ...
  deveventsraw deveventscooked devnames ] = euHLev_readAllTTLEvents( ...
  signaldefs, foldergame, folderopenephys, folderintanrec, folderintanstim )

% function [ boxevents gameevents evcodedefs gamereftime ...
%   deveventsraw deveventscooked devnames ] = euHLev_readAllTTLEvents( ...
%   signaldefs, foldergame, folderopenephys, folderintanrec, folderintanstim )
%
% This reads event data and metadata from USE and from the ephys machines,
% parses boolean and event code TTL signals, and returns what it found.
%
% The enormous time offset that USE timestamps normally have is subtracted.
% Intan recorder and Open Ephys recorder events get a 'recTime' column added.
% Intan stimulator events get a 'stimTime' column. These timestamps are in
% seconds.
%
% This is a wrapper for the following functions:
%   euUSE_readAllUSEEvents()
%   euUSE_readAllEphysEvents()
%   euUSE_removeLargeTimeOffset()
%   euFT_addEventTimestamps()
%
% "signaldefs" is a top-level TTL definition structure per TTLSIGNALDEFS.txt.
% "foldergame" is the game data folder, or '' to not read game data.
% "folderopenephys" is a folder containing ephys data saved by Open Ephys,
%   or '' to not read Open Ephys data.
% "folderintanrec" is a folder containing ephys data saved by an Intan
%   recording controller, or '' to not read Intan recorder data.
% "folderintanstim" is a folder containing ephys data saved by an Intan
%   stimulation controller, or '' to not read Intan stimulator data.
%
% "boxevents" is a structure containing SynchBox event data tables, or
%   struct([]) if unable to read game data.
% "gameevents" is a structure containing USE event data tables, or
%   struct([]) if unable to read game data.
% "evcodedefs" is a USE event code definition structure per EVCODEDEFS.txt,
%   or struct([]) if unable to read game data.
% "gamereftime" is the reference time subtracted from Unity timestamps. These
%   otherwise end up being relative to 1 Jan 1970 (huge values).
% "deveventsraw" is a structure containing each device's raw Field Trip
%   event list, per euUSE_readAllEphysEvents(). Missing devices' fields
%   contain struct([]):
%   "openephys" contains the event list from Open Ephys.
%   "intanrec" contains the event list from the Intan recording controller.
%   "intanstim" contains the event list from the Intan stimulation controller.
% "deveventscooked" is a structure containing each device's cooked event
%   tables, per euUSE_readAllEphysEvents(). Missing devices' fields contain
%   struct([]):
%   "openephys" contains event tables from Open Ephys.
%   "intanrec" contains event tables from the Intan recording controller.
%   "intanstim" contains event tables from the Intan stimulation controller.
% "devnames" is a structure indexed by device label containing human-readable
%   device names.


% Initialize to safe values.

boxevents = struct([]);
gamevents = struct([]);
evcodedefs = struct([]);

deveventsraw = struct();
deveventsraw.openephys = struct([]);
deveventsraw.intanrec = struct([]);
deveventsraw.intanstim = struct([]);

deveventscooked = struct();
deveventscooked.openephys = struct([]);
deveventscooked.intanrec = struct([]);
deveventscooked.intanstim = struct([]);



%
% Load game data, if we have any.

if ~isempty(foldergame)
  % Use the default code format, code size, and code endianness.
  [ boxevents gameevents evcodedefs ] = euUSE_readAllUSEEvents( foldergame );

  % Make timestamps relative to the smallest timestamp seen, to avoid the
  % enormous 1 Jan 1970 offset.
  [ gamereftime gameevents ] = ...
    euUSE_removeLargeTimeOffset( gameevents, 'unityTime' );

  % For the second call, pass the reference time as an argument to ensure
  % consistency.
  [ scratch boxevents ] = ...
    euUSE_removeLargeTimeOffset( boxevents, 'unityTime', gamereftime );
end



%
% Load ephys events.

devtypes = { 'openephys', 'intanrec', 'intanstim' };

devfolders = struct( 'openephys', folderopenephys, ...
  'intanrec', folderintanrec, 'intanstim', folderintanstim );
devnames = struct( 'openephys', 'Open Ephys', ...
  'intanrec', 'Intan recorder', 'intanstim', 'Intan stimulator' );

devtimestampcolumns = struct( 'openephys', 'recTime', ...
  'intanrec', 'recTime', 'intanstim', 'stimTime' );

for devidx = 1:length(devtypes)

  thisdev = devtypes{devidx};

  thisfolder = devfolders.(thisdev);
  thisname = devnames.(thisdev);

  devtimecolumn = devtimestampcolumns.(thisdev);

  devbitdefs = struct([]);
  devworddefs = struct([]);

  if isfield(signaldefs, ['bits_' thisdev])
    devbitdefs = signaldefs.(['bits_' thisdev]);
  end
  if isfield(signaldefs, ['codes_' thisdev])
    devworddefs = signaldefs.(['codes_' thisdev]);
  end

  % The reading function will tolerate struct([]) and struct(), so only
  % bail out if we're asked for nothing or have no folders.

  if (~isempty(thisfolder))
    if (~isempty(devbitdefs)) || (~isempty(devworddefs))

      % Use the default code size and code endianness.
      [ rawevents cookedevents ] = euUSE_readAllEphysEvents( ...
        thisfolder, devbitdefs, devworddefs, evcodedefs );

      % Read the header (to get the sampling rate) and augment events
      % with timestamps in seconds.
      thisheader = ...
        ft_read_header( thisfolder, 'headerformat', 'nlFT_readHeader' );
      samprate = thisheader.Fs;

      % This expects a top-level structure containing lists, so wrap the
      % raw event list.

      rawstruct = struct();
      rawstruct.raw = rawevents;
      rawstruct = euFT_addEventTimestamps( ...
        rawstruct, samprate, 'sample', devtimecolumn );
      rawevents = rawstruct.raw;

      cookedevents = euFT_addEventTimestamps( ...
        cookedevents, samprate, 'sample', devtimecolumn );

      % Store this device's event lists.
      deveventsraw.(thisdev) = rawevents;
      deveventscooked.(thisdev) = cookedevents;

    end
  end

end


% Done.
end


%
% This is the end of the file.
