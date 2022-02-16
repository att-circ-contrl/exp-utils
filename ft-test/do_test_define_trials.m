% Field Trip sample script / test script - Trial definitions.
% Written by Christopher Thomas.

% This processes event code data and produces Field Trip trial definition
% structures, along with metadata tables.
% FIXME - Doing this by reading and setting workspace variables directly.
%
% Variables that get set:
%   trialcodes_raw
%   trialcodes_valid
%   trialdefs
%   trialdefcolumns
%   trialdeftables


%
% Build trial definitions.


% First pass: Segment the event code sequence into trials.
% Use Unity's list of event codes, since it's guaranteed to exist.

allcodes = gamecodes;
codelabels = allcodes.codeLabel;

trialcodes_raw = {};
segcount = 0;
prevstart = NaN;

for cidx = 1:length(codelabels);
  thislabel = codelabels{cidx};

  if strcmp('TrlStart', thislabel)
    % Check for malformed trials.
    if ~isnan(prevstart)
      disp(sprintf( '###  "TrlStart" inside a trial at line %d.', cidx ));
    end

    % Start or restart the trial.
    prevstart = cidx;
  elseif strcmp('TrlEnd', thislabel)
    % Check for malformed trials.
    if isnan(prevstart)
      disp(sprintf( '###  "TrlEnd" without trial start at line %d.', cidx ));
    else
      % Only create a trial record if we ended a correctly-formed trial.
      % Save the in-trial portion of the code table.
      segcount = segcount + 1;
      trialcodes_raw{segcount} = allcodes(prevstart:cidx,:);
    end

    % End the trial no matter what.
    prevstart = NaN;
  end
end


% Filter the list of trials to only contain "valid" trials.

% FIXME - I'm not clear on how to do this. Marcus said that TrialNumber only
% increments after valid trials, and that there's an abort code to look for
% for other trials, but that filtering based on these wasn't a great idea.

% So, stick a user-defined function here to do it the way you want.

trialcodes_valid = doSelectGoodTrials(trialcodes_raw);



% Second pass: Iterate through the list of alignment cases, building
% trial definitions for each case.

samprate = rechdr.Fs;
trialdefs = struct();
trialdeftables = struct();
aligncases = fieldnames(trialaligncodes);

% FIXME - Magic values. These are the labels of the trial matrix columns.
% The first three are FT's required columns. Additional columns get copied
% to a "trialinfo" matrix. This can only contain numeric data.
% To get full event data for a trial, load trialcodes_valid{validindex}.

trialdefcolumns = { 'sampstart', 'sampend', 'sampoffset', ...
  'validindex', 'trialindex', 'trialnum', ...
  'rectimestart', 'rectimeend', 'rectimeevent' };

for cidx = 1:length(aligncases)

  thisalignlabel = aligncases{cidx};
  thisaligncodelist = trialaligncodes.(thisalignlabel);

  thistrialdef = [];
  thistrialcount = 0;

  for tidx = 1:length(trialcodes_valid)

    thistable = trialcodes_valid{tidx};
    thislabellist = thistable.codeLabel;

    % Find the span to save.

    timestart = NaN;
    timestop = NaN;

    thisridx = helper_findRow(thislabellist, trialstartcodes, 'last');
    if ~isnan(thisridx)
      timestart = thistable.recTime(thisridx);
    end

    thisridx = helper_findRow(thislabellist, trialendcodes, 'first');
    if ~isnan(thisridx)
      timestop = thistable.recTime(thisridx);
    end

    % Find the event to align to.

    timealign = NaN;

    thisridx = helper_findRow(thislabellist, thisaligncodelist, 'first');
    if ~isnan(thisridx)
      timealign = thistable.recTime(thisridx);
    end


    % If we found everything we're looking for, create a trial definition.
    % Save metadata as extra columns.
    if (~isnan(timestart)) && (~isnan(timestop)) && (~isnan(timealign))

      thistrialcount = thistrialcount + 1;

      % FIXME - Per above, our desired columns are:
      % sampstart, sampend, sampoffset (FT's required columns)
      % validindex, trialindex, trialnum
      % rectimestart, rectimeend, rectimevent

      timestart = timestart - trialstartpadsecs;
      timestop = timestop + trialendpadsecs;

      sampstart = round(timestart * samprate);
      sampstop = round(timestop * samprate);
      sampalign = round(timealign * samprate);

      validindex = tidx;
      trialindex = NaN;
      trialnum = NaN;

      % These should always exist but bulletproof it anyways.

      thisridx = helper_findRow(thislabellist, {'TrialIndex'}, 'last');
      if ~isnan(thisridx)
        trialindex = thistable.codeData(thisridx);
      end

      thisridx = helper_findRow(thislabellist, {'TrialNumber'}, 'last');
      if ~isnan(thisridx)
        trialnum = thistable.codeData(thisridx);
      end

      % Offset is negative if the trial starts before the trigger.
      thistrialdef(thistrialcount,:) = ...
        [ sampstart, sampstop, (sampstart - sampalign), ...
          validindex, trialindex, trialnum, timestart, timestop, timealign ];

    end

  end


  % Save this trial definition matrix. This is empty if we found no trials.
  trialdefs.(thisalignlabel) = thistrialdef;


  % Make a copy of the augmented trial definition as a proper table with
  % readable labels. Save this as a CSV file as well.

  trialtab = table();

  for lidx = 1:length(trialdefcolumns)
    thiscolumn = [];
    if ~isempty(thistrialdef)
      thiscolumn = thistrialdef(:,lidx);
    end
    trialtab.(trialdefcolumns{lidx}) = thiscolumn;
  end

  trialdeftables.(thisalignlabel) = trialtab;

  fname = [ datadir filesep 'trialdefs-' thisalignlabel '.csv' ];
  writetable(trialtab, fname);

end



%
% Save variables to disk, if requested.

% NOTE - There isn't much point, since these are fast to generate, but we
% might want it for auditing purposes.

if want_save_data
  fname = [ datadir filesep 'trialmetadata.mat' ];

  if isfile(fname)
    delete(fname);
  end

  disp('-- Saving trial definition metadata.');

  save( fname, ...
    'trialcodes_raw', 'trialcodes_valid', ...
    'trialdefs', 'trialdefcolumns', 'trialdeftables', ...
    '-v7.3' );

  disp('-- Finished saving.');
end



%
% Helper functions.


% This finds an entry in the first list that matches one of the labels in
% the second list.
%
% "rowlabels" is a cell array containing labels to search.
% "desiredlabels" is a cell array containing valid matches for the search.
% "order" is 'first' to return the index of the earliest match or 'last' to
%   return the index of the latest match.
%
% "rowindex" is the index of the matching entry, or NaN if no match was found.

function rowindex = helper_findRow(rowlabels, desiredlabels, order)

  matchlist = [];

  for didx = 1:length(desiredlabels)
    thismatch = strcmp(rowlabels, desiredlabels{didx});
    if ~isrow(thismatch)
      thismatch = transpose(thismatch);
    end
    matchlist = [ matchlist find(thismatch) ];
  end

  if strcmp('last', order)
    rowindex = max(matchlist);
  else
    rowindex = min(matchlist);
  end

  if isempty(rowindex)
    rowindex = NaN;
  end

% Done.

end



%
% This is the end of the file.
