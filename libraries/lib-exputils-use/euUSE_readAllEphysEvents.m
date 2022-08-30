function [ ttlevents cookedevents ] = ...
  euUSE_readAllEphysEvents( ephysfolder, bitsignaldefs, codesignaldefs, ...
  evcodedefs, codebytes, codeendian )

% function [ ttlevents cookedevents ] = ...
%   euUSE_readAllEphysEvents( ephysfolder, bitsignaldefs, codesignaldefs, ...
%   evcodedefs, codebytes, codeendian )
%
% This function reads TTL events from one ephys device and parses these into
% synch, reward, and event code events.
%
% This is a wrapper for the following functions:
%   ft_read_header()
%   ft_read_event()
%   euFT_getSingleBitEvent()
%   euFT_getCodeWordEvent()
%   euUSE_cleanEventsTabular()
%   euUSE_reassembleEventCodes()
%
% NOTE - Channel specifiers (individual or wildcard-based) have the format
% used by ft_channelselection().
%
% "ephysfolder" is the folder containing "structure.oebin", "info.rhd", or
%   "info.rhs".
% "bitsignaldefs" is a structure indexed by signal name, with each field
%   containing the TTL channel name with that signal's events.
%   If the structure is empty, no single-bit signals are recorded.
% "codesignaldefs" is a structure with the following fields:
%   "signameraw" is the output event code signal name for untranslated bytes.
%   "signamecooked" is the output event code signal name for event codes.
%   "channame" is the TTL channel name to convert. This may be a single
%     channel (for word-based TTL data) or a wildcard expression (for
%     single-bit TTL data).
%   "bitshift" is the number of bits to shift to the right, if reassembling
%     from bits. This is also used to compensate for 1-based numbering (the
%     channel names for bit lines are assumed to start at 0).
%   If there's only one matching channel, it's assumed to contain word data.
%   otherwise it's assumed to contain bit data.
%   If the structure is empty, no event codes are recorded.
% "evcodedefs" is a USE event code definition structure per EVCODEDEFS.txt.
% "codebytes" is the number of bytes used to encode each event code.
%   This defaults to 2 if unspecified.
% "codeendian" is 'big' if the most significant byte is received first or
%   'little' if the least-significant byte is received first.
%   This defaults to 'big' if unspecified.
%
% "ttlevents" is the raw TTL event list returned by ft_read_event().
% "cookedevents" is a structure with one field per signal listed in
%   "bitsignaldefs" and "codesignaldefs". Each field contains a table
%   of matching events whose columns correspond to the event list's fields.
%   These tables may be empty if no events were found.


% FIXME - Set defaults if not specified.

if ~exist('codebytes', 'var')
  codebytes = 2;
end

if ~exist('codeendian', 'var')
  codeendian = 'big';
end


%
% First pass: Get the raw TTL events.

% NOTE - Field Trip will throw an exception if this fails. Wrap this to
% catch exceptions.

% Initialize to an empty array.
ttlevents = struct([]);

try

  disp('-- Reading raw TTL events.');

  ephyshdr = ft_read_header( ephysfolder, 'headerformat', 'nlFT_readHeader' );

  ttlevents = ft_read_event( ephysfolder, ...
    'headerformat', 'nlFT_readHeader', 'eventformat', 'nlFT_readEvents' );

  % NOTE - Fall back to reading waveforms if we failed to read events.
  if isempty(ttlevents)
    disp('.. No TTL events found. Trying again using waveforms.');
    ttlevents = ft_read_event( ephysfolder, ...
      'headerformat', 'nlFT_readHeader', ...
      'eventformat', 'nlFT_readEventsContinuous' );
  end

catch errordetails
  disp(sprintf( ...
    '### Exception thrown while reading "%s".', ephysfolder ));
  disp(sprintf( 'Message: "%s"', errordetails.message ));

  % Continue with an empty event list.
end

if isempty(ttlevents)
  disp('-- No events found!');
else
  disp('-- Finished reading raw TTL events.');
end


%
% Second pass: If we have an event list, look for SynchBox signals.

% Initialize to an empty structure.
cookedevents = struct();

if ~isempty(ttlevents)

  disp('-- Looking for SynchBox signals in ephys data.');

  % Look for single-bit events.

  if (~isempty(bitsignaldefs)) && (~isempty(fieldnames(bitsignaldefs)))
    bitsiglist = fieldnames(bitsignaldefs);
    for bidx = 1:length(bitsiglist)
      thissig = bitsiglist{bidx};
      thischan = bitsignaldefs.(thissig);
      thisspec = struct();
      thisspec.(thissig) = { thischan };
      [ thisevtab have_events ] = euFT_getSingleBitEvent( ...
        thisspec, thissig, ephyshdr.label, ttlevents );
      % If we found events, keep only rising edges.
      if have_events
        thisevtab = thisevtab(thisevtab.value > 0,:);
      end
      % An empty table is fine.
      cookedevents.(thissig) = thisevtab;
    end
  end


  % Look for event codes.

  if (~isempty(codesignaldefs)) && (~isempty(fieldnames(codesignaldefs)))

    % Set the bit shift if we don't have one.
    if ~isfield(codesignaldefs, 'bitshift')
      codesignaldefs.bitshift = 0;
    end

    % Build a structure for euFT_getCodeWordEvent().
    getcodestruct = struct( 'codechans', codesignaldefs.channame, ...
      'codeshift', codesignaldefs.bitshift );

    % Figure out how many matching channels we have, to see if we're dealing
    % with bit data or word data (or no data).
    codechanlist = ...
      ft_channelselection( codesignaldefs.channame, ephyshdr.label, {} );

    % Read codes using the appropriate method.
    if isempty(codechanlist)
      disp('-- No event codes found!');
      thiscodesraw = table();
      have_codes = false;
    elseif 1 == length(codechanlist)
      disp('-- Reading event codes as words.');
      [ thiscodesraw have_codes ] = euFT_getCodeWordEvent( ...
        getcodestruct, 'codechans', 'bogus', 0, 'codeshift', ...
        ephyshdr.label, ttlevents );
    else
      disp('-- Reading event codes from bit lines.');
      [ thiscodesraw have_codes ] = euFT_getCodeWordEvent( ...
        getcodestruct, 'bogus', 'codechans', 0, 'codeshift', ...
        ephyshdr.label, ttlevents );
    end

    % Squash event code values of zero; that's the idle state.
    % Merge codes that repeat the same timestamp or that are one sample apart.
    % These use the FT event column labels ("sample", "value", "type",
    % "offset", "duration").
    thiscodesraw = ...
      euUSE_cleanEventsTabular( thiscodesraw, 'value', 'sample' );

    % Reassemble raw bytes into cooked codes.
    [ thiscodescooked origlocations ] = euUSE_reassembleEventCodes( ...
      thiscodesraw, evcodedefs, codebytes, codeendian, 'value' );

    % Store the resulting tables, which may be empty.
    cookedevents.(codesignaldefs.signameraw) = thiscodesraw;
    cookedevents.(codesignaldefs.signamecooked) = thiscodescooked;

  end


  % Finished looking for events.

  disp('-- Finished looking for SynchBox signals.');

end


% Done.

end


%
% This is the end of the file.
