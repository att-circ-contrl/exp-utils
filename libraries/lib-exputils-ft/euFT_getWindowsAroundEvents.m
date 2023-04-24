function trialmasks = nlFT_getWindowsAroundEvents(ftdataset, window_ms)

% function trialmasks = nlFT_getWindowsAroundEvents(ftdataset, window_ms)
%
% This function gets boolean masks that are set "true" around trigger
% events within trials.
%
% This handles the "overlapping trials" case correctly.
%
% "ftdataset" is a Field Trip ft_datatype_raw dataset.
% "window_ms" [ start stop ] is the time range around each trigger event to
%   set to true in the mask, in milliseconds. E.g. [ -1 5 ].
%
% "trialmasks" is a 1xNtrials cell array. Each cell is a 1xNtime logical
%   vector which is true near events and false everywhere else.


trialmasks = {};

timelist = ftdataset.time;
samprate = ftdataset.hdr.Fs;
trialdefs = ftdataset.cfg.trl;


for tidx = 1:length(timelist)
  thistime = timelist{tidx};
  thismask = false(thistime);

% FIXME - NYI.

  trialmasks{tidx} = thismask;
end


% Done.
end


%
% This is the end of the file.
