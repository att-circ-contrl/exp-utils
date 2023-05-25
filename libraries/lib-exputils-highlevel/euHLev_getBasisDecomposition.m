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

scratch = size(datavalues);
nvectors = scratch(1);
ntimesamps = scratch(2);

maxbasiscount = max(basis_counts_tested);

zeromean = zeros(1,ntimesamps);


% FIXME - Magic values.

% If we're doing ICA on PCA-transformed input, PCA parameters are picked
% by black magic.
pca_min_explained = 0.98;
pca_min_components = 3;
pca_max_components = 20;


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

    % FIXME - Bail out if we're asked for more clusters than data points.
    if nbasis > nvectors
      continue;
    end

    % NOTE - Adding timestamps, since this takes a while.

    if ~strcmp(verbosity, 'quiet')
      disp(sprintf( '.. Getting %d basis vectors using raw ICA (%s).', ...
        nbasis, char(datetime) ));
    end

    tic;

    ricamodel = rica( datavalues, nbasis);

    icatime = euUtil_makePrettyTime(toc);

    thisbasis = transpose( ricamodel.TransformWeights );
    thiscoeffs = transform( ricamodel, datavalues );


    % The FOM is the mean explained variance.
    % The explained variance fraction is the square of the correlation
    % coefficient, for well-behaved distributions.

    datarecon = thiscoeffs * thisbasis;
    rvalues = [];
    for vidx = 1:nvectors
      thisrmatrix = corrcoef( datarecon(vidx,:), datavalues(vidx,:) );
      rvalues(vidx) = thisrmatrix(1,2);
    end
    thisfom = mean(rvalues .* rvalues);
    datarecon = [];


    fomlist(countidx) = thisfom;
    basislist{countidx} = struct( ...
      'basisvecs', thisbasis, 'coeffs', thiscoeffs, 'background', zeromean );

    if ~strcmp(verbosity, 'quiet')
      disp(sprintf( ...
        '.. ICA with %d basis vectors gave a FOM of %.3f after %s.', ...
        nbasis, thisfom, icatime ));
    end

  end

elseif strcmp(method, 'ica_pca')

  % NOTE - Because this uses the covariance matrix, we need to have more
  % than one data vector.
  if nvectors < 2
    return;
  end

  if ~strcmp(verbosity, 'quiet')
    disp('.. Getting basis vectors using ICA on PCA-transformed input.');
  end


  % First pass: Get a PCA transformation into a lower-dimensional space.

  [ pcabasis, pcaweights, ~, ~, pcaexplained, pcamean ] = ...
    pca( datavalues, 'NumComponents', pca_max_components );

  % Handle the case where we had fewer components.
  pca_max_components = min(pca_max_components, length(pcaexplained));

  chosenpcacount = pca_max_components;
  chosenpcafom = sum( pcaexplained(1:pca_max_components) ) / 100;

  % Get the minimum number of components for which we explain the desired
  % amount of variance.
  for testcount = (pca_max_components - 1):-1:pca_min_components
    testfom = sum( pcaexplained(1:testcount) ) / 100;

    if testfom >= pca_min_explained
      chosenpcacount = testcount;
      chosenpcafom = testfom;
    end
  end

  % Get the basis vectors as _rows_, and the desired weights subset.
  % The mean is already a row vector.
  pcabasis = transpose(pcabasis);
  pcabasis = pcabasis(1:chosenpcacount,:);
  pcacoeffs = pcaweights(:,1:chosenpcacount);

  if ~strcmp(verbosity, 'quiet')
    disp(sprintf( '.. Used %d PCA components (%.1f %% of variance).', ...
      chosenpcacount, chosenpcafom * 100 ));
  end


  % Second pass: Perform ICA on the transformed input.

  for countidx = 1:length(basis_counts_tested)

    nbasis = basis_counts_tested(countidx);

    % Bail out if we're trying to get more basis vectors than data points.
    if nbasis > nvectors
      continue;
    end


    % Use the Nvectors x Npca coefficient matrix instead of Nvectors x Ntime
    % data matrix.
    ricamodel = rica( pcacoeffs, nbasis);

    % The ICA basis is in PCA space.
    icabasis = transpose( ricamodel.TransformWeights );
    icacoeffs = transform( ricamodel, pcacoeffs );


    % Invert the PCA transformation to get the time-domain basis vectors.

    % data = pcacoeffs * pcabasis
    % data = (icacoeffs * icabasis) * pcabasis
    % data = icacoeffs * (icabasis * pcabasis)
    % data = icacoeffs * thisbasis

    thisbasis = icabasis * pcabasis;
    thiscoeffs = icacoeffs;


    % The FOM is the mean explained variance.
    % The explained variance fraction is the square of the correlation
    % coefficient, for well-behaved distributions.

    % NOTE - We're reconstructing without the mean, here.
    % If we add the mean, most of the explained variance comes from it, so
    % our FOM is always nearly perfect.

    datarecon = thiscoeffs * thisbasis;
%    datarecon = datarecon + repmat( pcamean, nvectors, 1 );
    rvalues = [];
    for vidx = 1:nvectors
      thisdatavalue = datavalues(vidx,:) - pcamean;
      thisrmatrix = corrcoef( datarecon(vidx,:), thisdatavalue );
      rvalues(vidx) = thisrmatrix(1,2);
    end
    thisfom = mean(rvalues .* rvalues);
    datarecon = [];


    fomlist(countidx) = thisfom;
    basislist{countidx} = struct( ...
      'basisvecs', thisbasis, 'coeffs', thiscoeffs, 'background', pcamean );

    if ~strcmp(verbosity, 'quiet')
      disp(sprintf( ...
        '.. ICA with %d basis vectors gave a FOM of %.3f.', ...
        nbasis, thisfom ));
    end

  end

else

  disp([ '### [euHLev_getBasisDecomposition]  Unknown method "' method '".' ]);

end


% Done.
end


%
% This is the end of the file.
