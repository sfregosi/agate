function y = minmax(x)
%minmax		Return the minimum and maximum values of a vector
%
% y = minmax(x)
%   Given a vector x, return the minimum and maximum values of x as a 
%   1x2 vector.   Returns strange results if x is not a vector.

y = [min(x) max(x)];
