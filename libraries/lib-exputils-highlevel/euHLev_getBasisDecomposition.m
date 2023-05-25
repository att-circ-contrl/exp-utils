function [ fomlist basislist ] = euHLev_getBasisDecomposition( ...
  datavalues, basis_counts_tested, method, verbosity )

% function [ fomlist basislist ] = euHLev_getBasisDecomposition( ...
%   datavalues, basis_counts_tested, method, verbosity )
%
% This expresses a set of data vectors as the sum of several basis vectors.
% The basis vectors and sample vector coefficients are returned.
%
% The reason this tests multiple options for the number of basis vectors
% is that for some algorithms (such as PCA) you can get all options at once
% for the same cost as computing each of them individually.
%
% NOTE - Some methods (such as PCA) remove the mean. For these methods the
% mean is stored as an additional structure field in "basislist", per below.
%
% NOTE - Some methods (like doing ICA on the raw waveforms) take a while.
%
% "datavalues" is a Nvectors x Ntimesamples matrix of sample vectors. For
%   ephys data, this is typically Nchans x Ntimesamples.
% "basis_counts_tested" is a vector containing different values to test
%   for the number of basis vectors to return.
% "method" is 'pca' for principal component analysis, 'ica_raw' for
%   independent component analysis using the raw waveforms, 'ica_pca' to
%   perform PCA and then use ICA on the transformed input (transforming back
%   to input space after getting component vectors), and 'kmeans' for k-means
%   vector quantization.
% "verbosity" is 'normal' or 'quiet'.
%
% "fomlist" is a vector with one entry per entry in "basis_counts_tested",
%   containing a goodness-of-fit figure for each decomposition attempt.
%   Values that are more positive are better.
%   For 'pca', the figure of merit is the fraction of explained variance
%   (0.0 - 1.0).
%   For 'ica', the figure of merit is the fraction of explained variance
%   (0.0 - 1.0).
%   For 'kmeans', the figure of merit is the mean of the silhouette values
%   (-1.0 - 1.0).
% "basislist" is a cell array with one cell per entry in
%   "basis_counts_tested". Each cell contains a structure with the following
%   fields, per BASISVECTORS.txt:
%
%   "basisvecs" is a Nbasis x Ntimesamples matrix where each row is a basis
%     vector.
%   "coeffs" is a Nvectors x Nbasis matrix with basis vector weights for
%     each input vector. (coeffs * basisvecs) is an estimate of (datavalues).
%   "background" is a 1 x Ntimesamples vector containing a constant background
%     to be added to all vectors during reconstruction. This is typically
%     zero (for k-means or raw ICA) or the mean across sample vectors (for
%     PCA-based methods that discard the mean).


fomlist = [];
basislist = {};


if strcmp(method, 'kmeans')

  for countidx = 1:length(basis_counts_tested)

    nbasis = basis_counts_tested(countidx);

    [ thisfom thisbasis ] = nlBasis_getBasisKmeans( ...
      datavalues, nbasis, NaN, verbosity );

    if ~isnan(thisfom)
      fomlist(countidx) = thisfom;
      basislist{countidx} = thisbasis;
    end

  end

elseif strcmp(method, 'pca')

  % FIXME - This is wasteful; we only really need to call pca() once.

  for countidx = 1:length(basis_counts_tested)

    nbasis = basis_counts_tested(countidx);

    [ thisfom thisbasis ] = nlBasis_getBasisPCA( ...
      datavalues, nbasis, NaN, verbosity );

    if ~isnan(thisfom)
      fomlist(countidx) = thisfom;
      basislist{countidx} = thisbasis;
    end

  end

elseif strcmp(method, 'ica_raw')

  for countidx = 1:length(basis_counts_tested)

    nbasis = basis_counts_tested(countidx);

    [ thisfom thisbasis ] = nlBasis_getBasisDirectICA( ...
      datavalues, nbasis, NaN, verbosity );

    if ~isnan(thisfom)
      fomlist(countidx) = thisfom;
      basislist{countidx} = thisbasis;
    end

  end

elseif strcmp(method, 'ica_pca')

  for countidx = 1:length(basis_counts_tested)

    nbasis = basis_counts_tested(countidx);

    [ thisfom thisbasis ] = nlBasis_getBasisPCAICA( ...
      datavalues, nbasis, NaN, verbosity );

    if ~isnan(thisfom)
      fomlist(countidx) = thisfom;
      basislist{countidx} = thisbasis;
    end

  end

else

  disp([ '### [euHLev_getBasisDecomposition]  Unknown method "' method '".' ]);

end


% Done.
end


%
% This is the end of the file.
