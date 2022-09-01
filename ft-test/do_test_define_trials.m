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
% Load cached time-aligned event data if we don't already have it.

if ~exist('times_recorder_game', 'var')
  fname_aligned = [ datadir filesep 'events_aligned.mat' ];

  if ~isfile(fname_aligned)
    % No time-aligned data. Abort the script and send the user back to
    % the Matlab prompt.
    error('Can''t define trials without time alignment information.');
  else
    disp('-- Loading time-aligned Unity events and alignment tables.');
    load(fname_aligned);
    disp('-- Finished loading.');
  end
end


%
% Build trial definitions.


% First pass: Segment the event code sequence into trials.
% Use Unity's list of event codes, since it's guaranteed to exist.

% Calling this twice, so that we get the unfiltered and filtered lists.

[ trialcodes_raw trialcodes_concat ] = ...
  euUSE_segmentTrialsByCodes( gamecodes, 'codeLabel', '', false);

[ trialcodes_valid trialcodes_concat ] = ...
  euUSE_segmentTrialsByCodes( gamecodes, 'codeLabel', 'codeData', true);



% Second pass: Iterate through the list of alignment cases, building
% trial definitions for each case.

samprate = rechdr.Fs;

aligncases = fieldnames(trialaligncodes);
trialdefs = struct();
trialdeftables = struct();
trialdefcolumns = {};

for cidx = 1:length(aligncases)

  thisalignlabel = aligncases{cidx};
  thisaligncodelist = trialaligncodes.(thisalignlabel);

  codemetawanted = ...
    struct( 'trialnum', 'TrialNumber', 'trialindex', 'TrialIndex' );

  % FIXME - Only taking the first element in trialstartcodes, trialendcodes,
  % and thisaligncodelist.
  [ thistrialdef thistrialtab ] = euFT_defineTrialsUsingCodes( ...
    vertcat(trialcodes_valid{:}), 'codeLabel', 'recTime', samprate, ...
    trialstartpadsecs, trialendpadsecs, ...
    trialstartcodes{1}, trialendcodes{1}, thisaligncodelist{1}, ...
    codemetawanted, 'codeData' );

  trialdefs.(thisalignlabel) = thistrialdef;
  trialdeftables.(thisalignlabel) = thistrialtab;

  % Save a list of metadata column names.
  trialdefcolumns = thistrialtab.Properties.VariableNames;

  % Write this case's trial definitions out as CSV for debugging.
  fname = [ datadir filesep 'trialdefs-' thisalignlabel '.csv' ];
  writetable(thistrialtab, fname);

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
% This is the end of the file.
