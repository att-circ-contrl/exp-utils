function newconfig = euAlign_getDefaultAlignConfig( oldconfig )

% function newconfig = euAlign_getDefaultAlignConfig( oldconfig )
%
% This function fills in missing time alignment parameters with reasonable
% default values.
%
% These configuration parameters are intended to be used with
% "euAlign_alignTables()".
%
% "oldconfig" is a structure with zero or more of the following fields:
%   "coarsewindows" is a vector with coarse alignment window half-widths.
%   "medwindows" is a vector with medium alignment window half-widths.
%   "finewindow" is the window half-width for final non-uniform alignment.
%   "outliersigma" is the threshold for rejecting spurious matches.
%   "verbosity" is 'verbose', 'normal', or 'quiet'.
%
% "newconfig" is a copy of "oldconfig" with missing fields added.


newconfig = oldconfig;

if ~isfield(newconfig, 'coarsewindows')
  newconfig.coarsewindows = [ 100.0 ];
end

if ~isfield(newconfig, 'medwindows')
  newconfig.medwindows = [ 1.0 ];
end

if ~isfield(newconfig, 'finewindow')
  newconfig.finewindow = 0.1;
end

if ~isfield(newconfig, 'outliersigma')
  newconfig.outliersigma = 4.0;
end

if ~isfield(newconfig, 'verbosity')
  newconfig.verbosity = 'normal';
end


% Done.

end


%
% This is the end of the file.
