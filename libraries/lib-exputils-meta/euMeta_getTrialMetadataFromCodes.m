function trialmeta = euMeta_getTrialMetadataFromCodes( ...
   codetable, conditionlut, timecolumn )

% function trialmeta = euMeta_getTrialMetadataFromCodes( ...
%   codetable, conditionlut, timecolumn )
%
% This parses a table of event codes (from euUSE_segmentTrialsByCodes()) and
% produces a structure with per-trial condition metadata and with a list
% of fixations (with metadata).
%
% If "codetable" is a table, it's parsed as one trial. If "codetable" is a
% cell array, each cell is assumed to correspond to a trial, and each trial
% is processed.
%
% "codetable" is a table with event codes seen during a trial. Columns must
%   include 'codeLabel' and 'codeData'. The column specified by "timecolumn"
%   must also be present. If multiple trials are to be parsed, this is a
%   cell array of such tables.
% "conditionlut" is a structure specifying metadata associated with various
%   'BlockCondition' code values, per euMeta_getBlockConditions_xxx.
% "timecolumn" is the column name containing timestamps in "codetable".
%
% "trialmeta" is a structure with the following fields. If multiple trials
%   are processed, this is a structure array:
%   "wasrewarded" is a boolean value indicating whether the 'Rewarded' or
%     'Unrewarded' code was seen.
%   "rewardtime" is the timestamp of the 'Rewarded'/'Unrewarded' code.
%   "wascorrect" is a boolean value indicating whether the 'CorrectResponse'
%     or 'IncorrectResponse' code was seen.
%   "correcttime" is the timestamp of the correct/incorrect response code.
%   "tokensadded" is the 'TokensAdded' code value, or NaN if not seen.
%   "tokentime" is the time the 'TokensAdded' code was seen (NaN if not).
%   "difficulty" is the value of the 'Dimensionality' code, or NaN if not seen.
%   "blockCode" is the 'blockCode' value given by "conditionlut".
%   (Additional fields corresponding to columns in "conditionlut" are also
%    added.)
%   "trial_index" is the TrialIndex code value.
%   "trial_number" is the TrialNumber code value.
%   "lastfixationstart" is the timestamp of the start of the last fixation,
%     or NaN if there were no fixations.
%   "lastfixationend" is the timestamp of the end of the last fixation, or
%     NaN if there were no fixations.
%   "lastfixationtype" is a character vector with the code label of the
%     last fixation's initiation code, or '' if there were no fixations.
%   "fixationlist" is a (possibly empty) structure array with the following
%     fields:
%     "starttime" is the timestamp of the start of the fixation.
%     "endtime" is the timestamp of the end of the fixation.
%     "type" is a character vector with the code label that initiated this
%       fixation.


%
% Figure out what fields the metadata record should have.

emptyfixlist = struct( 'starttime', {}, 'endtime', {}, 'type', {} );

defaultmeta = struct( ...
  'wasrewarded', false, 'rewardtime', nan, ...
  'wascorrect', false, 'correcttime', nan, ...
  'tokensadded', nan, 'tokentime', nan, ...
  'difficulty', nan, ...
  'trial_index', nan, 'trial_number', nan, ...
  'lastfixationstart', nan, 'lastfixationend', nan, ...
  'lastfixationtype', '', 'fixationlist', emptyfixlist );

% Copy blockCode and other fields from the condition LUT.

condfields = conditionlut.Properties.VariableNames;
condmatchvals = conditionlut.blockCode;

for fidx = 1:length(condfields)

  thisfield = condfields{fidx};
  thisval = nan;

  if ~isempty(conditionlut)
    thisval = conditionlut.(thisfield)(1);

    % If this isn't numeric, the default is something other than NaN.
    if iscell(thisval)
      thisval = {};
    elseif ischar(thisval)
      thisval = '';
    elseif islogical(thisval)
      thisval = false;
    elseif isstruct(thisval)
      thisval = struct([]);
    else
      % Numeric. Use NaN.
      thisval = nan;
    end
  end

  defaultmeta.(thisfield) = thisval;

end


%
% Initialize.

% NOTE - We want to initialize to an empty list, in case of zero trials.
trialmeta = defaultmeta(1:0);


%
% Process input.

if iscell(codetable)

  % Multiple trials. Iterate and recurse.

  for tidx = 1:length(codetable)
    trialmeta(tidx) = euMeta_getTrialMetadataFromCodes( ...
      codetable{tidx}, conditionlut, timecolumn );
  end

else

  % Single trial. Process this.

  trialmeta = defaultmeta;

  codelabels = codetable.codeLabel;
  codevalues = codetable.codeData;
  codetimes = codetable.(timecolumn);


  % Information other than block conditions and fixations.


  trialmeta.wasrewarded = any(strcmp( codelabels, 'Rewarded' ));
  scratchidx = min(find(contains( codelabels, 'ewarded' )));
  if ~isempty(scratchidx)
    trialmeta.rewardtime = codetimes(scratchidx);
  end

  trialmeta.wascorrect = any(strcmp( codelabels, 'CorrectResponse' ));
  scratchidx = min(find(contains( codelabels, 'orrectResponse' )));
  if ~isempty(scratchidx)
    trialmeta.correcttime = codetimes(scratchidx);
  end


  scratchidx = min(find(strcmp( codelabels, 'TokensAdded' )));
  if ~isempty(scratchidx)
    trialmeta.tokensadded = codevalues(scratchidx);
    trialmeta.tokentime = codetimes(scratchidx);
  end


  scratchidx = min(find(strcmp( codelabels, 'Dimensionality' )));
  if ~isempty(scratchidx)
    trialmeta.difficulty = codevalues(scratchidx);
  end


  scratchidx = min(find(strcmp( codelabels, 'TrialIndex' )));
  if ~isempty(scratchidx)
    trialmeta.trial_index = codevalues(scratchidx);
  end

  scratchidx = min(find(strcmp( codelabels, 'TrialNumber' )));
  if ~isempty(scratchidx)
    trialmeta.trial_number = codevalues(scratchidx);
  end


  % Block condition information.

  rowidx = find(strcmp( codelabels, 'BlockCondition' ));
  if ~isempty(rowidx)
    thiscond = codevalues(rowidx(1));
    condidx = find( thiscond == condmatchvals );
    if ~isempty(condidx)
      for fidx = 1:length(condfields)
        thisfield = condfields{fidx};
        trialmeta.(thisfield) = conditionlut.(thisfield)(condidx);
      end
    end
  end


  % Fixations.
  % Look for "FixObjectEnd" and work back to find what was fixated on.

  thisfixlist = emptyfixlist;

  allfixends = find(strcmp( codelabels, 'FixObjectEnd' ));
  allfixstarts = [];
  for lidx = 1:length(codelabels)
    tokenlist = regexp( codelabels{lidx}, '(Fix\w+Start)', 'tokens' );
    if length(tokenlist) > 0
      allfixstarts = [ allfixstarts lidx ];
    end
  end

  for fidx = 1:length(allfixends)
    idxend = allfixends(fidx);
    idxstart = max(allfixstarts( allfixstarts < idxend ));
    if isempty(idxstart)
      % Fixation end without start. FIXME - Not reporting.
    else
      thisfixrec = struct( 'starttime', codetimes(idxstart), ...
        'endtime', codetimes(idxend), 'type', codelabels{idxstart} );
      thisfixlist = [ thisfixlist thisfixrec ];
    end
  end

  trialmeta.fixationlist = thisfixlist;

  if ~isempty(thisfixlist)
    thisfixrec = thisfixlist( length(thisfixlist) );

    trialmeta.lastfixationstart = thisfixrec.starttime;
    trialmeta.lastfixationend = thisfixrec.endtime;
    trialmeta.lastfixationtype = thisfixrec.type;
  end

end


% Done.
end


%
% This is the end of the file.
