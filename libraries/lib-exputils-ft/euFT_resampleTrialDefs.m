function newtrialdefs = ...
  euFT_resampleTrialDefs( oldtrialdefs, oldrate, newrate );

% function newtrialdefs = ...
%   euFT_resampleTrialDefs( oldtrialdefs, oldrate, newrate );
%
% This function alters a trial definition table to account for a changed
% sampling rate. Time zero is expected to be consistent between the
% two representations (i.e. just a scaling, without shifting).
%
% "oldtrialdefs" is a matrix or table containing trial definitions, per
%   ft_definetrial().
% "oldrate" is the sampling rate used with "oldtrialdefs".
% "newrate" is the desired new sampling rate.
%
% "newtrialdefs" is a copy of "oldtrialdefs" with the start, end, and
%   offset columns modified to reflect the new sampling rate.


% Copy the table or matrix.

newtrialdefs = oldtrialdefs;


% Extract the start, end, and offset series.

thisstart = newtrialdefs(:,1);
thisend = newtrialdefs(:,2);
thisoffset = newtrialdefs(:,3);


% Convert to the new sampling rate. Remember that sample 1, not sample 0,
% is time zero, for start and end (but not offset).

% Convert from samples to seconds.
thisstart = (thisstart - 1) / oldrate;
thisend = (thisend - 1) / oldrate;
thisoffset = thisoffset / oldrate;

% Convert from seconds back to samples.
thisstart = round(thisstart * newrate) + 1;
thisend = round(thisend * newrate) + 1;
thisoffset = round(thisoffset * newrate);


% Store the modified series.

newtrialdefs(:,1) = thisstart;
newtrialdefs(:,2) = thisend;
newtrialdefs(:,3) = thisoffset;


% Done.

end


%
% This is the end of the file.
