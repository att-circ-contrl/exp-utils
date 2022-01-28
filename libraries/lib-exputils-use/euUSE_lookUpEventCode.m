function [ codedata codelabel ] = euUSE_loopUpEventCode( codeword, codedefs)

% function [ codedata codelabel ] = euUSE_loopUpEventCode( codeword, codedefs)
%
% This function looks up the event code definition for a specified code word.
% The translated event code data value, if applicable, is generated.
%
% "codeword" is the event code word to translate.
% "codedefs" is a "cooked" event code definition structure per
%   "EVCODEDEFS.txt".
%
% "codedata" is a translated data value corresponding to this event code, if
%   translation is appropriate, or a copy of "codeword" if not.
% "codelabel" is the field name of the corresponding entry in "codedefs", if
%   the code was understood. This is usually a human-readable code name. If
%   the code was not recognized, this is an empty character array ('').


% Initialize as "unrecognized".
codedata = codeword;
codelabel = '';


% FIXME - Walk through all code definition entries rather than doing a clever
% lookup. Unless there's an absurd number of entries this should be fast.

deflabels = fieldnames(codedefs);

% Track offset and multiplier outside the loop, so it only gets applied once
% if there are multiple matching entries (shouldn't happen).
thisoffset = 0;
thismult = 1;

for didx = 1:length(deflabels)

  thislabel = deflabels{didx};
  thisdef = codedefs.(thislabel);
  thisrange = thisdef.value;

  if (codeword <= max(thisrange)) && (codeword >= min(thisrange))
    % We have a match.
    codelabel = thislabel;

    % Get the new offset and multiplier.
    thisoffset = 0;
    thismult = 1;
    if isfield(thisdef, 'offset')
      thisoffset = thisdef.offset;
    end
    if isfield(thisdef, 'multiplier')
      thismult = thisdef.multiplier;
    end
  end

end

% Apply the offset and multiplier, if we found them.
codedata = codedata - thisoffset;
codedata = codedata * thismult;


% Done.

end


%
% This is the end of the file.
