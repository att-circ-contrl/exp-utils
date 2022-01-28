function cookeddefs = euUSE_parseEventCodeDefs( rawdefs, overrides )

% function cookeddefs = euUSE_parseEventCodeDefs( rawdefs, overrides )
%
% This parses raw event code definitions (as given by "jsondecode") and
% builds a structure containing processed event definitions.
%
% "rawdefs" is the decoded JSON event code definition structure.
% "overrides" is a structure containing specific event code fields that
%   overwrite automatically-generated fields in "cookeddefs".
%
% "cookeddefs" is a structure with fields indexed by event code names, each
%   of which contains a structure with the following fields (per
%   EVCODEDEFS.txt):
%   "value" is a scalar or a two-element vector, containing the event code
%     value or range of values ( [ min max ] ) for this code.
%   "description" is a cell array containing human-readable description
%     strings for the event code. There may be multiple strings if the code
%     is defined by multiple entries in "rawdefs" (as with ranged codes).
%   "offset" (optional) is a number to be subtracted from the code value
%     to convert it into a processed data value.
%   "multiplier" (optional) is a factor by which the code value is to be
%     multiplied to convert it into a processed value. This is not
%     automatically generated.
%
% When turning an event code value into a processed value, the formula used
% is:  processed = multiplier * (raw - offset)
%
% The idea is that the automatic parsing generates reasonable guesses for the
% interpretation of "FooMin" and "FooMax" definition pairs, and the
% "overrides" structure can modify these interpretations for known cases
% where automatic guesses aren't correct.


% Initialize output.
cookeddefs = struct();


% Build a scratch list to hold information about "Min"/"Max" pairs.
pairlist = struct();


% First pass: walk through the raw definitions, copying single entries to
% the output and anything that looks like a pair to the pair list.

rawnames = fieldnames(rawdefs);

for ridx = 1:length(rawnames)

  % Get this raw record.
  thisrawname = rawnames{ridx};
  thisrawdef = rawdefs.(thisrawname);
  thisvalue = thisrawdef.Value;
  thisdesc = thisrawdef.Description;

  % Look for "Min" and "Max" in the name.
  % We'll get zero or one token lists, and if we have a list, one token value.

  basename = '';
  tokenlist = regexp( thisrawname, '^\s*(.+)Max$', 'tokens' );
  if ~isempty(tokenlist)
    basename = tokenlist{1}{1};
  end
  tokenlist = regexp( thisrawname, '^\s*(.+)Min$', 'tokens' );
  if ~isempty(tokenlist)
    basename = tokenlist{1}{1};
  end

  % Either add this to the output list or save it as part of a pair list.

  if isempty(basename)
    % Individual entry.
    cookeddefs.(thisrawname) = ...
      struct( 'value', thisvalue, 'description', {{ thisdesc }} );
  else
    % Pair entry component.
    thispairdef = struct( 'range', [], 'descs', {{}} );
    if isfield(pairlist, basename)
      thispairdef = pairlist.(basename);
    end

    thispairdef.range = [ thispairdef.range thisvalue ];
    thispairdef.descs = [ thispairdef.descs { thisdesc } ];

    pairlist.(basename) = thispairdef;
  end

end


% Second pass: Walk through the pair list, adding pairs to the output.

pairnames = fieldnames(pairlist);

for pidx = 1:length(pairnames)

  % Get this record.
  thispairname = pairnames{pidx};
  thispairdef = pairlist.(thispairname);
  thispairrange = sort(thispairdef.range);
  thispairdesc = thispairdef.descs;

  % Complain if we have anything other than two entries. Otherwise continue.
  if length(thispairrange) ~= 2
    disp(sprintf( '###  Pair "%s" has %d contributors instead of 2.', ...
      thispairname, length(thispairrange) ));
  else
    cookeddefs.(thispairname) = ...
      struct( 'value', thispairrange, 'description', { thispairdesc } );

    % NOTE - The original idea was to set the offset to min(range), but
    % we ended up having to override this for all input cases. So, leave it
    % empty for now.
  end

end


% Third pass: Walk through the overrides list, updating the output list.

overnames = fieldnames(overrides);

for oidx = 1:length(overnames)
  thisname = overnames{oidx};
  thisoverdef = overrides.(thisname);

  if isfield(cookeddefs, thisname)
    fnames = fieldnames(thisoverdef);
    for fidx = 1:length(fnames)
      thisfname = fnames{fidx};
      thisfval = thisoverdef.(thisfname);
      cookeddefs.(thisname).(thisfname) = thisfval;
    end
  end
end


% Done.

end


%
% This is the end of the file.
