function euPlot_plotBasisCharts( basislist, fomlist, fompattern, ...
  chanlist, window_sizes_ms, size_labels, titleprefix, obase )

% function euPlot_plotBasisCharts( basislist, fomlist, fompattern, ...
%   chanlist, window_sizes_ms, size_labels, titleprefix, obase )
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
% "chanlist" is a cell array containing channel names for Nchannels signals.
% "window_sizes_ms" is a cell array. Each cell contains a plot time range
%   [ begin end ] in milliseconds, or [] for the full data extent.
% "size_labels" is a cell array containing filename-safe labels used when
%   creating filenames and annotating titles for plots of each window size.
% "titleprefix" is the prefix used when generating figure titles.
% "obase" is the prefix used when generating output filenames.


% FIXME - NYI.


% Done.
end


%
% This is the end of the file.
