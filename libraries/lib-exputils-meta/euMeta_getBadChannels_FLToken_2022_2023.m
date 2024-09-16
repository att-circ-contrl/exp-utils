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


% NOTE - I suspect a channel map error. CH_059 looks like it should be
% next to CH_014.



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

scratch.('prACC1') = ...
{ 'CH_002', 'CH_010', 'CH_012', 'CH_022', 'CH_030', 'CH_043', 'CH_045', ...
  'CH_048', 'CH_053', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% No _good_ channels to compare to.
% 066 through 076 look suspicious, but are LF dominated, not 60 Hz.
scratch.('prCD1') = ...
{ 'CH_078', 'CH_094', ...
  'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

badchanlist.('FrProbe0222051001001') = scratch;



% 2022 05 11 session.

scratch = struct();

scratch.('prACC1') = ...
{ 'CH_002', 'CH_010', 'CH_012', 'CH_022', 'CH_030', 'CH_043', 'CH_045', ...
  'CH_048', 'CH_053', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% Lots of suspicious channels that showed up before: 083, 090, 092, 104,
% 106, 107, 108, 111, 112.
% 066 through 076 have a big blob, but are LF dominated, not 60 Hz.
scratch.('prCD1') = ...
{ 'CH_078', 'CH_094', ...
  'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

badchanlist.('FrProbe0222051101101') = scratch;



% 2022 06 30 session.
% Different probes, looks like.

scratch = struct();

% Suspicious: 067, 068, 069, 090, 091, 092, 109, 110.
scratch.('prCD1') = ...
{ 'CH_081', 'CH_094', ...
  'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

% Suspicious: 014, 046, 059
% Nice-looking LFP activity and spiking (from spectrum): 026
scratch.('prCD2') = ...
{ 'CH_002', 'CH_030', ...
  'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

badchanlist.('FrProbe0322063000102') = scratch;



% 2022 07 13 session.
% First manually-annotated one; hence more extensive notes.

scratch = struct();

% Also suspicious: 259, 260, 284, 291, 292, 304.
scratch.('prACC1') = ...
{ 'CH_257', 'CH_258', 'CH_269', 'CH_285', 'CH_286', 'CH_297', 'CH_300', ...
  'CH_316', 'CH_317', 'CH_318', 'CH_319', 'CH_320' };

% This looks like it had four very different layers.
% Also suspicious: 002, 044.
% 016/017/018/045 might be a bad group or might be a real feature.
% Suspicious: 031, 046, 059.
scratch.('prPFC1') = ...
{ 'CH_001', 'CH_029', 'CH_030', ...
  'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% This also seems to have layers and several different mixed types.
% Might be bad or might be real: 131/132/133 blob at 60-120 Hz.
scratch.('prCD1') = ...
{ 'CH_130', 'CH_158', ...
  'CH_188', 'CH_189', 'CH_190', 'CH_191', 'CH_192' };

badchanlist.('FrProbe0322071300201') = scratch;



% 2022 07 21 session.

scratch = struct();

% Suspicious: 289, 303, 304, 315.
scratch.('prACC1') = ...
{ 'CH_257', 'CH_269', 'CH_284', 'CH_285', 'CH_286', 'CH_297', 'CH_300', ...
  'CH_316', 'CH_317', 'CH_318', 'CH_319', 'CH_320' };

% Suspicious spectra, but I think it may be legit activity:
% 331, 332, 333, 334, 348, 349, 350, 363, 367, 368, 369, 370
% If there _aren't_ bad channels, channels with LFP or spiking look extreme.
scratch.('prACC2') = ...
{ 'CH_380', 'CH_381', 'CH_382', 'CH_383', 'CH_384' };

scratch.('prPFC1') = ...
{ 'CH_030', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% Suspicious: 159, 173, 174, 187.
scratch.('prCD1') = ...
{ 'CH_130', 'CH_158', 'CH_188', 'CH_189', 'CH_190', 'CH_191', 'CH_192' };

badchanlist.('FrProbe0322072100401') = scratch;



%
% Wotan sessions.



% 2023 02 13 session.

scratch = struct();

% NOTE - Very hard to tell bad channels apart from channels with unusual
% spectra.

scratch.('prACC1') = ...
{ 'CH_102', 'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

% 53 also suspicious.
scratch.('prACC2') = ...
{ 'CH_030', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% Also suspicious: 197, 198, 240, 241.
scratch.('prPFC1') = ...
{ 'CH_222', 'CH_252', 'CH_253', 'CH_254', 'CH_255', 'CH_256' };

% Also suspicious: 145, 146, 147.
scratch.('prPFC2') = ...
{ 'CH_167', 'CH_188', 'CH_189', 'CH_190', 'CH_191', 'CH_192' };

scratch.('prCD1') = ...
{ 'CH_334', 'CH_350', 'CH_380', 'CH_381', 'CH_382', 'CH_383', 'CH_384' };

% Also suspicious: 257, 258.
scratch.('prCD2') = ...
{ 'CH_286', 'CH_316', 'CH_317', 'CH_318', 'CH_319', 'CH_320' };

badchanlist.('WoProbe0123021300301') = scratch;



% 2023 02 22 session.

scratch = struct();

% Also suspicious: 091, 094.
scratch.('prACC1') = ...
{ 'CH_068', 'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

scratch.('prACC2') = ...
{ 'CH_030', 'CH_039', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

scratch.('prPFC1') = ...
{ 'CH_206', 'CH_222', 'CH_252', 'CH_253', 'CH_254', 'CH_255', 'CH_256' };

% Also suspicious: 355, 356, 373, 374, 375
scratch.('prCD1') = ...
{ 'CH_334', 'CH_350', 'CH_380', 'CH_381', 'CH_382', 'CH_383', 'CH_384' };

scratch.('prCD2') = ...
{ 'CH_270', 'CH_286', 'CH_316', 'CH_317', 'CH_318', 'CH_319', 'CH_320' };

badchanlist.('WoProbe0123022200701') = scratch;



% 2023 02 23 session.

scratch = struct();

% NOTE - Channel order looks iffy.

% Also suspicious: 091, 095.
scratch.('prACC1') = ...
{ 'CH_094', 'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

% Also suspicious: 004
scratch.('prACC2') = ...
{ 'CH_030', 'CH_039', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% Also suspicious: 196, 207, 242.
scratch.('prPFC1') = ...
{ 'CH_222', 'CH_252', 'CH_253', 'CH_254', 'CH_255', 'CH_256' };

scratch.('prCD1') = ...
{ 'CH_334', 'CH_350', 'CH_380', 'CH_381', 'CH_382', 'CH_383', 'CH_384' };

% Also suspicious: 260.
scratch.('prCD2') = ...
{ 'CH_286', 'CH_316', 'CH_317', 'CH_318', 'CH_319', 'CH_320' };

badchanlist.('WoProbe0123022300801') = scratch;



% 2023 02 24 session.

scratch = struct();

scratch.('prACC1') = ...
{ 'CH_094', 'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

% Tones: 001, 017
scratch.('prACC2') = ...
{ 'CH_030', 'CH_039', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% Also suspicious: 203, 207. Maybe features.
scratch.('prPFC1') = ...
{ 'CH_222', 'CH_252', 'CH_253', 'CH_254', 'CH_255', 'CH_256' };

% Also suspicious: 346, 347.
scratch.('prCD1') = ...
{ 'CH_334', 'CH_350', 'CH_380', 'CH_381', 'CH_382', 'CH_383', 'CH_384' };

% Also suspicious: 273 (tone), 284.
scratch.('prCD2') = ...
{ 'CH_286', 'CH_316', 'CH_317', 'CH_318', 'CH_319', 'CH_320' };

badchanlist.('WoProbe0123022400901') = scratch;



% 2023 02 27 session.

scratch = struct();

% Can't tell if suspicious or spiky: 068.
scratch.('prACC1') = ...
{ 'CH_094', 'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

% Also suspicious: 004.
scratch.('prACC2') = ...
{ 'CH_030', 'CH_039', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% Also suspicious: 197, 198, 207, 240, 241.
scratch.('prPFC1') = ...
{ 'CH_222', 'CH_252', 'CH_253', 'CH_254', 'CH_255', 'CH_256' };

% Looks like channel mapping errors.
scratch.('prCD1') = ...
{ 'CH_334', 'CH_336', 'CH_350', ...
  'CH_380', 'CH_381', 'CH_382', 'CH_383', 'CH_384' };

% Also suspicious: 273, 284.
scratch.('prCD2') = ...
{ 'CH_286', 'CH_316', 'CH_317', 'CH_318', 'CH_319', 'CH_320' };

badchanlist.('WoProbe0123022701001') = scratch;



% 2023 02 28 session.

scratch = struct();

scratch.('prACC1') = ...
{ 'CH_091', 'CH_094', 'CH_095', ...
  'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

% Also suspicious: 014.
scratch.('prACC2') = ...
{ 'CH_030', 'CH_039', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% 199 and 201 might be false positives, but look a lot like 206.
scratch.('prPFC1') = ...
{ 'CH_199', 'CH_201', 'CH_206', 'CH_222', ...
  'CH_252', 'CH_253', 'CH_254', 'CH_255', 'CH_256' };

scratch.('prCD1') = ...
{ 'CH_334', 'CH_350', ...
  'CH_380', 'CH_381', 'CH_382', 'CH_383', 'CH_384' };

% Also suspicious: 262.
scratch.('prCD2') = ...
{ 'CH_270', 'CH_286', 'CH_316', 'CH_317', 'CH_318', 'CH_319', 'CH_320' };

badchanlist.('WoProbe0123022801101') = scratch;



% 2023 03 01 session.

scratch = struct();

% Also suspicious: 068, 095.
scratch.('prACC1') = ...
{ 'CH_094', 'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

scratch.('prACC2') = ...
{ 'CH_030', 'CH_039', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% Also suspicious: 240, 241.
scratch.('prPFC1') = ...
{ 'CH_196', 'CH_222', ...
  'CH_252', 'CH_253', 'CH_254', 'CH_255', 'CH_256' };

scratch.('prCD1') = ...
{ 'CH_334', 'CH_350', ...
  'CH_380', 'CH_381', 'CH_382', 'CH_383', 'CH_384' };

scratch.('prCD2') = ...
{ 'CH_286', 'CH_297', 'CH_316', 'CH_317', 'CH_318', 'CH_319', 'CH_320' };

badchanlist.('WoProbe0123030101201') = scratch;



% 2023 03 02 session.

scratch = struct();

% Also suspicious: 068, 101, 109, 110.
scratch.('prACC1') = ...
{ 'CH_094', 'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

scratch.('prACC2') = ...
{ 'CH_030', 'CH_039', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% Also suspicious: 207.
scratch.('prPFC1') = ...
{ 'CH_222', ...
  'CH_252', 'CH_253', 'CH_254', 'CH_255', 'CH_256' };

scratch.('prCD1') = ...
{ 'CH_334', 'CH_350', ...
  'CH_380', 'CH_381', 'CH_382', 'CH_383', 'CH_384' };

% Also suspicious: 271, 272. Spiking on 273?
scratch.('prCD2') = ...
{ 'CH_286', 'CH_316', 'CH_317', 'CH_318', 'CH_319', 'CH_320' };

badchanlist.('WoProbe0123030201301') = scratch;



% 2023 03 03 session.

scratch = struct();

% Also suspicious: 095, 110
scratch.('prACC1') = ...
{ 'CH_078', 'CH_094', 'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

scratch.('prACC2') = ...
{ 'CH_030', 'CH_039', 'CH_060', 'CH_061', 'CH_062', 'CH_063', 'CH_064' };

% Also suspicious: 240, 241.
scratch.('prPFC1') = ...
{ 'CH_222', ...
  'CH_252', 'CH_253', 'CH_254', 'CH_255', 'CH_256' };

scratch.('prCD1') = ...
{ 'CH_334', 'CH_350', ...
  'CH_380', 'CH_381', 'CH_382', 'CH_383', 'CH_384' };

% Also suspicious: 260.
scratch.('prCD2') = ...
{ 'CH_286', 'CH_316', 'CH_317', 'CH_318', 'CH_319', 'CH_320' };

badchanlist.('WoProbe0123030301401') = scratch;



% 2023 03 07 session.

% Probes seem to have been swapped/changed.
% Channel mapping seems iffy on several probes (ACC1, PFC1, CD1).

scratch = struct();

scratch.('prACC1') = ...
{ 'CH_094', 'CH_098', ...
  'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

scratch.('prACC2') = ...
{ 'CH_158', ...
  'CH_188', 'CH_189', 'CH_190', 'CH_191', 'CH_192' };

scratch.('prPFC1') = ...
{ 'CH_350', 'CH_368', 'CH_369', ...
  'CH_380', 'CH_381', 'CH_382', 'CH_383', 'CH_384' };

% Also suspicious: 471, 480, 483, 486, 494.
scratch.('prCD1') = ...
{ 'CH_462', 'CH_478', ...
  'CH_508', 'CH_509', 'CH_510', 'CH_511', 'CH_512' };

% No obvious bad channels. New probe?
scratch.('prCD2') = ...
{ 'CH_444', 'CH_445', 'CH_446', 'CH_447', 'CH_448' };

badchanlist.('WoProbe0123030701601') = scratch;



% 2023 03 08 session.

scratch = struct();

scratch.('prACC1') = ...
{ 'CH_095', 'CH_098', ...
  'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

% Suspicious but might be spiky:  130, 145, 149.
% Suspicious but might be LFP+spikes:  142, 159, 161, 162.
scratch.('prACC2') = ...
{ 'CH_158', ...
  'CH_188', 'CH_189', 'CH_190', 'CH_191', 'CH_192' };

% Suspicious but might be LFP+spikes:  327, 329, 334, 350, 351.
scratch.('prPFC1') = ...
{ 'CH_380', 'CH_381', 'CH_382', 'CH_383', 'CH_384' };

% Also suspicious:  457
% Suspicous but might be an activity feature:  467, 468.
scratch.('prCD1') = ...
{ 'CH_462', 'CH_478', ...
  'CH_508', 'CH_509', 'CH_510', 'CH_511', 'CH_512' };

% Suspicious low frequency stuff:  387, 414, 417.
scratch.('prCD2') = ...
{ 'CH_429', ...
  'CH_444', 'CH_445', 'CH_446', 'CH_447', 'CH_448' };

badchanlist.('WoProbe0123030801701') = scratch;



% 2023 03 09 session.

scratch = struct();

% Also suspicious:  109
scratch.('prACC1') = ...
{ 'CH_094', 'CH_095', ...
  'CH_124', 'CH_125', 'CH_126', 'CH_127', 'CH_128' };

scratch.('prACC2') = ...
{ 'CH_158', ...
  'CH_188', 'CH_189', 'CH_190', 'CH_191', 'CH_192' };

% It looks like this is a different probe _and_ one ribbon cable was bad.
% Basically, only 334-365 are _good_.
% Also suspicious:  354, 358.
scratch.('prPFC1') = ...
{ 'CH_321', 'CH_322', 'CH_323', 'CH_324', 'CH_325', 'CH_326', ...
  'CH_327', 'CH_328', 'CH_329', 'CH_330', 'CH_332', 'CH_332', 'CH_333', ...
  'CH_366', 'CH_367', 'CH_368', 'CH_369', 'CH_370', 'CH_371', 'CH_372', ...
  'CH_373', 'CH_374', 'CH_375', 'CH_376', 'CH_377', 'CH_378', 'CH_379', ...
  'CH_380', 'CH_381', 'CH_382', 'CH_383', 'CH_384' };

% Also suspicious:  489.
scratch.('prCD1') = ...
{ 'CH_462', 'CH_478', ...
  'CH_508', 'CH_509', 'CH_510', 'CH_511', 'CH_512' };

% Suspicious low frequency stuff:  387, 414.
scratch.('prCD2') = ...
{ 'CH_429', ...
  'CH_444', 'CH_445', 'CH_446', 'CH_447', 'CH_448' };

badchanlist.('WoProbe0123030901801') = scratch;



%
% This is the end of the file.
