function badchanlist = euMeta_getBadChannels_FLToken_2022_2023

% function badchanlist = euMeta_getBadChannels_FLToken_2022_2023
%
% This function returns a hierarchical structure listing bad channels in
% each of the sessions of the Frey and Wotan FLToken datasets from 2022 and
% 2023.
%
% The bad channel list contains cooked labels, following the convention of
% the experiment log.
%
% No arguments.
%
% "badchanlist" is a channel list structure indexed by session and probe
%   labels, per CHANLISTS.txt.



% These are manually-compiled bad channel lists.

% Automated detection isn't perfect, so for each session, I plotted the
% results of the bad channel analysis and comiled lists of bad channels by
% hand based on those plots.

% These are cooked channel labels, just like the experiment log.


badchanlist = struct();



%
% Frey Sessions



% 2022 05 02 session.

scratch = struct();

scratch.('prACC1') = ...
{ 'CH_010', 'CH_012', 'CH_022', 'CH_030', 'CH_043', 'CH_045', 'CH_048', ...
  'CH_053', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% NOTE - 108, 109, and 110 are suspicious.
% Consistent across sessions, so marking as bad.
scratch.('prCD1') = ...
{ 'CH_073', 'CH_087', 'CH_088', 'CH_091', 'CH_094', ...
  'CH_108', 'CH_109', 'CH_110', ...
  'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

badchanlist.('FrProbe0222050200401') = scratch;



% 2022 05 03 session.

scratch = struct();

scratch.('prACC1') = ...
{ 'CH_002', 'CH_010', 'CH_012', 'CH_022', 'CH_030', 'CH_043', 'CH_045', ...
  'CH_048', 'CH_053', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% NOTE - 090, 092, and 095 are suspicious. So are 108, 109, and 110.
% 108/109/110 are consistent across sessions, so marking as bad.
scratch.('prCD1') = ...
{ 'CH_078', 'CH_094', ...
  'CH_108', 'CH_109', 'CH_110', ...
  'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

badchanlist.('FrProbe0222050300501') = scratch;



% 2022 05 04 session.

scratch = struct();

scratch.('prACC1') = ...
{ 'CH_002', 'CH_010', 'CH_012', 'CH_022', 'CH_030', 'CH_043', 'CH_045', ...
  'CH_048', 'CH_053', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% NOTE - 090, 092, and 095 are suspicious.
scratch.('prCD1') = ...
{ 'CH_078', 'CH_094', ...
  'CH_108', 'CH_109', 'CH_110', ...
  'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

badchanlist.('FrProbe0222050400601') = scratch;



% 2022 05 05 session.

scratch = struct();

scratch.('prACC1') = ...
{ 'CH_002', 'CH_010', 'CH_012', 'CH_022', 'CH_030', 'CH_043', 'CH_045', ...
  'CH_048', 'CH_053', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% It looks like the tip of the probe got damaged (or the cable traces for it).
% NOTE - 077 and 109 are suspicious.
scratch.('prCD1') = ...
{ 'CH_066', 'CH_067', 'CH_068', 'CH_069', 'CH_070', 'CH_071', 'CH_072', ...
  'CH_073', 'CH_074', 'CH_075', 'CH_076', ...
  'CH_078', 'CH_094', 'CH_111', 'CH_112', ...
  'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

badchanlist.('FrProbe0222050500701') = scratch;



% 2022 05 06 session.

scratch = struct();

scratch.('prACC1') = ...
{ 'CH_002', 'CH_010', 'CH_012', 'CH_022', 'CH_030', 'CH_043', 'CH_045', ...
  'CH_048', 'CH_053', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

scratch.('prCD1') = ...
{ 'CH_066', 'CH_067', 'CH_068', 'CH_069', 'CH_070', 'CH_071', 'CH_072', ...
  'CH_073', 'CH_074', 'CH_075', 'CH_076', ...
  'CH_078', 'CH_094', 'CH_109', 'CH_123', ...
  'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

badchanlist.('FrProbe0222050600801') = scratch;



% 2022 05 09 session.

scratch = struct();

% Probe tip span and 059 looked like they had 60 Hz interference.
scratch.('prACC1') = ...
{ 'CH_002', 'CH_010', 'CH_012', 'CH_022', 'CH_030', 'CH_043', 'CH_045', ...
  'CH_048', 'CH_053', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% Either the tip/cable damage healed or it was intereference instead of
% damage. Much less severe than previously.
% Lots of suspicious channels, but hard to disambiguate on spectrum plots.
scratch.('prCD1') = ...
{ 'CH_066', 'CH_067', 'CH_073', 'CH_074', 'CH_075', ...
  'CH_078', 'CH_094', 'CH_111', 'CH_112', 'CH_123', ...
  'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

badchanlist.('FrProbe0222050900901') = scratch;



% 2022 05 10 session.

scratch = struct();

badchanlist.('FrProbe0222051001001') = scratch;



% 2022 05 11 session.

scratch = struct();

badchanlist.('FrProbe0222051101101') = scratch;



% 2022 06 30 session.

scratch = struct();

badchanlist.('FrProbe0322063000102') = scratch;



% 2022 07 13 session.
% First manually-annotated one; hence more extensive notes.

scratch = struct();

% Also suspicious: 259, 260, 284, 291, 292, 304.
scratch.('prACC1') = ...
{ 'CH_257', 'CH_258', 'CH_269', 'CH_285', 'CH_286', 'CH_297', 'CH_300', ...
  'CH_316', 'CH_317', 'CH_318', 'CH_319', 'CH_320' };

% This looks like it had four very different layers.
% Also suspicious: 001, 002, 044.
% 016/017/018/045 might be a bad group or might be a real feature.
scratch.('prPFC1') = ...
{ 'CH_029', 'CH_030', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% This also seems to have layers and several different mixed types.
% Might be bad or might be real: 131/132/133 blob at 60-120 Hz.
scratch.('prCD1') = ...
{ 'CH_130', 'CH_158', 'CH_188', 'CH_189', 'CH_190', 'CH_191', 'CH_192' };

badchanlist.('FrProbe0322071300201') = scratch;



% 2022 07 21 session.

scratch = struct();

badchanlist.('FrProbe0322072100401') = scratch;



%
% Wotan sessions.



% 2023 02  session.

scratch = struct();

badchanlist.('') = scratch;



%
% This is the end of the file.
