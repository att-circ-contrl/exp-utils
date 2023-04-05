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
have_condtrig = ~isnan(cookedmeta.trigbank);
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
thismsg = [ thismsg '  condtrig: ' ];
thismsg = helper_addYN(thismsg, have_condtrig);
thismsg = [ thismsg '  ard: ' ];
thismsg = helper_addYN(thismsg, have_arduino);
thismsg = [ thismsg '  files: ' num2str(length(cookedmeta.filewritenodes)) ];

diagmsgs = [ diagmsgs { thismsg } ];
details = [ details { thismsg } ];


% See if we have enough information to proceed.

if have_torte && have_magdetect && have_phasedetect ...
  && (have_randdetect || have_fakerand) && have_condtrig && have_firstfile


  %
  % Check to see if wiring is consistent, and identify channel names.
  % NOTE - These are not the same names Field Trip uses!

  % These are 1-based.
  chan_wb_num = cookedmeta.torteinchans(1);
  chan_mag_num = cookedmeta.torteextrachan;
  chan_phase_num = chan_wb_num;

  % If we had an Intan recorder, we got channel labels from it.
  % Otherwise we're using fake labels that _look_ like Intan/OpenE labels.
  % If we had an internal channel map, we applied it.
  % Otherwise, we're using an external channel map or no channel map.
  chan_wb_oelabel = cookedmeta.cookedchans{chan_wb_num};

  thismsg = [ '   WB channel is ' num2str(chan_wb_num) ' ("' ...
    chan_wb_oelabel '"); magnitude is channel ' num2str(chan_mag_num) '.' ];

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

  % See what type of output we're generating.
  trigtype = 'none';
  trigselectedbit = cookedmeta.ardinbit;
  if have_arduino
    if cookedmeta.ardinbit == cookedmeta.trigphasebit
      trigtype = 'phase';
    elseif cookedmeta.ardinbit == cookedmeta.trigrandbit
      trigtype = 'random';
    elseif cookedmeta.ardinbit == cookedmeta.trigmagbit
      trigtype = 'power';
    elseif cookedmeta.ardinbit == cookedmeta.trignowbit
      trigtype = 'immediate';
    else
      thismsg == [ '###  Arduino is reading from unused TTL bit ' ...
        num2str(cookedmeta.ardinbit) '.' ];
      diagmsgs = [ diagmsgs { thismsg } ];
      errmsgs = [ errmsgs { thismsg } ];
      summary = [ summary { thismsg } ];
      details = [ details { thismsg } ];
      trigselectedbit = NaN;
    end

    thismsg = [ '   Selected trigger type "' trigtype '".' ];
    diagmsgs = [ diagmsgs { thismsg } ];
    summary = [ summary { thismsg } ];
    details = [ details { thismsg } ];
  else
    thismsg = '   No trigger output.';
    diagmsgs = [ diagmsgs { thismsg } ];
    summary = [ summary { thismsg } ];
    details = [ details { thismsg } ];
  end


  % Record all of this in the configuration structure.

  config.chan_wb_num = chan_wb_num;
  config.chan_mag_num = chan_mag_num;
  config.chan_phase_num = chan_phase_num;

  config.chan_wb_oelabel = chan_wb_oelabel;

  config.trigtype = trigtype;



  %
  % Figure out what we're saving.


  chan_wb_ftlabel = '';
  chan_mag_ftlabel = '';
  chan_phase_ftlabel = '';

  chan_ttl_loopback_trig_ftlabel = '';

  chan_ttl_detect_mag_ftlabel = '';
  chan_ttl_detect_phase_ftlabel = '';
  chan_ttl_detect_rand_ftlabel = '';

  chan_ttl_trig_phase_ftlabel = '';
  chan_ttl_trig_rand_ftlabel = '';
  chan_ttl_trig_power_ftlabel = '';
  chan_ttl_trig_immed_ftlabel = '';

  chan_ttl_trig_selected_ftlabel = '';


  % FIXME - Rely on the file recorder nodes being saved in signal chain order.
  % We always have at least one recording node.
  % Assume that this is saving raw input, and the next is saving derived
  % signals.

  firstidx = 1;
  secondidx = NaN;

  if have_secondfile
    secondidx = 2;
  end


  % Get analog channel information.

  [ chan_wb_ftlabel chan_mag_ftlabel chan_phase_ftlabel ] = ...
    helper_getFTLabels(chan_wb_oelabel);

  firstchanmask = cookedmeta.filewritechanmasks{firstidx};
  firstsavedcount = sum(firstchanmask);

  if ~firstchanmask(chan_wb_num)
    chan_wb_ftlabel = '';
  end

  secondsavedcount = 0;
  if have_secondfile
    secondchanmask = cookedmeta.filewritechanmasks{secondidx};
    secondsavedcount = sum(secondchanmask);

    if ~secondchanmask(chan_mag_num)
      chan_mag_ftlabel = '';
    end
    if ~secondchanmask(chan_phase_num)
      chan_phase_ftlabel = '';
    end
  else
    chan_mag_ftlabel = '';
    chan_phase_ftlabel = '';
  end


  % Record analog channels and file node information.

  config.file_node_first = cookedmeta.filewritenodes(firstidx);
  config.file_node_second = NaN;
  if have_secondfile
    config.file_node_second = cookedmeta.filewritenodes(secondidx);
  end

  config.chan_wb_ftlabel = chan_wb_ftlabel;
  config.chan_mag_ftlabel = chan_mag_ftlabel;
  config.chan_phase_ftlabel = chan_phase_ftlabel;

  % Report this information.

  thismsg = [ '   Wideband saved as "' chan_wb_ftlabel '" by record node ' ...
    num2str(config.file_node_first) '.' ];
  diagmsgs = [ diagmsgs { thismsg } ];
  summary = [ summary { thismsg } ];
  details = [ details { thismsg } ];

  if have_secondfile
    thismsg = [ '   Mag saved as "' chan_mag_ftlabel '" and phase as "' ...
      chan_phase_ftlabel '" by record node ' ...
      num2str(config.file_node_second) '.' ];
    diagmsgs = [ diagmsgs { thismsg } ];
    summary = [ summary { thismsg } ];
    details = [ details { thismsg } ];
  end


  % Get TTL channel information.

  if have_arduino && cookedmeta.filewritehasevents(firstidx)
    % FIXME - Hard-coded as Intan recorder TTL bit 8.
    chan_ttl_loopback_trig_ftlabel = 'DigBitsA_008';
  end

  if have_secondfile
    if cookedmeta.filewritehasevents(secondidx)

      % Bank and bit are NaN for signals that weren't generated.
      % The helper function gives '' as output in that situation.

      chan_ttl_detect_mag_ftlabel = helper_makeTTLName( ...
        cookedmeta.crossmagbank, cookedmeta.crossmagbit );
      chan_ttl_detect_phase_ftlabel = helper_makeTTLName( ...
        cookedmeta.crossphasebank, cookedmeta.crossphasebit );
      chan_ttl_detect_rand_ftlabel = helper_makeTTLName( ...
        cookedmeta.crossrandbank, cookedmeta.crossrandbit );

      chan_ttl_trig_phase_ftlabel = helper_makeTTLName( ...
        cookedmeta.trigbank, cookedmeta.trigphasebit );
      chan_ttl_trig_rand_ftlabel = helper_makeTTLName( ...
        cookedmeta.trigbank, cookedmeta.trigrandbit );
      chan_ttl_trig_power_ftlabel = helper_makeTTLName( ...
        cookedmeta.trigbank, cookedmeta.trigmagbit );
      chan_ttl_trig_immed_ftlabel = helper_makeTTLName( ...
        cookedmeta.trigbank, cookedmeta.trignowbit );

      if strcmp(trigtype, 'phase')
        chan_ttl_trig_selected_ftlabel = chan_ttl_trig_phase_ftlabel;
      elseif strcmp(trigtype, 'random')
        chan_ttl_trig_selected_ftlabel = chan_ttl_trig_rand_ftlabel;
      elseif strcmp(trigtype, 'power')
        chan_ttl_trig_selected_ftlabel = chan_ttl_trig_power_ftlabel;
      elseif strcmp(trigtype, 'immediate')
        chan_ttl_trig_selected_ftlabel = chan_ttl_trig_immed_ftlabel;
      end

    end
  end


  % Record TTL channel labels.

  config.chan_ttl_loopback_trig_ftlabel = chan_ttl_loopback_trig_ftlabel;

  config.chan_ttl_detect_mag_ftlabel = chan_ttl_detect_mag_ftlabel;
  config.chan_ttl_detect_phase_ftlabel = chan_ttl_detect_phase_ftlabel;
  config.chan_ttl_detect_rand_ftlabel = chan_ttl_detect_rand_ftlabel;

  config.chan_ttl_trig_phase_ftlabel = chan_ttl_trig_phase_ftlabel;
  config.chan_ttl_trig_rand_ftlabel = chan_ttl_trig_rand_ftlabel;
  config.chan_ttl_trig_power_ftlabel = chan_ttl_trig_power_ftlabel;
  config.chan_ttl_trig_immed_ftlabel = chan_ttl_trig_immed_ftlabel;

  config.chan_ttl_trig_selected_ftlabel = chan_ttl_trig_selected_ftlabel;

  % Report this information.

  thismsg = ...
    [ '   Loopback trigger saved as "' chan_ttl_loopback_trig_ftlabel ...
      '" by record node ' num2str(config.file_node_first) '.' ];
  diagmsgs = [ diagmsgs { thismsg } ];
  summary = [ summary { thismsg } ];
  details = [ details { thismsg } ];

  if have_secondfile
    thismsg = [ '   Detect flags saved as "' chan_ttl_detect_mag_ftlabel ...
      ' (mag), "' chan_ttl_detect_phase_ftlabel '" (phase),"' ];
    diagmsgs = [ diagmsgs { thismsg } ];
    summary = [ summary { thismsg } ];
    details = [ details { thismsg } ];
    thismsg = [ '   and "' chan_ttl_detect_rand_ftlabel ...
      '" (rand) by record node ' num2str(config.file_node_second) '.' ];
    diagmsgs = [ diagmsgs { thismsg } ];
    summary = [ summary { thismsg } ];
    details = [ details { thismsg } ];

    thismsg = [ '   Triggers saved as "' chan_ttl_trig_phase_ftlabel ...
      ' (phase), "' chan_ttl_trig_rand_ftlabel '" (rand),' ];
    diagmsgs = [ diagmsgs { thismsg } ];
    summary = [ summary { thismsg } ];
    details = [ details { thismsg } ];
    thismsg = [ '   "' chan_ttl_trig_power_ftlabel '" (power), and "' ...
      chan_ttl_trig_immed_ftlabel '" (immed) by record node ' ...
      num2str(config.file_node_second) '.' ];
    diagmsgs = [ diagmsgs { thismsg } ];
    summary = [ summary { thismsg } ];
    details = [ details { thismsg } ];
  end


  %
  % Finished aggregating and reporting experiment configuration.

% FIXME - Stick on the FT digital channel list.
% We also have chans_an and header_ft.label available.
thislist = rawmeta.chans_dig;
if ~isrow(thislist) ; thislist = transpose(thislist) ; end
diagmsgs = [ diagmsgs thislist ];

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


function [ wb_ftlabel mag_ftlabel phase_ftlabel ] = ...
  helper_getFTLabels( wb_oelabel )

  wb_ftlabel = '';
  mag_ftlabel = '';
  phase_ftlabel = '';

  tokenlist = regexp(wb_oelabel, 'CH(\d+)', 'tokens');
  if length(tokenlist) > 0
    thisnumstr = tokenlist{1}{1};
    thisnum = str2num(thisnumstr);

    wb_ftlabel = sprintf('CH_%03d', thisnum);
    mag_ftlabel = sprintf('CHMAG_%03d', thisnum);
    phase_ftlabel = wb_ftlabel;
  end

end


function ftlabel = helper_makeTTLName( bankidx, bitidx )

  % Supplied bank and bit are 0-based, and are NaN for invalid signals.
  % FT labels start at "A" and "001" (1-based).

  ftlabel = '';

  if (~isnan(bankidx)) && (~isnan(bitidx))
    bitidx = bitidx + 1;
    ftlabel = [ 'DigBits' char('A' + bankidx) '_' sprintf('%03d', bitidx) ];
  end

end



%
% This is the end of the file.
