function conditiontab = euMeta_getBlockConditions_FLToken_2022_2023

% function conditiontab = euMeta_getBlockConditions_FLToken_2022_2023
%
% This function returns a table listing experiment condition parameters
% that correspond to each of the BlockCondition codes used in an experiment.
%
% This implementation translates codes used in the Frey and Wotan FLToken
% datasets from 2022 and 2023.
%
% No arguments.
%
% "conditiontab" is a table with columns 'blockCode', 'gainTokens', and
%   'lossTokens'. Tokens gained are positive, tokens lost are negative.
%   'blockCode' is the offset-corrected BlockCondition code value, used in
%   BlockDef.txt and BlockData.txt.


conditiontab = table();

% No longer needed, since we're converting this when parsing the codes.
%conditiontab.blockCondition = [ 529 ; 530 ; 531 ; 532 ];

conditiontab.blockCode = [ 28 ; 29 ; 30 ; 31 ];
conditiontab.gainTokens = [ +3 ; +3 ; +2 ; +2 ];
conditiontab.lossTokens = [ -1 ; -3 ; -1 ; -3 ];


% Done.
end


%
% This is the end of the file.
