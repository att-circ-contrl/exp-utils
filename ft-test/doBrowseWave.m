function doBrowseWave( thisdata, thistitle )

% function doBrowseWave( thisdata, thistitle )
%
% This pops up ft_databrowser() window for a specified list of waveform.
% The window is given the specified title.
%
% "thisdata" is a FT-processed data structure.
% "thistitle" is a character array containing the title to use.


browserconfig = struct( 'allowoverlap', 'yes' );
ft_databrowser(browserconfig, thisdata);
set( gcf(), 'Name', thistitle, 'NumberTitle', 'off' );


% Done.

end


%
% This is the end of the file.
