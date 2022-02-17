function newlist = doSelectGoodTrials(oldlist)

% function newlist = doSelectGoodTrials(oldlist)
%
% This accepts a list of per-trial event code sequences, identifies and
% discards "bad" trials, and returns a list containing event code sequences
% for the "good" trials.
%
% FIXME - This is a placeholder function that looks for TrialNumber
% incrementing. Use your own filtering routines for real data.
% FIXME - This always discards the final trial, since we aren't sure if
% the index incremented or not after it.
%
% "oldlist" is a cell array containing per-trial event code tables.
%
% "newlist" is a copy of "oldlist" containing only "good" trials.


% FIXME - Select trials where TrialNumber incremented.
% FIXME - This always discards the final trial, since we aren't sure if
% the index incremented or not after it.

newlist = {};
newcount = 0;
for tidx = 2:length(oldlist)
  prevtable = oldlist{tidx-1};
  thistable = oldlist{tidx};

  prevline = prevtable(strcmp(prevtable.codeLabel, 'TrialNumber'),:);
  thisline = thistable(strcmp(thistable.codeLabel, 'TrialNumber'),:);

  if (~isempty(prevline)) && (~isempty(thisline))
    if thisline.codeData ~= prevline.codeData
      % We just incremented TrialNumber.
      % This means the "previous" trial was valid.
      newcount = newcount + 1;
      newlist{newcount} = prevtable;
    end
  end
end


% Done.

end


%
% This is the end of the file.
