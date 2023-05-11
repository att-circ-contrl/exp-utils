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
% NOTE - Some methods (such as PCA) remove the mean. This is added as an
% additional basis vector, with the corresponding coefficient being 1.
%
% "datavalues" is a Nvectors x Ntimesamples matrix of sample vectors. For
%   ephys data, this is typically Nchans x Ntimesamples.
% "basis_counts_tested" is a vector containing different values to test
%   for the number of basis vectors to return.
% "method" is 'pca' for Principal Component Analysis, 'ica' for Independent
%   Component Analysis, and 'kmeans' for K-means vector quantization.
% "verbosity" is 'normal' or 'quiet'.
%
% "fomlist" is a vector with one entry per entry in "basis_counts_tested",
%   containing a goodness-of-fit figure for each decomposition attempt.
%   Values that are more positive are better.
% "basislist" is a cell array with one cell per entry in
%   "basis_counts_tested". Each cell contains a structure with the following
%   fields:
%
%   "basisvecs" is a Nbasis x Ntimesamples matrix where each row is a basis
%     vector.
%   "coeffs" is a Nvectors x Nbasis matrix with basis vector weights for
%     each input vector. (coeffs * vectors) is an estimate of (datavalues).


fomlist = [];
basislist = {};

scratch = size(datavalues);
nvectors = scratch(1);
ntimesamps = scratch(2);

maxbasiscount = max(basis_counts_tested);


if strcmp(method, 'kmeans')

  for countidx = 1:length(basis_counts_tested)

    nbasis = basis_counts_tested(countidx);

    % FIXME - Bail out if we're asked for more clusters than data points.
    if nbasis > nvectors
      continue;
    end

    if ~strcmp(verbosity, 'quiet')
%      disp(sprintf('.. Quantizing with k-means into %d vectors.', nbasis));
    end

    [ clustlabels, clustvecs, distsums ] = kmeans( datavalues, nbasis );

    thisbasis = clustvecs;

    thiscoeffs = zeros(nvectors, nbasis);
    for vidx = 1:length(nvectors)
      thiscoeffs(vidx, clustlabels(vidx)) = 1;
    end

    % Convert the distance measure into a "1 is best" measure.
    % Make sure FOMs from different basis counts can be meaningfully comapred.
    thisfom = mean(distsums);
    thisfom = log( 1 / (1 + thisfom) );

% FIXME - Silhouette might be a better FOM than distance. Use it instead.

    fomlist(countidx) = thisfom;
    basislist{countidx} = ...
      struct( 'basisvecs', thisbasis, 'coeffs', thiscoeffs );

    if ~strcmp(verbosity, 'quiet')
      disp(sprintf( ...
        '.. K-means quantization with %d vectors gave a FOM of %.2f.', ...
        nbasis, thisfom ));
    end

  end

elseif strcmp(method, 'pca')

  % NOTE - PCA limits the number of basis vectors to the dimensionality
  % of the sample vectors (Ntimesamps), not the nubmer of samples (Nchans)?

  % NOTE - Because this uses the covariance matrix, we need to have more
  % than one data vector.
  if nvectors < 2
    return;
  end

  if ~strcmp(verbosity, 'quiet')
    disp('.. Getting basis vectors using PCA.');
  end

  [ pcabasis, pcaweights, ~, ~, pcaexplained, pcamean ] = ...
    pca( datavalues, 'NumComponents', maxbasiscount );

  for countidx = 1:length(basis_counts_tested)

    nbasis = basis_counts_tested(countidx);

    thisfom = sum( pcaexplained(1:nbasis) );

    % In pcabasis, the columns are basis vectors. We want rows.
    thisbasis = transpose(pcabasis);
    thisbasis = thisbasis(1:nbasis,:);

    thiscoeffs = pcaweights(:,1:nbasis);

    % pcamean is a row vector; it gets added as an additional basis vector.
    thisbasis( nbasis + 1, : ) = pcamean;
    thiscoeffs( :, nbasis + 1 ) = 1;

    fomlist(countidx) = thisfom;
    basislist{countidx} = ...
      struct( 'basisvecs', thisbasis, 'coeffs', thiscoeffs );

    if ~strcmp(verbosity, 'quiet')
      disp(sprintf( ...
        '.. PCA with %d basis vectors gave a FOM of %.2f.', ...
        nbasis, thisfom ));
    end

  end

elseif strcmp(method, 'ica')

% FIXME - NYI.

else

  disp([ '### [euHLev_getBasisDecomposition]  Unknown method "' method '".' ]);

end


% Done.
end


%
% This is the end of the file.
