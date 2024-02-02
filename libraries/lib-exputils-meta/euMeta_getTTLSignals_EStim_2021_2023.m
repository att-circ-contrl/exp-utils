function ttl_defs = euMeta_getTTLSignals_FLToken_2022_2023

% function ttl_defs = euMeta_getTTLSignals_FLToken_2022_2023
%
% This returns a structure containing information about how event code
% signals and boolean signals are packaged in ephys data for the Frey and
% Igor EStim datasets from 2021-2023 (tungsten for Frey, DBC for Igor).
%
% NOTE - The Frey data was recorded using the Intan recording controller,
% but the Igor data was recorded using Open Ephys. Both runs used the Intan
% stimulation controller as well.
%
% FIXME - Incomplete. Revise this!
%
% No arguments.
%
% "ttl_defs" is a structure with the following fields, per TTLSIGNALDEFS.txt.
%   Each field contains a single-bit signal definition structure or a code
%   signal definition structure per euUSE_readAllEphysEvents(). If no
%   signals are defined for a device, struct() is stored.
%   "codes_openephys" defines event code signals in data saved by Open Ephys.
%   "codes_intanrec" defines event code signals in Intan recorder data.
%   "codes_intanstim" defines event code signals in Intan stimulator data.
%   "bits_openephys" defines single-bit signals in data saved by Open Ephys.
%   "bits_intanrec" defines single-bit signals in Intan recorder data.
%   "bits_intanstim" defines single-bit signals in Intan stimulator data.


ttl_defs = struct();


% FIXME - Add reward TTL signals, and recorder/OpenE stim TTL signals!
ttl_defs.bits_openephys = struct();
ttl_defs.bits_intanrec = struct();
ttl_defs.bits_intanstim = struct( 'stimtrig', 'Din_002' );


% FIXME - Probably correct?
ttl_defs.codes_openephys = struct( ...
  'signameraw', 'rawcodes', 'signamecooked', 'cookedcodes', ...
  'channame', 'DigWordsA_000', 'bitshift', 8 );

% FIXME - Doublecheck this!
ttl_defs.codes_intanrec = struct( ...
  'signameraw', 'rawcodes', 'signamecooked', 'cookedcodes', ...
  'channame', 'Din_*', 'bitshift', 9 );

ttl_defs.codes_intanstim = struct( ...
  'signameraw', 'rawcodes', 'signamecooked', 'cookedcodes', ...
  'channame', 'Din_*', 'bitshift', 9 );


% Done.
end


%
% This is the end of the file.
