function y = last(x)
%LAST           Return the last element of a vector, or last column of a matrix
%
% y = last(x)
%   If x is a vector, return its last element.
%   If x is a matrix, return its last column.

if (isempty(x))
  y = x;
elseif (size(x,2) == 1)		% column vector
  y = x(length(x));
else
  y = x(:,size(x,2));
end
