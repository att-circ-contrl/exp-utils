function newbasis = euHLev_getBasisBackground( oldbasis, method )

% function newbasis = euHLev_getBasisBackground( oldbasis, method )
%
% This takes a basis extraced by euHLev_getBasisDecomposition() and attempts
% to find a common background. The basis definition is modified to account
% for this common background (storing the new background and modifying basis
% coefficients).
%
% "oldbasis" is a structure defining the basis decomposition, per
%   BASISVECTORS.txt.
% "method" is 'residue' or 'extrema', per below.
%
% "newbasis" is a modified version of "oldbasis" with the same basis vectors
%   but with weight coefficients and the background modified.
%
%
% For the "residue" method:
%
% The new background is the part of the old background that doesn't contain
% basis vector components.
%
% This method is safe to use with k-means and raw ICA; a background of zero
% will stay zero.
%
%
% For the "extrema" method:
%
% For each basis vector, that basis times its maximum or minimum coefficient
% value is taken to be part of the background (in addition to the residue).


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


if strcmp(method, 'residue')

  % Nothing else to do.

elseif strcmp(method, 'extrema')

  % For each basis vector, get the smallest coefficient min/max and add that
  % component to the background, subtracting from the foreground.
  for bidx = 1:nbasis

    thiscoefflist = newbasis.coeffs(:,bidx);
    thismin = min(thiscoefflist);
    thismax = max(thiscoefflist);

    thiscoeff = thismin;
    if abs(thismax) < abs(thismin)
      thiscoeff = thismax;
    end

    thisvec = newbasis.basisvecs(bidx,:);
    newbasis.background = newbasis.background + thisvec * thiscoeff;

    thiscoefflist = thiscoefflist - thiscoeff;
    newbasis.coeffs(:,bidx) = thiscoefflist;
  end

else
  disp([ '### [euHLev_getBasisBackground]  Unknown method "' method '".' ]);
  newbasis = oldbasis;
end


% Done.
end


%
% This is the end of the file.
