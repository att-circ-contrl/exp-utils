% This turns off messages from FT and from the NPY library.

% Set FT defaults via "evalc" again, to suppress the banner again.
evalc('ft_defaults');

ft_notice('off');
ft_info('off');

% We'll sometimes get lots of warnings about deprecated config fields.
ft_warning('off');

% NPy loves to complain about text data.
% Use "warning(warnstate)" to restore warnings.
warnstate = warning('off');

% This is the end of the file.
