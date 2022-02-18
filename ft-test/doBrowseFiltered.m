function doBrowseFiltered( titleprefix, ...
  data_wideband, data_lfp, data_spike, data_rect )

% function doBrowseFiltered( titleprefix, ...
%   data_wideband, data_lfp, data_spike, data_rect )
%
% This pops up ft_databrowser() windows for filtered waveform data.
% Windows are given titles that begin with the specified prefix.
%
% "titleprefix" is a string prepended to the window title.
% "data_wideband" is FT-processed wideband data.
% "data_lfp" is FT-processed local field potential data.
% "data_spike" is FT-processed spike-band data.
% "data_rect" is FT-processed rectified spike activity data.


browserconfig = struct( 'allowoverlap', 'yes');

ft_databrowser(browserconfig, data_wideband);
set( gcf(), 'Name', [ titleprefix ' Wideband' ], 'NumberTitle', 'off' );

ft_databrowser(browserconfig, data_lfp);
set( gcf(), 'Name', [ titleprefix ' LFP' ], 'NumberTitle', 'off' );

ft_databrowser(browserconfig, data_spike);
set( gcf(), 'Name', [ titleprefix ' Spikes' ], 'NumberTitle', 'off' );

ft_databrowser(browserconfig, data_rect);
set( gcf(), 'Name', [ titleprefix ' Rectified' ], 'NumberTitle', 'off' );


% Done.

end


%
% This is the end of the file.
