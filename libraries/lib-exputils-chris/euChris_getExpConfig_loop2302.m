function [ config summary details diagmsgs errmsgs ] = ...
  euChris_getExpConfig_loop2302( rawmeta, cookedmeta, hintdata )

% function [ config summary details diagmsgs errmsgs ] = ...
%   euChris_getExpConfig_loop2302( rawmeta, cookedmeta, hintdata )
%
% This examines an experiment session's metadata and builds an experiment
% configuration structure describing the experiment.
%
% This function works with 'loop2302' type metadata.
%
% "rawmeta" is the raw metadata structure for this experiment folder, per
%   RAWFOLDERMETA.txt.
% "cookedmeta" is the cooked (derived) metadata for this experiment, per
%   CHRISEXPMETA.txt.
% "hintdata" is a structure containing hints for processing metadata. If
%   there are no hints, this will be a structure with no fields.
%
% "config" is a structure describing the experiment configuration, per
%   CHRISEXPCONFIGS.txt. It will be empty if parsing failed.
% "summary" is a cell array of character vectors containing a short
%   human-readable summary of the configuration.
% "details" is a cell array of character vectors containing a
%   human-readable detailed description of the configuration.
% "diagmsgs" is a cell array containing diagnostic messages _and_ error
%   and warning messages generated during processing.
% "errmsg" is a cell array containing _only_ error and warning messages
%   generated during processing.


config = struct();

summary = {};
details = {};

diagmsgs = {};
errmsgs = {};


%
% Check that we _have_ everything.

have_torte = (~isempty(cookedmeta.torteband)) ...
  && (~isempty(cookedmeta.torteinchans));
have_magdetect = ~isnan(cookedmeta.crossmagchan);
have_phasedetect = ~isnan(cookedmeta.crossphasechan);
have_randdetect = ~isnan(cookedmeta.crossrandchan);
have_fakerand = cookedmeta.randwasjitter;
have_arduino = ~isnan(cookedmeta.ardinbit);
have_firstfile = length(cookedmeta.filewritenodes) > 0;
have_secondfile = length(cookedmeta.filewritenodes) > 1;

thismsg = '   Found torte: ';
thismsg = helper_addYN(thismsg, have_torte);
thismsg = [ thismsg '  mag: ' ];
thismsg = helper_addYN(thismsg, have_magdetect);
thismsg = [ thismsg '  phase: ' ];
thismsg = helper_addYN(thismsg, have_phasedetect);
thismsg = [ thismsg '  rand: ' ];
thismsg = helper_addYN(thismsg, have_randdetect);
thismsg = [ thismsg '  fakerand: ' ];
thismsg = helper_addYN(thismsg, have_fakerand);
thismsg = [ thismsg '  ard: ' ];
thismsg = helper_addYN(thismsg, have_arduino);
thismsg = [ thismsg '  files: ' num2str(length(cookedmeta.filewritenodes)) ];

diagmsgs = [ diagmsgs { thismsg } ];
details = [ details { thismsg } ];


% See if we have enough information to proceed.

if have_torte && have_magdetect && have_phasedetect ...
  && (have_randdetect || have_fakerand) && have_firstfile


  %
  % Check to see if wiring is consistent, and identify channel names.
  % NOTE - These are not the same names Field Trip uses!

  % These are 1-based.
  chan_wb_num = cookedmeta.torteinchans(1);
  chan_mag_num = cookedmeta.torteextrachan;
  chan_phase_num = chan_wb_num;

  % If we had an Intan recorder, we got channel labels from it.
  % Otherwise we're using FT labels.
  % If we had an internal channel map, we applied it.
  % Otherwise, we're using an external channel map or no channel map.
  chan_wb_label = cookedmeta.cookedchans{chan_wb_num};

  thismsg = [ '   WB channel is ' num2str(chan_wb_num) ' ("' ...
    chan_wb_label '");  magnitude is channel ' num2str(chan_mag_num) '.' ];

  diagmsgs = [ diagmsgs { thismsg } ];
  summary = [ summary { thismsg } ];
  details = [ details { thismsg } ];

  % We may or may not have a random crossing detector. We do have the others.
  if chan_mag_num ~= cookedmeta.crossmagchan
    thismsg = [ '###  Magnitude detector is reading from channel ' ...
      num2str(cookedmeta.crossmagchan) ' instead of ' ...
      num2str(chan_mag_num) '.' ];
    diagmsgs = [ diagmsgs { thismsg } ];
    errmsgs = [ errmsgs { thismsg } ];
    summary = [ summary { thismsg } ];
    details = [ details { thismsg } ];
  end
  if chan_phase_num ~= cookedmeta.crossphasechan
    thismsg = [ '###  Phase detector is reading from channel ' ...
      num2str(cookedmeta.crossphasechan) ' instead of ' ...
      num2str(chan_phase_num) '.' ];
    diagmsgs = [ diagmsgs { thismsg } ];
    errmsgs = [ errmsgs { thismsg } ];
    summary = [ summary { thismsg } ];
    details = [ details { thismsg } ];
  end
  if have_randdetect && (chan_phase_num ~= cookedmeta.crossrandchan)
    thismsg = [ '###  Random detector is reading from channel ' ...
      num2str(cookedmeta.crossrandchan) ' instead of ' ...
      num2str(chan_phase_num) '.' ];
    diagmsgs = [ diagmsgs { thismsg } ];
    errmsgs = [ errmsgs { thismsg } ];
    summary = [ summary { thismsg } ];
    details = [ details { thismsg } ];
  end



% FIXME - NYI. Stopped here.
end



% Done.
end



%
% Helper Functions


function newmsg = helper_addYN(oldmsg, flagval)
  if flagval
    newmsg = [ oldmsg 'Y' ];
  else
    newmsg = [ oldmsg 'N' ];
  end
end



%
% This is the end of the file.
