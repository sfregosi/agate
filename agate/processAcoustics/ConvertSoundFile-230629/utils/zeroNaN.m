function x = zeroNaN(x)
%zeroNaN	replace NaNs in a vector or matrix by zeros
%
% y = zeroNaN(x)
%    Given a vector or matrix, replace the NaN's in it with zeros.
%    The output is the same size as the input.
%
% See also NaN, isnan, removeNaN.

nx = isnan(x);
x(nx) = zeros(1, sum(sum(nx)));
