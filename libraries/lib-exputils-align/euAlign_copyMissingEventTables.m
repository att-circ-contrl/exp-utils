function newtarget = ...
  euAlign_copyMissingEventTables( evsource, oldtarget, timelabel, samprate )

% function newtarget = ...
%   euAlign_copyMissingEventTables( evsource, oldtarget, timelabel, samprate )
%
% This function augments a structure containing event tables with new event
% tables copied from a different structure. Timestamps from the specified
% column are translated to sample counts in the new event tables.
%
% "evsource" is a structure with zero or more fields. Each field contains
%   an event table that is to be copied. Empty tables are not copied.
% "oldtarget" is a structure with zero or more fields. Each field contains
%   an event table. Event tables that are missing or empty are replaced.
% "timelabel" is the name of the table column in "evsource" to use when
%   generating sample counts in "newtarget".
% "samprate" is the sampling rate to use when translating timestamps in
%   seconds into sample counts.
%
% "newtarget" is a copy of "oldtarget" with any missing or empty tables
%   overwritten with translated non-empty tables from "evsource".


% Initialize output.
newtarget = oldtarget;


% Walk through the source structure, copying where appropriate.

srcfields = fieldnames(evsource);

for sidx = 1:length(srcfields)

  thistabname = srcfields{sidx};
  thissrctab = evsource.(thistabname);
  srclabels = thissrctab.Properties.VariableNames;

  if isempty(thissrctab)
    % As a special case, copy empty tables that are missing in the target.
    if ~isfield(oldtarget, thistabname)
      newtarget.(thistabname) = thissrctab;
    end
  else
    % This is a non-empty table. If the target doesn't have it, copy it.

    need_copy = true;
    if isfield(oldtarget, thistabname)
      if ~isempty( oldtarget.(thistabname) )
        need_copy = false;
      end
    end

    if need_copy
      if ~ismember(timelabel, srclabels)
        disp([ '###  Asked to copy event table "' thistabname ...
          '" but can''t find time column "' timelabel '".' ]);
      else
        % FIXME - Tattle.
        disp([ '.. Translating event table "' thistabname '".' ]);

        timeseries = thissrctab.(timelabel);

        % Remember that time 0 is sample 1.
        thissrctab.sample = 1 + round(timeseries * samprate);

        % Offset and duration are optional fields expressed in samples.
        % FIXME - We can't translate these without the original sampling
        % rate, so remove them.

        if ismember('offset', srclabels)
          thissrctab.offset = [];
        end
        if ismember('duration', srclabels)
          thissrctab.duration = [];
        end

        newtarget.(thistabname) = thissrctab;
      end
    end
  end

end


% Done.

end


%
% This is the end of the file.
