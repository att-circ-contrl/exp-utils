function [ trl trltab ] = euFT_defineTrialsUsingCodes( ...
  eventtable, labelfield, timefield, samprate, padbefore, padafter, ...
  startlabel, stoplabel, alignlabel, codemetatosave, codevaluefield )

% function trl = euFT_defineTrialsUsingCodes( ...
%   eventtable, labelfield, timefield, samprate, padbefore, padafter, ...
%   startlabel, stoplabel, alignlabel, codemetatosave, codevaluefield )
%
% This function generates a Field Trip "trl" matrix from a USE event code
% table. The first three columns of "trl" are the starting sample, ending
% sample, and trigger offset (per ft_definetrial()). Remaining columns are
% metadata, which ft_preprocess() will move to a "trialinfo" matrix.
%
% The "trltab" table is a table containing the same data as "trl". This
% may be used to get column labels for "trl" (as metadata would otherwise
% be hard to identify).
%
% NOTE - The first three columns in 'trltab' are named 'sampstart',
% 'sampend', and 'sampoffset'. The original timestamps for the start, stop,
% and alignment events are saved in 'timestart', 'timeend', and 'timetrigger'.
%
% This can tolerate event labels that are numbers or character arrays.
%
% "eventtable" is a table containing event information. This must at minimum
%   contain event labels and timestamps.
% "labelfield" is the name of the event table column holding event labels.
% "timefield" is the name of the event table column holding timestamps.
% "samprate" is the sampling rate to use for converting timestamps into sample
%   indices.
% "padbefore" is the number of seconds to add before the trial-start event.
% "padafter" is the number of seconds to add after the trial-end event.
% "startlabel" is the event label that indicates the start of a trial.
% "stoplabel" is the event label that indicates the end of a trial.
% "alignlabel" is the event label that indicates the trigger to align trials
%    with.
% "codemetatosave" is a structure describing event code value information to
%    be saved as trial metadata. Each field is an output metadata column
%    name, and that field's value is the event label to look for. When that
%    event label is seen, the event value (from "valuefield") is saved as
%    metadata.
% "codevaluefield" is the name of the event table column holding event values.
%    This is only needed if "codemetatosave" is non-empty.
%
% "trl" is a Field Trip trial definition matrix, per ft_definetrial(). This
%   includes additional metadata columns.
% "trltab" is a table containing the same trial definition data as "trl",
%   with column names.


% Initialize.

trl = [];
trltab = table();


%
% Scan through the event data collecting everything we need.
% Do this sequentially to catch malformed trials.

codemetafields = fieldnames(codemetatosave);
trialcount = 0;
intrial = false;

evlabels = eventtable.(labelfield);
evtimes = eventtable.(timefield);

evvalues = [];
emptymetastruct = struct();
if ~isempty(codemetafields)
  evvalues = eventtable.(codevaluefield);
  for fidx = 1:length(codemetafields)
    emptymetastruct.(codemetafields{fidx}) = nan;
  end
end

timestart = nan;
timestop = nan;
timealign = nan;
thismetastruct = emptymetastruct;

for eidx = 1:length(evlabels)

  thislabel = evlabels(eidx);
  thistime = evtimes(eidx);

  if helper_labelMatch(thislabel, startlabel)

    if intrial
      disp(sprintf( '###  Trial start inside trial at row %d.', eidx ));
    end

    % Initialize this trial.
    intrial = true;
    timestart = thistime;
    timestop = nan;
    timealign = nan;
    thismetastruct = emptymetastruct;

  elseif helper_labelMatch(thislabel, stoplabel)

    if ~intrial
      disp(sprintf( '###  Trial end without trial start at row %d.', eidx ));
    else

      % End this trial.
      intrial = false;
      timestop = thistime;

      if isnan(timestart)
        disp(sprintf( ...
          '### Missing trial start time for trial ending at row %d.', eidx ));
      elseif isnan(timestop)
        disp(sprintf( ...
          '### Missing trial stop time at row %d (how?).', eidx ));
      elseif isnan(timealign)
        % FIXME - Suppress this warning.
        % We'll quite often be looking for events that don't happen in every
        % trial.
%        disp(sprintf( ...
%          '### No trigger found in trial ending at row %d. Skipping.', ...
%           eidx ));
      else
        % Everything looks okay; record this trial.

        trialcount = trialcount + 1;

        timestart = timestart - padbefore;
        timestop = timestop + padafter;

        % Build the new table row in a scratch variable, to avoid warnings
        % about updating one cell at a time in the existing table.

        scratchtab = table();

        % Remember that global sample indices start at 1, not 0.
        scratchtab.sampstart = round(timestart * samprate) + 1;
        scratchtab.sampend = round(timestop * samprate) + 1;
        % This is a relative sample offset, so it's 0-based.
        scratchtab.sampoffset = ...
          round((timestart - timealign) * samprate);

        scratchtab.timestart = timestart;
        scratchtab.timeend = timestop;
        scratchtab.timetrigger = timealign;

        for fidx = 1:length(codemetafields)
          metalabel = codemetafields{fidx};
          % Metadata values might be NaN if we didn't see appropriate codes.
          scratchtab.(metalabel) = thismetastruct.(metalabel);
        end

        % Append the new row to the trial table.
        trltab(trialcount,:) = scratchtab(1,:);
      end
    end

  elseif helper_labelMatch(thislabel, alignlabel)

    if ~intrial
      disp(sprintf( '###  Trial trigger outside trial at row %d.', eidx ));
    else
      timealign = thistime;
    end

  else
    for fidx = 1:length(codemetafields)
      metalabel = codemetafields{fidx};
      thismetacode = codemetatosave.(metalabel);
      if helper_labelMatch(thislabel, thismetacode)

        if ~intrial
          texttmeta = helper_makeString(thislabel);
          disp(sprintf( '###  Metadata "%s" outside trial at row %d.', ...
            textmeta, eidx ));
        else
          thismetastruct.(metalabel) = evvalues(eidx);
        end

      end
    end
  end

end


%
% Rebuild "trl" with the same column ordering as "trltab".

trl = table2array(trltab);


% Done.

end



%
% Helper Functions


function ismatch = helper_labelMatch(firstval, secondval)
  % Promote to string and do a lexical comparison.
  ismatch = ...
    strcmp( helper_makeString(firstval), helper_makeString(secondval) );
end


function textval = helper_makeString(unknownval)

  % This is either a number, a cell containing a number or character array,
  % or a character array.

  textval = unknownval;

  if iscell(textval)
    textval = textval{1};
  end

  % It's now either a number or a character array.

  if isnumeric(textval)
    textval = num2str(textval);
  end

  % It's now definitely a character array.
end


%
% This is the end of the file.
