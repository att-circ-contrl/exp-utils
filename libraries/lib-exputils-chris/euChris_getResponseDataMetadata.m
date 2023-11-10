function datameta = euChris_getResponseDataMetadata( statdata, labelfields )

% function datameta = euChris_getResponseDataMetadata( statdata, labelfields )
%
% This extracts many pieces of metadata from a series of stimulation response
% feature statistics structures.
%
% NOTE - window times are expected to be consistent across all records!
% Window metadata content may be incorrect if this is not the case.
%
% NOTE - If requested label fields are absent, associated metadata fields
% will be absent or empty.
%
% "statdata" is a cell array containing stimulation response feature data
%   structures, per CHRISSTIMFEATURES.txt, typically also including
%   session/case/probe labels.
% "labelfields" is a cell array containing label field names to collect
%   metadata for. Typical names include 'sessionlabel', 'caselabel', and
%   'probelabel'.
%
% "datameta" is a structure with the following fields:
%
%   "winbefore" is a scalar containing the timestamp of the midpoint of the
%     before-stimulation time window.
%   "winafter" is a vector containing the timestamps of the midpoints of the
%     after-stimulation time windows.
%   "winbeforetext" is a character vector containing a plot-safe
%     human-readable version of the absolute value of the "winbefore" time.
%   "winbeforelabel" is a character vector containing a filename-safe
%     label derived from the absolute value of the "winbefore" time.
%   "winaftertext" is a cell array containing character vectors with
%     plot-safe human-readable versions of the "winafter" times.
%   "winafterlabels" is a cell array containing character vectors with
%     filename-safe labels derived from the "winafter" times.
%
%   "labelraw" is a structure with one field per entry in "labelfields",
%     holding cell arrays with lists of all raw label values encountered.
%   "labeltext" is a structure with one field per entry in "labelfields",
%     holding cell arrays containing plot-safe human-readable versions of
%     the raw labels.
%   "labelshort" is a structure with one field per entry in "labelfields",
%     holding cell arrays containing plot-safe versions of the raw labels.
%   "labelkey" is a structure with one field per entry in "labelfields",
%     holding cell arrays containing versions of the raw labels that are
%     safe to use as structure field names.


% Initialize to safe values.

winbefore = 0;
winafter = [];
winbeforetext = '0 ms';
winbeforelabel = 'pre000ms';
winaftertext = {};
winafterlabels = {};

labelraw = struct();
labeltext = struct();
labelshort = struct();
labelkey = struct();

for fidx = 1:length(labelfields)
  thisfield = labelfields{fidx};

  labelraw.(thisfield) = {};
  labeltext.(thisfield) = {};
  labelshort.(thisfield) = {};
  labelkey.(thisfield) = {};
end



% If we have data at all, copy the window times from the first entry.
% This is guaranteed to be present.

if ~isempty(statdata)
  thisdata = statdata{1};

  % Remember to take the absolute value for the "before" time.
  winbefore = thisdata.winbefore;
  winbeforetext = sprintf( '%d ms', round(abs(1000 * winbefore)) );
  winbeforelabel = sprintf( 'pre%03d', round(abs(1000 * winbefore)) );

  for widx = 1:length(thisdata.winafter)
    thistime = thisdata.winafter(widx);
    winafter(widx) = thistime;
    winaftertext{widx} = sprintf( '%d ms', round(1000 * thistime) );
    winafterlabels{widx} = sprintf( 'post%03d', round(1000 * thistime) );
  end
end


% Get raw label field information, if present.

for fidx = 1:length(labelfields)
  thisfield = labelfields{fidx};

  % We know that this is character data, not numeric/logical.
  thisraw = nlUtil_getCellOfStructField( statdata, thisfield, '' );

  % Discard default-valued ('') entries.
  thisraw = thisraw( ~strcmp(thisraw, '') );

  labelraw.(thisfield) = unique(thisraw);
end



% Build derived versions of the label fields, keeping the same order
% as the raw list.

for fidx = 1:length(labelfields)

  % Fetch the raw list.

  thisfield = labelfields{fidx};

  % This is guaranteed to exist but may be empty.
  thisrawlist = labelraw.(thisfield);

  [ safelabellist safetitlelist ] = euUtil_makeSafeStringArray( thisrawlist );


  % Translate known label types.

  if strcmp(thisfield, 'sessionlabel')
    for lidx = 1:length(thisrawlist)

      [ thisdate thissuffix ] = ...
        euChris_parseSetLabel_loop2302( thisrawlist{lidx} );

      if ~isnan(thisdate)
        [ thisyear thismonthnum thismonthshort thismonthlong thisday ] = ...
          euUtil_parseDateNumber(thisdate);
        if ~isnan(thisyear)
          thislabel = ...
            sprintf('%02d %s %d', thisday, thismonthshort, thisyear );
        else
          thislabel = sprintf('%02d %s', thisday, thismonthshort );
        end
        if ~isempty(thissuffix)
          thislabel = [ thislabel ' ' thissuffix ];
        end
        safetitlelist{lidx} = thislabel;
      end

    end
  elseif strcmp(thisfield, 'caselabel')
    for lidx = 1:length(thisrawlist)

      [ thisband thiscurrent thisphase ] = ...
        euChris_parseCaseLabel_loop2302( thisrawlist{lidx} );

      if ~isempty(thisband)
        thislabel = thisband;
        if ~isnan(thiscurrent)
          thislabel = sprintf('%s %duA', thislabel, thiscurrent);
        end
        if ~isempty(thisphase)
          thislabel = [ thislabel ' ' thisphase ];
        end
        safetitlelist{lidx} = thislabel;
      end

    end
  end


  % Save derived lists.

  labeltext.(thisfield) = safetitlelist;
  labelshort.(thisfield) = safelabellist;

  for lidx = 1:length(safelabellist)
    % Fieldnames have to start with a letter.
    labelkey.(thisfield){lidx} = [ 'x' safelabellist{lidx} ];
  end

end



% Build the output structure.

datameta = struct();

datameta.winbefore = winbefore;
datameta.winafter = winafter;
datameta.winbeforetext = winbeforetext;
datameta.winbeforelabel = winbeforelabel;
datameta.winaftertext = winaftertext;
datameta.winafterlabels = winafterlabels;

datameta.labelraw = labelraw;
datameta.labeltext = labeltext;
datameta.labelshort = labelshort;
datameta.labelkey = labelkey;


% Done.
end


%
% This is the end of the file.
