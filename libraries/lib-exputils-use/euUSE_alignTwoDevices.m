function [ alignedevents timecorresp ] = euUSE_alignTwoDevices( ...
  eventtables, firsttimecol, secondtimecol, alignconfig )

% function [ alignedevents timecorresp ] = euUSE_alignTwoDevices( ...
%   eventtables, firsttimecol, secondtimecol, alignconfig )
%
% This function performs time alignment between two devices by examining
% correlated event sequences between the devices.
%
% This is a wrapper for "euAlign_alignTables()".
%
% NOTE - If it can't find events in common, it centers the time series on
% each other (using the maximum extents of each source). If it can't even do
% that (for example if one source has no events of any type), it lines them
% up by fiat (declaring missing extents to be 0 to 3600 seconds).
% FIXME - We should really have a return flag to indicate this. Right now
% it just shows up on console output.
%
% "eventtables" is a Nx2 cell array. Each row contains two tables with
%   events that ostensibly match each other. The first row where both tables
%   are non-empty is used for alignment.
% "firsttimecol" is the name of the timestamp column in tables stored in
%   column 1 of "eventtables".
% "secondtimecol" is the name of the timestamp column in tables stored in
%   column 2 of "eventtables".
% "alignconfig" is a structure with zero or more of the following fields:
%   "coarsewindows" is a vector with coarse alignment window half-widths.
%   "medwindows" is a vector with medium alignment window half-widths.
%   "finewindow" is the window half-width for final non-uniform alignment.
%   "outliersigma" is the threshold for rejecting spurious matches.
%   "verbosity" is 'verbose', 'normal', or 'quiet'.
%   Missing fields will be set to reasonable defaults.
%
% "alignedevents" is a copy of "eventtables" with the tables in column 1
%   augmented with "secondtimecol" timestamps and the tables in column 2
%   augmented with "firsttimecol" timestamps.
% "timecorresp" is a table with "firsttimecol" and "secondtimecol" columns,
%   containing tuples with known-good time alignment. This is the "canonical"
%   set of timestamps used to interpolate time values between tables.


% Get a fully populated configuration structure.

alignconfig = euAlign_getDefaultAlignConfig(alignconfig);


%
% First pass: Look for pairs of tables and also get extents.


firstmin = inf;
firstmax = -inf;
secondmin = inf;
secondmax = -inf;

tuplerow = nan;

[evrows evcols] = size(eventtables);

for ridx = 1:evrows
  firsttable = eventtables{ridx,1};
  secondtable = eventtables{ridx,2};

  if ~isempty(firsttable)
    firsttimes = firsttable.(firsttimecol);
    firstmin = min(firstmin, min(firsttimes));
    firstmax = max(firstmax, max(firsttimes));
  end

  if ~isempty(secondtable)
    secondtimes = secondtable.(secondtimecol);
    secondmin = min(secondmin, min(secondtimes));
    secondmax = max(secondmax, max(secondtimes));
  end

  % Give priority to the first fully-populated row.
  if isnan(tuplerow) && (~isempty(firsttable)) && (~isempty(secondtable))
    tuplerow = ridx;
  end
end


% If we didn't get extents, fake them.

firstextents = [ 0 3600 ];
if isfinite(firstmin) && isfinite(firstmax)
  firstextents = [ firstmin firstmax ];
else
  disp('###  Couldn''t find time extents for first series! Faking it.');
end

secondextents = [ 0 3600 ];
if isfinite(secondmin) && isfinite(secondmax)
  secondextents = [ secondmin secondmax ];
else
  disp('###  Couldn''t find time extents for second series! Faking it.');
end



%
% Second pass: Get the official correspondence table.


if isnan(tuplerow)

  disp('###  No corresponding event tables; faking alignment with extents!');

  timecorresp = euAlign_fakeAlignmentWithExtents( ...
    firsttimecol, firstextents, secondtimecol, secondextents );

else

  firsttable = eventtables{tuplerow, 1};
  secondtable = eventtables{tuplerow, 2};


  % FIXME - Check for event codes (align-by-data) by black magic.
  % Raw synchbox and game codes have "codeValue".
  % Cooked synchbox and game codes have "codeWord".
  % The corresponding ephys event column is "value".
  % Boolean events have "value" too, though, so switch based on "codeValue"
  % and "codeWord".

  firstcols = firsttable.Properties.VariableNames;
  secondcols = secondtable.Properties.VariableNames;

  iscodefirst = true;
  firstvaluefield = 'value';
  if ismember('codeValue', firstcols)
    firstvaluefield = 'codeValue';
  elseif ismember('codeWord', firstcols)
    firstvaluefield = 'codeWord';
  else
    iscodefirst = false;
  end

  iscodesecond = true;
  secondvaluefield = 'value';
  if ismember('codeValue', secondcols)
    secondvaluefield = 'codeValue';
  elseif ismember('codeWord', secondcols)
    secondvaluefield = 'codeWord';
  else
    iscodesecond = false;
  end

  % If neither table has "codeWord" or "codeValue", we're not dealing with
  % event codes. Don't compare data.
  if (~iscodefirst) && (~iscodesecond)
    firstvaluefield = '';
    secondvaluefield = '';
  end


  % Do the alignment.
  % We're discarding the augmented tables here, and just keeping timecorresp.

  [ firsttable, secondtable, firstmask, secondmask, timecorresp ] = ...
    euAlign_alignTables( firsttable, secondtable, ...
      firsttimecol, secondtimecol, firstvaluefield, secondvaluefield, ...
      alignconfig.coarsewindows, alignconfig.medwindows, ...
      alignconfig.finewindow, alignconfig.outliersigma, ...
      alignconfig.verbosity );

end


%
% Third pass: Augment all tables with aligned timestamps.

alignedevents = {};
for ridx = 1:evrows
  firsttable = eventtables{ridx, 1};
  secondtable = eventtables{ridx, 2};

  if ~isempty(firsttable)
    % This tolerates "can't translate" and "already translated" situations.
    firsttable = euAlign_addTimesToTable( ...
      firsttable, firsttimecol, secondtimecol, timecorresp );
  end

  if ~isempty(secondtable)
    % This tolerates "can't translate" and "already translated" situations.
    secondtable = euAlign_addTimesToTable( ...
      secondtable, secondtimecol, firsttimecol, timecorresp );
  end

  alignedevents{ridx,1} = firsttable;
  alignedevents{ridx,2} = secondtable;
end



% Done.

end


%
% This is the end of the file.
