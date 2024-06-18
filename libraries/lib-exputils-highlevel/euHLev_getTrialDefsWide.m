function [ codesbytrial trl trltab ] = euHLev_getTrialDefsWide( ...
  datafolder, evtable, evtimefield, padsecs, aligncode, prunemethod )

% function [ codesbytrial trl trltab ] = euHLev_getTrialDefsWide( ...
%   datafolder, evtable, evtimefield, padsecs, aligncode, prunemethod )
%
% This function generates a Field Trip "trl" matrix defining trials to be
% read using ft_preprocessing.
%
% Trials span from the 'TrlStart' code to the 'TrlEnd' code, and are aligned
% to have t=0 at a user-specified code. The intention is that these trial
% definitions are used to read wideband data for pre-processing, and that
% ft_redefinetrial is used to realign and crop them for further analysis
% after filtering and artifact rejection.
%
% This is a wrapper for euUSE_segmentTrialsByCodes() and
% euFT_defineTrialsUsingCodes().
%
% "datafolder" is the path to the ephys data folder (for FT header data).
% "evtable" is a table containing event information. This must contain
%   the specified time field, a 'codeLabel' field, and a 'codeData' field.
% "evtimefield" is the name of the table column to read timestamps from.
%   This is typically 'recTime' or 'stimTime'.
% "padsecs" is the number of seconds to add before 'TrlStart' and after
%   'TrlEnd' in trials. This may be cropped if it would extend past the end
%   of the recorded data.
% "aligncode" is the name of the event code to use as t=0. If this isn't
%   found in the trial, the trial is skipped.
% "prunemethod" is 'keep', 'strict', or 'forgiving'. This determines whether
%   we discard trials where TrialNumber isn't incremented.
%
% "codesbytrial" is a cell array containing event code tables for each trial.
% "trl" is a Field Trip trial definition matrix, per ft_definetrial(). This
%   includes additional metadata columns (for trial number and trial index).
% "trltab" is a table containing the same trial definition data as "trl",
%   with column names.


% Get FT metadata.

fthdr = ft_read_header( datafolder, 'headerformat', 'nlFT_readHeader' );
samprate = fthdr.Fs;


% Get per-trial event codes.
% Optionally discard trials that don't increment TrialNumber.

[ codesbytrial codesconcat ] = euUSE_segmentTrialsByCodes( ...
  evtable, 'codeLabel', 'codeData', prunemethod );


% Get trial definitions using these codes.

desiredmeta = struct( 'trialnum', 'TrialNumber', 'trialindex', 'TrialIndex' );

[ trl trltab ] = euFT_defineTrialsUsingCodes( ...
  codesconcat, 'codeLabel', evtimefield, samprate, padsecs, padsecs, ...
  'TrlStart', 'TrlEnd', aligncode, desiredmeta, 'codeData' );



% FIXME - Modify the list of codes by trial to match the list of trials.
% These can be different if there were trials where the alignment code
% wasn't found (those trials would have been discarded).

keepmask = false(size(codesbytrial));
trigtimes = trltab.timetrigger;

% Avoid precision issues if we aligned to TrlStart or TrlEnd.
epsilon_secs = 1e-4;

for tidx = 1:length(keepmask)

  % Trials that we want to keep have a trigger time that falls inside them.

  thistrial = codesbytrial{tidx};
  thistimelist = thistrial.(evtimefield);
  mintime = min(thistimelist) - epsilon_secs;
  maxtime = max(thistimelist) + epsilon_secs;

  thismask = (trigtimes >= mintime) & (trigtimes <= maxtime);
  keepmask(tidx) = any(thismask);

end

% Filter the codes-by-trial list.
codesbytrial = codesbytrial(keepmask);


% Done.
end


%
% This is the end of the file.
