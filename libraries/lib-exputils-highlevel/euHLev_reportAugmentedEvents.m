function reportmsg = euHLev_reportAugmentedEvents( olddevlist, newdevlist )

% function reportmsg = euHLev_reportAugmentedEvents( olddevlist, newdevlist )
%
% This reports changes to a set of per-device event table collections.
% This is intended to compare the before-and-after effects of
% euHLev_augmentEphysEvents().
%
% "olddevlist" is a structure containing each device's cooked event tables,
%   per euUSE_readAllEphysEvents(), before the putative changes.
% "newdevlist" is a structure containing each device's cooked event tables
%   after the putative changes.
%
% "reportmsg" is a character vector containing a human-readable summary of
%   the differences between the two structures. This contains newlines.


% Initialize.
reportmsg = '';
newline = sprintf('\n');


% FIXME - Magic values (metadata).

devnamelut = struct( 'openephys', 'Open Ephys', ...
  'intanrec', 'Intan Recorder', 'intanstim', 'Intan Stimulator' );


% Iterate devices.

devlist = fieldnames(olddevlist);

for devidx = 1:length(devlist)

  devlabel = devlist{devidx};

  devname = [ 'Unknown (' devlabel ')' ];
  if isfield( devnamelut, devlabel )
    devname = devnamelut.(devlabel);
  end


  % Sanity - Make sure the device exists in both lists.
  if ~isfield(newdevlist, devlabel)
    reportmsg = [ reportmsg '###  Device "' devlabel ...
      '" from old list isn''t in new list!' newline ];

    % Skip further processing for this device.
    continue;
  end


  oldtables = olddevlist.(devlabel);
  newtables = newdevlist.(devlabel);


  % Report tables added or extended.

  tablist = fieldnames(newtables);

  for tabidx = 1:length(tablist)
    tablabel = tablist{tabidx};
    desttab = newtables.(tablabel);

    if ~isempty(desttab)
      if ~isfield(oldtables, tablabel)
        reportmsg = [ reportmsg ...
          '.. Added event list "' tablabel '" to ' devname '.' newline ];
      else
        sourcetab = oldtables.(tablabel);
        if isempty(sourcetab)
          reportmsg = [ reportmsg ...
            '.. Added event list "' tablabel '" to ' devname '.' newline ];
        elseif height(sourcetab) ~= height(desttab)
          % NOTE - This should catch added faux event codes from TTL events.
          reportmsg = [ reportmsg ...
            sprintf( '.. Added %d entries to event list "%s" in %s.\n', ...
              height(desttab) - height(sourcetab), tablabel, devname ) ];
        end
      end
    end
  end


  % We've already reported that "cookedcodes" has been extended.
  % Give a description of new labels that were added.

  if (~isfield(oldtables, 'cookedcodes')) ...
    || (~isfield(newtables, 'cookedcodes'))
    reportmsg = [ reportmsg ...
      '###  Can''t find "cookedcodes" for device "' devlabel '"!' newline ];
  else
    oldcodetab = oldtables.cookedcodes;
    newcodetab = newtables.cookedcodes;

    if (~ismember( 'codeLabel', oldcodetab.Properties.VariableNames )) ...
      || (~ismember( 'codeLabel', newcodetab.Properties.VariableNames ))
      reportmsg = [ reportmsg '###  Can''t find "codeLabels"' ...
        ' in "cookedcodes" for device "' devlabel '"!' newline ];
    else
      oldcodelist = oldcodetab.codeLabel;
      newcodelist = newcodetab.codeLabel;
      newcodes = unique(newcodelist);

      % For each code label, tell the user if its count increased.

      need_cooked_banner = true;

      for cidx = 1:length(newcodes)
        thiscode = newcodes{cidx};
        oldcount = sum(strcmp( thiscode, oldcodelist ));
        newcount = sum(strcmp( thiscode, newcodelist ));

        if oldcount ~= newcount
          if need_cooked_banner
            reportmsg = [ reportmsg ...
              '.. New entries in "cookedcodes" for ' devname ':' newline ];
            need_cooked_banner = false;
          end

          reportmsg = [ reportmsg sprintf( '  %s - Added %d counts.\n', ...
            thiscode, newcount - oldcount ) ];
        end
      end
    end
  end

end


% Done.
end


%
% This is the end of the file.
