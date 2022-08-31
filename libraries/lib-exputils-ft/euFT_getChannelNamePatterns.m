function [ names_ephys names_digital names_stimcurrent names_stimflags ] = ...
  euFT_getChannelNamePatterns()

% function [ names_ephys names_digital names_stimcurrent names_stimflags ] = ...
%   euFT_getChannelNamePatterns()
%
% This function returns cell arrays of channel name patterns, suitable for
% use with ft_channelselection(). These will identify different types of
% channel in Open Ephys and Intan data read using the LoopUtil library.
%
% "names_ephys" contains patterns for analog ephys recording channels.
% "names_digital" contains patterns for TTL bit-line and word channels.
% "names_stimcurrent" has patterns for Intan stimulation current channels.
% "names_stimflags" hass patterns for Intan stimulation flag status channels.


% NOTE - These are magic values.

% FIXME - These are default names provided by Open Ephys and the Intan GUI.
% If the user changes them in the GUI, these patterns might not work!

names_ephys = { 'Amp*', 'CH*' };
names_digital = { 'Din*', 'Dout*', 'DigBits*', 'DigWords*' };
names_stimcurrent = { 'Stim*' };
names_stimflags = { 'Flags*' };


% Done.

end


%
% This is the end of the file.
