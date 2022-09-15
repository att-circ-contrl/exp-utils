function newnames = euPlot_helperMakeTrialNames(oldnames, trialcount)

% function newnames = euPlot_helperMakeTrialNames(oldnames, trialcount)
%
% This function converts its argument to a cell array with per-trial
% character array labels. Input can be a cell array of character labels,
% a vector of numbers, or an empty cell array or empty vector.
%
% "oldnames" is the list to convert.
% "trialcount" is the number of trials to generate labels for if passed an
%   empty list. This is ignored if passed a non-empty list (no checking).
%
% "newnames" is an Nx1 cell array with per-trial character array labels.


newnames = {};

if isempty(oldnames)
  oldnames = 1:trialcount;
end

if iscell(oldnames)
  newnames = oldnames;
else
  % There's probably a one-line way to do this, but do it explicitly.
  for cidx = 1:length(oldnames)
    newnames{cidx} = sprintf( 'Tr %04d', oldnames(cidx) );
  end
end

if ~iscolumn(newnames)
  newnames = newnames';
end


% Done.

end


%
% This is the end of the file.
