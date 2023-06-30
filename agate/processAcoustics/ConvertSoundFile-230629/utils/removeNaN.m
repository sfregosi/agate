function y = removeNaN(x)
%removeNaN	delete NaNs from a vector
%
% y = removeNaN(x)
%    Given a vector, delete the NaN's in it.
%
% See also NaN, isnan, zeroNaN.

y = x(~isnan(x));
