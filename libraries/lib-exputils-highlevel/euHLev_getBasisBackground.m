function newbasis = euHLev_getBasisBackground( oldbasis )

% function newbasis = euHLev_getBasisBackground( oldbasis )
%
% This takes a basis extraced by euHLev_getBasisDecomposition() and attempts
% to find a common background that doesn't contain basis vector components.
%
% The basis definition is modified to account for this common background
% (storing the background and modifying basis coefficients).
%
% This is safe to use with k-means and raw ICA; a background of zero will
% stay zero.
%
% "oldbasis" is a structure defining the basis decomposition, per
%   BASISVECTORS.txt.
%
% "newbasis" is a modified version of "oldbasis" with the same basis vectors
%   but with weight coefficients and the background modified.


newbasis = oldbasis;

scratch = size(oldbasis.coeffs);
nvectors = scratch(1);
nbasis = scratch(2);



% Express the supplied background as a linear combination of the basis
% vectors.
% NOTE - This helper function works best with orthogonal basis vectors.

[ bgcoeffs, bgresidue ] = ...
  euHLev_decomposeSignalsUsingBasis( oldbasis.background, oldbasis.basisvecs );


% Add the linear component to the coefficients and store the residue as the
% new background.

newbasis.background = bgresidue;
newbasis.coeffs = newbasis.coeffs + repmat(bgcoeffs, nvectors, 1);


% Done.
end


%
% This is the end of the file.
