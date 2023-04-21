function keepflags = euPlot_decimatePlotsBresenham( keepcount, origarray )

% function keepflags = euPlot_decimatePlotsBresenham( keepcount, origarray )
%
% This selects a subset of elements of a supplied vector to keep, and
% returns a logical vector indicating which to keep and which to discard.
%
% The idea is to be able to say "newarray = origarray(keepflags)" afterwards,
% or filter other arrays with the same geometry.
%
% "keepcount" is the desired number of elements to keep.
% "origarray" is a vector or cell array of arbitrary type (usually a label
%   or channel list) with the same dimensions as the element array to filter.
%   This should be one-dimensional (matrix results are undefined).
%
% "keepflags" is a boolean vector with the same dimensions as "origarray"
%   that's true for elements to be kept and false for elements to discard.


keepflags = true(size(origarray));

origcount = length(origarray);

if origcount > keepcount

  % Use the Bresenham algorithm to decide which elements to keep.

  bres_err = round(0.5 * origcount);
  for oidx = 1:origcount
    bres_err = bres_err + keepcount;
    if bres_err >= origcount
      bres_err = bres_err - origcount;
    else
      keepflags(oidx) = false;
    end
  end

end


% Done.
end


%
% This is the end of the file.
