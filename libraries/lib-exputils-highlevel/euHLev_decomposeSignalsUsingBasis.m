function [ coeffs residues ] = ...
  euHLev_decomposeSignalsUsingBasis( datavectors, basisvecs )

% function [ coeffs residues ] = ...
%   euHLev_decomposeSignalsUsingBasis( datavectors, basisvecs )
%
% This attempts to decompose one or more sample vectors using a previously
% extracted set of basis vectors (per BASISVECTORS.txt).
%
% NOTE - This will only give optimal output if the basis vectors are
% orthogonal! For non-orthogonal basis vectors, output will be valid but
% not necessarily minimum-energy.
%
% "datavectors" is a Nvectors x Ntimesamples matrix of sample vectors. For
%   ephys data, this is typically Nchans x Ntimesamples.
% "basisvecs" is a Nbasis x Ntimesamples matrix where each row is a basis
%   vector.
%
% "coeffs" is a Nvectors x Nbasis matrix with basis vector weights for each
%   input vector.
% "residues" is a Nvectors x Ntimesamples matrix containing the components of
%   the input vectors that could not be represented as a linear combination
%   of the basis vectors.
%
% (coeffs * basisvecs) + (residues) is an estimate of (datavectors).


scratch = size(datavectors);
nvectors = scratch(1);
ntimesamps = scratch(2);

scratch = size(basisvecs);
nbasis = scratch(1);

coeffs = zeros(nvectors, nbasis);
residues = zeros(nvectors, ntimesamps);


% First pass: Estimate coefficients by minimizing the energy in the residue
% after the corresponding basis vector is removed.
%
% c = sum( basis .* data ) / sum( basis .* basis )
%
% NOTE - If basis vectors are _not_ orthogonal, this will over-estimate at
% least some of the coefficients.

for bidx = 1:nbasis
  thisbasis = basisvecs(bidx,:);
  normfact = sum(thisbasis .* thisbasis);

  for vidx = 1:nvectors
    thisvec = datavectors(vidx,:);
    thiscoeff = sum(thisbasis .* thisvec) / normfact;
    coeffs(vidx,bidx) = thiscoeff;
  end
end


% Second pass: Scale the resulting coefficients by a constant to minimize the
% energy in the residue.
%
% c = sum( data .* recon ) / sum( recon .* recon )

recondata = coeffs * basisvecs;
normfact = sum(sum( datavectors .* recondata )) ...
  / sum(sum( recondata .* recondata ));
coeffs = coeffs * normfact;


% Get the reconstruction and the residue.

recondata = coeffs * basisvecs;
residues = datavectors - recondata;


% Done.
end


%
% This is the end of the file.
