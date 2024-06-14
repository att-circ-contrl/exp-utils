function newdevstruct = euHLev_augmentEphysEvents( olddevstruct, ...
  boxevents, addttl, folder_openephys, folder_intanrec, folder_intanstim )

% function newdevstruct = euHLev_augmentEphysEvents( olddevstruct, ...
%   boxevents, addttl, folder_openephys, folder_intanrec, folder_intanstim )
%
% This does two things: Adds missing events that were sent but not detected
% to the ephys device event lists, and optionally adds pseudo event codes to
% the list of recorded codes for TTL reward and synch pulses.
%
% This is a wrapper for euAlign_copyMissingEventTables() and
% euFT_addTTLEventsAsCodes().
%
% Folders are needed so that we can read device headers and get the
% sampling rates. Folders given as '' are skipped.
%
% "olddevstruct" is a structure containing each device's cooked event tables,
%   per euUSE_readAllEphysEvents(). Missing devices' fields contain
%   struct([]).
%   "openephys" contains event tables from Open Ephys.
%   "intanrec" contains event tables from the Intan recording controller.
%   "intanstim" contains event tables from the Intan stimulation controller.
% "boxevents" is a structure containing SynchBox event data tables.
% "addttl" is true to add TTL events to the event code list, false otherwise.
% "folder_openephys" is the location of the Open Ephys data.
% "folder_intanrec" is the location of the Intan recording controller data.
% "folder_instanstim" is the location of the Intan stim controller data.
%
% "newdevstruct" is a copy of "olddevstruct" with missing events added and
%   with TTL events added as event code events.


% Fall back to safe output.
newdevstruct = olddevstruct;


% Bail out if we don't have synchbox events.
% We can get struct([]) here if it failed to find the synchbox logs.
if isempty(boxevents)
  return;
end


%
% FIXME - Magic values. Device metadata.

devmeta = struct( ...
  'label', { 'openephys', 'intanrec', 'intanstim' }, ...
  'folder', { folder_openephys, folder_intanrec, folder_intanstim }, ...
  'timecolumn', { 'recTime', 'recTime', 'stimTime' } );

ttlmeta = struct( ...
  'label', { 'rwdA', 'rwdB', 'synchA', 'synchB' }, ...
  'code', { 'TTLRwdA', 'TTLRwdB', 'TTLSynchA', 'TTLSynchB' } );



%
% Iterate through target devices.

for devidx = 1:length(devmeta)

  % See if we have this device.

  thisdev = devmeta(devidx);
  have_device = false;

  if isfield( newdevstruct, thisdev.label )
    if ~isempty( newdevstruct.(thisdev.label) )
      if ~isempty( thisdev.folder )
        have_device = true;
      end
    end
  end

  % Skip the rest of the loop if we don't have this device.
  if ~have_device
    continue;
  end


  % Get this device's sampling rate.

  % NOTE - Field Trip will throw an exception if this fails.
  % Add a try/catch block if we have to fail gracefully.
  ftheader = ft_read_header( ...
    thisdev.folder, 'headerformat', 'nlFT_readHeader' );

  samprate = ftheader.Fs;


  % Extract this device's event tables.
  evtables = newdevstruct.(thisdev.label);


  % Add any event tables that were missing.

  evtables = euAlign_copyMissingEventTables( boxevents, evtables, ...
    thisdev.timecolumn, samprate );


  % Iterate through TTL event channels, adding them as event codes.

  if addttl
    if ~isfield( evtables, 'cookedcodes' )
      disp([ '###  No "cookedcodes" event table in device "' ...
        thisdev.label '"!' ]);
    else

      for ttlidx = 1:length(ttlmeta)
        thissig = ttlmeta(ttlidx);

        if isfield( evtables, thissig.label )
          evtables.cookedcodes = euFT_addTTLEventsAsCodes( ...
            evtables.cookedcodes, evtables.(thissig.label), ...
            thisdev.timecolumn, 'codeLabel', thissig.code );
        end
      end

    end
  end


  % Save the modified event tables.
  newdevstruct.(thisdev.label) = evtables;


  % Finished with this device.

end



% Done.
end


%
% This is the end of the file.
