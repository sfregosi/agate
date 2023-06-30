function [x,flip] = columnize(x)
%COLUMNIZE	Make sure a vector is a column vector.
%
% [y,flip] = columnize(x)
%    If x is a row vector, make it a column vector.
%    If x is a column vector or matrix, leave it alone.
%    The return value flip indicates whether x was changed.
%
%    This function exists only because it's such a common operation 
%    to do at the start of a function.

flip = 0;
if (size(x,1) == 1)
  flip = 1;
  x = x.';
end
