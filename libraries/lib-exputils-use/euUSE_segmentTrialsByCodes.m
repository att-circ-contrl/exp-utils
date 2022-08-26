function [ pertrialtabs alltrialtab ] = ...
  euUSE_segmentTrialsByCodes( rawtab, labelfield, valuefield, discardbad )

% function [ pertrialtabs alltrialtab ] = ...
%   euUSE_segmentTrialsByCodes( rawtab, labelfield, valuefield, discardbad )
%
% This function processes a table containing event code sequences, segmenting
% the sequence into trials and optionally discarding bad trials.
%
% Trials are demarked by 'TrlStart' and 'TrlEnd' codes. "Good" trials are
% those for which 'TrialNumber' incremented.
%
% Additional columns in "rawtab" are copied to the output tables. These are
% typically things like timestamps.
%
% "rawtab" is the table to process. It must contain columns with event code
%   labels and (if discarding bad trials) event code data values.
% "labelfield" is the name of the table column that has code label character
%   arrays.
% "valuefield" is the name of the table column that has code data values.
%   This is ignored if bad trials aren't being filtered.
% "discardbad" is true if bad trials are to be discarded and false otherwise.
%
% "pertrialtabs" is a cell array containing event code sequence tables for
%   each trial.
% "alltrialtab" is an event code sequence table containing all trials
%   (equal to the concatenated contents of "pertrialtabs").


% Initialize.

pertrialtabs = {};
alltrialtab = table();


%
% Build the segmented tables.

codelabels = rawtab.(labelfield);

segcount = 0;
prevstart = NaN;

for cidx = 1:length(codelabels);
  thislabel = codelabels{cidx};

  if strcmp('TrlStart', thislabel)
    % Check for malformed trials.
    if ~isnan(prevstart)
      disp(sprintf( '###  "TrlStart" inside a trial at row %d.', cidx ));
    end

    % Start or restart the trial.
    prevstart = cidx;
  elseif strcmp('TrlEnd', thislabel)
    % Check for malformed trials.
    if isnan(prevstart)
      disp(sprintf( '###  "TrlEnd" without trial start at row %d.', cidx ));
    else
      % Only create a trial record if we ended a correctly-formed trial.
      % Save the in-trial portion of the code table.
      segcount = segcount + 1;
      pertrialtabs{segcount} = rawtab(prevstart:cidx,:);
    end

    % End the trial no matter what.
    prevstart = NaN;
  end
end


%
% Optionally, filter the segments.

if discardbad
  keeplist = [];
  keepcount = 0;

  % NOTE - We're always discarding the last trial, since we can't tell if
  % the trial number was incremented after it or not.

  for tidx = 2:length(pertrialtabs)
    prevtable = pertrialtabs{tidx-1};
    thistable = pertrialtabs{tidx};

    prevline = prevtable(strcmp(prevtable.(labelfield), 'TrialNumber'),:);
    thisline = thistable(strcmp(thistable.(labelfield), 'TrialNumber'),:);

    if (~isempty(prevline)) && (~isempty(thisline))
      if thisline.(valuefield) ~= prevline.(valuefield)
        % We just incremented TrialNumber.
        % This means the "previous" trial was valid.
        keepcount = keepcount + 1;
        keeplist(keepcount) = tidx-1;
      end
    end
  end

  pertrialtabs = pertrialtabs(keeplist);
end


%
% Concatenate the remaining segments.

alltrialtab = vertcat(pertrialtabs{:});


% Done.

end


%
% This is the end of the file.
