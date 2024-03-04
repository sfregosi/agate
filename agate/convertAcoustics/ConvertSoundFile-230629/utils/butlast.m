function y = butlast(x)
%BUTLAST	Return all but the last element of a vector/column of a matrix.
%
% y = butlast(x)
%    If y is a vector, return the vector without the last element.
%    If y is a matrix, return the matrix without its last column.

[m,n] = size(x);
if (n == 1)
  y = x(1 : length(x)-1);
else
  y = x(:, 1 : nCols(x)-1);
end
