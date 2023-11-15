function [ plotdata sessionlabels caselabels probelabels timelabels ...
  sessiontitles casetitles probetitles timetitles timevaluesms ] = ...
  euChris_stimFeaturesToRawPlotData_loop2302( statdata )

% function [ plotdata sessionlabels caselabels probelabels timelabels ...
%   sessiontitles casetitles probetitles timetitles timevaluesms ] = ...
%   euChris_stimFeaturesToRawPlotData_loop2302( statdata )
%
% This augments a cell array "stimulation response features" records (per
% CHRISSTIMFEATURES.txt) with the metadata needed to be a valid raw plot
% data cell array (per PLOTDATARAW.txt).
%
% NOTE - This assumes "loop2302" naming conventions for sessions/cases/probes.
%
% "statdata" is a cell array containing stimulation response feature data
%   structures, per CHRISSTIMFEATURES. This must include the optional
%   "sessionlabel", "caselabel", "probelabel", and "chanlabels" fields.
%
% "plotdata" is a copy of "statdata" with records augmented with the
%   metadata fields described in PLOTDATARAW.
%
% "sessionlabels" is a cell array containing all unique "sessionlabel"
%   values.
% "caselabels" is a cell array containing all unique "caselabel" values.
% "probelabels" is a cell array containing all unique "probelabel" values.
% "timelabels" is a cell array containing all unique "timelabel" values from
%   the augmented records.
%
% "sessiontitles" is a cell array containing human-readable session names
%   corresponding to "sessionlabels".
% "casetitles" is a cell array containing human-readable case names
%   corresponding to "caselabels".
% "probetitles" is a cell array containg human-readable probe names
%   corresponding to "probelabels".
% "timetitles" is a cell array containing human-readable times corresponding
%   to "timelabels".
%
% "timevaluesms" is a vector containing time bin values in milliseconds
%   corresponding to "timelabels".


plotdata = statdata;

sessionlabels = {};
caselabels = {};
probelabels = {};
timelabels = {};

sessiontitles = {};
casetitles = {};
probetitles = {};
timetitles = {};


if ~isempty(statdata)

  % Time window labels and titles.
  % FIXME - Assume consistent window times across all records.
  % FIXME - Blithely assuming no collisions in the labels after rounding.

  timevaluesms = statdata{1}.winafter * 1000;

  timetitles = nlUtil_sprintfCellArray( '%d ms', round(timevaluesms) );

  % NOTE - Time "after" can be negative; handle that.
  timelabels = nlUtil_sprintfCellArray( 'p%04dms', round(timevaluesms) );
  scratch = nlUtil_sprintfCellArray( 'n%04dms', round(timevaluesms) );
  masknegative = (timevaluesms < 0);
  timelabels(masknegative) = scratch(masknegative);


  % Labels for sessions, probes, and cases.
  % FIXME - We know a priori that the raw labels are filename- and plot-safe,
  % for loop2302 conventions.

  sessionlabels = nlUtil_getCellOfStructField( statdata, 'sessionlabel', '' );
  sessionlabels = sessionlabels( ~strcmp(sessionlabels, '') );
  sessionlabels = unique(sessionlabels);

  probelabels = nlUtil_getCellOfStructField( statdata, 'probelabel', '' );
  probelabels = probelabels( ~strcmp(probelabels, '') );
  probelabels = unique(probelabels);

  caselabels = nlUtil_getCellOfStructField( statdata, 'caselabel', '' );
  caselabels = caselabels( ~strcmp(caselabels, '') );
  caselabels = unique(caselabels);


  % Pretty titles for sessions, probes, and cases.

  sessiontitles = euChris_makePrettySessionTitles_loop2302( sessionlabels );
  probetitles = probelabels;
  casetitles = euChris_makePrettyCaseTitles_loop2302( caselabels );


  % Walk through the records, adding metadata.

  for didx = 1:length(plotdata)
    thissession = plotdata{didx}.sessionlabel;
    thisprobe = plotdata{didx}.probelabel;
    thiscase = plotdata{didx}.caselabel;

    % FIXME - Blithely assume a valid label is present for all records.
    sidx = min(find(strcmp(thissession, sessionlabels)));
    pidx = min(find(strcmp(thisprobe, probelabels)));
    cidx = min(find(strcmp(thiscase, caselabels)));

    plotdata{didx}.sessiontitle = sessiontitles{sidx};
    plotdata{didx}.probetitle = probetitles{pidx};
    plotdata{didx}.casetitle = casetitles{cidx};

    plotdata{didx}.timelabels = timelabels;
    plotdata{didx}.timetitles = timetitles;
    plotdata{didx}.timevaluesms = timevaluesms;
  end

end


% Done.
end


%
% This is the end of the file.
