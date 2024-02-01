function metadata = euMeta_getDesiredSessions_guessLouie( sessionlist )

% function metadata = euMeta_getDesiredSessions_guessLouie( sessionlist )
%
% This takes a session list provided by euMeta_getLouieFoldersAndLogs() and
% builds a desired session metadata list based on its contents.
%
% Mostly this generates faux probe banks.
%
% This is intended to only be used as a short-term testing kludge!
% Make a proper getDesiredSessions function for each experiment instead, if
% at all possible.
%
% FIXME - This isn't reliable! It depends on parsing Louie's written notes,
% which vary in format.
%
% FIXME - We don't have enough information to get tungsten bank labels.
%
% "sessionlist" is a struct array containing session folder metadata, per
%   SESSIONMETA.txt, produced by euMeta_getLouieFoldersAndLogs().
%
% "metadata" is a struct array per DESIREDSESSIONS.txt.


metadata = struct([]);

for sidx = 1:length(sessionlist)
  thissession = sessionlist(sidx);

  if isfield(thissession, 'logdata')
    thislog = thissession.logdata;

    if isfield(thislog, 'dataset')

      dataset = thislog.dataset;
      newmeta = struct('dataset', dataset);


      % Guess at monkey identity.

      newmeta.monkey = 'unknown';

      if contains(dataset, 'Fr')
        newmeta.monkey = 'Frey';
      elseif contains(dataset, 'Ig')
        newmeta.monkey = 'Igor';
      elseif contains(dataset, 'Wo')
        newmeta.monkey = 'Wotan';
      elseif contains(dataset, 'Re')
        newmeta.monkey = 'Reider';
      end


      % Guess at probes.

      probedefs = struct([]);

      probetext = {};
      probeareas = {};

      if isfield(thislog, 'CHANNELS_neuro')
        % Tungsten or hybrid tungsten/silicon.
        probetext = thislog.('CHANNELS_neuro');
        probeareas = thislog.('CHANNELS_area');
      elseif isfield(thislog, 'PROBE_neuro')
        % Usually but not always silicon.
        probetext = thislog.('PROBE_neuro');
        probeareas = thislog.('PROBE_area');
      end

      if length(probetext) == length(probeareas)
        % We might have zero entries, but that's okay.
        areasseen = {};
        for pidx = 1:length(probetext)

          % Text is signal names for tungsten, or sometimes 'tungsten',
          % or a serial number for silicon, or 'DBC probe NN-NN'.

          % For tungsten on Intan, the "inNNx" and "elecNN" numbers from my
          % EIB conventions can only be translated if we know what port the
          % EIB was on. So we have no idea what bank to use.

          % We have no idea what bank probes with serial numbers are on.
          % We might reverse-engineer it from good/bad channels, but no.

          thistext = probetext{pidx};
          thisarea = probeareas{pidx};
          [ thisarea scratch ] = euUtil_makeSafeString( thisarea );


          % Louie's DBC probe convention.

          tokenlist = regexp( thistext, 'probe\s+(\d+)\D+(\d+)', 'tokens' );
          if length(tokenlist) > 0
            firstchan = str2num(tokenlist{1}{1});
            lastchan = str2num(tokenlist{1}{2});

            areasseen = [ areasseen { thisarea } ];
            areanum = sum(strcmp( areasseen, thisarea ));
            areanum = num2str(areanum);

            thisprobedef = struct();

            thisprobedef.label = [ 'pr' thisarea areanum ];
            thisprobedef.title = [ 'Probe ' thisarea ' ' areanum ];
            thisprobedef.channums = firstchan:lastchan;
            thisprobedef.chanlabels = ...
              nlFT_makeLabelsFromNumbers( 'CH', thisprobedef.channums );

            probedefs = [ probedefs thisprobedef ];
          end

        end
      end

      if ~isempty(probedefs)
        newmeta.probedefs = probedefs;
        metadata = [ metadata newmeta ];
      end

    end
  end
end


% Done.
end


%
% This is the end of the file.
