function euPlot_plotBasisCharts( basislist, fomlist, fompattern, ...
  timeseries, chanlist, window_sizes_ms, size_labels, titleprefix, obase )

% function euPlot_plotBasisCharts( basislist, fomlist, fompattern, ...
%   timeseries, chanlist, window_sizes_ms, size_labels, titleprefix, obase )
%
% This makes a spreadsheet and several plots describing the decomposition of a
% series of channel signals into a linear combination of basis signals.
%
% This is intended to be used with the output of euHLev_getBasisDecomposition.
%
% A "foms.csv" file contains figures of merit as a function of the number of
% basis vectors.
%
% A "coeffs.png" plot shows the contributions of each basis vector to each
% channel's signal.
%
% A "basis.png" plot shows the basis vector signals.
%
% "basislist" is a cell array containing structures that have basis vector
%   information in the following fields:
%   "basisvecs" is a Nbasis x Ntimesamples matrix where each row is a basis
%     vector signal.
%   "coeffs" is a Nchannls x Nbasis matrix with basis vector weights for each
%     input vector. (coeffs * basisvecs) is an estimate of the original
%     Nchannels x Ntimesamples data matrix.
% "fomlist" is a vector containing a figure of merit for each of the cases
%   in "basislist".
% "fompattern" is a sprintf pattern for formatting figures of merit.
% "timeseries" is a vector containing time axis points for plotting basis
%   vectors.
% "chanlist" is a cell array containing channel names for Nchannels signals.
% "window_sizes_ms" is a cell array. Each cell contains a plot time range
%   [ begin end ] in milliseconds, or [] for the full data extent.
% "size_labels" is a cell array containing filename-safe labels used when
%   creating filenames and annotating titles for plots of each window size.
% "titleprefix" is the prefix used when generating figure titles.
% "obase" is the prefix used when generating output filenames.


% Get metadata.

listcount = length(basislist);
basiscountlist = [];

for lidx = 1:listcount
  thiscoeffs = basislist{lidx}.coeffs;
  thissize = size(thiscoeffs);
  basiscountlist(lidx) = thissize(2);
end

% Make channel labels plot-safe.
[ scratch chanlist ] = euUtil_makeSafeStringArray( chanlist );



% Save a table with figures of merit.

% NOTE - Doing this by hand instead of with tables.

tabletext = sprintf( '"%s", "%s"\n', 'Basis Count', 'Score' );

for lidx = 1:listcount
  tabletext = [ tabletext sprintf( [ '%d, ' fompattern '\n' ], ...
    basiscountlist(lidx), fomlist(lidx) ) ];
end

nlIO_writeTextFile( [ obase '-foms.csv' ], tabletext );



% Prepare for plotting.

% Get a scratch figure.
thisfig = figure();
figure(thisfig);

% Get a basis vector palette.
cols = nlPlot_getColorPalette();
palette_basis = {};
for lidx = 1:listcount
  palette_basis{lidx} = ...
    nlPlot_getColorSpread(cols.red, basiscountlist(lidx), 240);
end



% Plot the basis vectors.
% FIXME - Not breaking this down into zoom levels!
% FIXME - Using hard-coded cursors!

for lidx = 1:listcount
  clf('reset');

  thisbasiscount = basiscountlist(lidx);
  thisbasis = basislist{lidx}.basisvecs;
  thispalette = palette_basis{lidx};

  hold on;

  plot( timeseries, zeros(size(timeseries)), 'Color', cols.blk, ...
    'HandleVisibility', 'off' );

  thismin = min(min(thisbasis));
  thismax = max(max(thisbasis));

  plot( [ 0 0 ], [ thismin thismax ], 'Color', cols.blk, ...
    'HandleVisibility', 'off' );

  for bidx = 1:thisbasiscount
    plot( timeseries, thisbasis(bidx,:), 'Color', thispalette{bidx}, ...
      'DisplayName', [ 'basis ' num2str(bidx) ] );
  end

  hold off;

  xlabel('Time (s)');
  ylabel('Amplitude (a.u.)');

  title([ titleprefix ' - ' num2str(thisbasiscount) ' Basis Vecs' ]);

  legend('Location', 'northwest');

  saveas( thisfig, sprintf('%s-vecs-%02d.png', obase, thisbasiscount) );
end



% Plot the decomposition of signals into basis vectors (weight coefficients).

for lidx = 1:listcount
  clf('reset');

  thisbasiscount = basiscountlist(lidx);
  thisallcoeffs = basislist{lidx}.coeffs;
  thispalette = palette_basis{lidx};
  chanseries = 1:length(chanlist);

  hold on;

  plot( chanseries, zeros(size(chanseries)), 'Color', cols.blk, ...
    'HandleVisibility', 'off' );

  for bidx = 1:thisbasiscount
    plot( chanseries, thisallcoeffs(:,bidx), 'Color', thispalette{bidx}, ...
      'DisplayName', [ 'basis ' num2str(bidx) ] );
  end

  hold off;

  % Kludge: Set tick labels to channels instead of using categorical data.
  set( gca, 'XTick', chanseries, 'XTickLabel', chanlist );

  xlabel('Channel');
  ylabel('Amplitude (a.u.)');

  title([ titleprefix ' - ' num2str(thisbasiscount) ' Basis Mixing' ]);

  legend('Location', 'northwest');

  saveas( thisfig, sprintf('%s-mix-%02d.png', obase, thisbasiscount) );
end



% Done.
end


%
% This is the end of the file.
