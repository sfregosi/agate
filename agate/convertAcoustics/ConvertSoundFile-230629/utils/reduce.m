function y = reduce(x, which)
% y = reduce(x, which)
% If x is a vector, return a smaller vector with elements corresponding
% to non-zero elements of the vector 'which'.  which may be shorter
% than x; in this case, the longer elements of x are thrown away.
%
% If x is a matrix, do the same thing on columns of x.
%
% As a special case, if x is a column vector and which is the vector [1],
% then x is treated as a matrix, and so is returned whole.
% To avoid this special case, make sure x is a row vector.

if (any(size(x) == [1 1]) & ~(nCols(x) == 1 & all(size(which) == [1 1])))
  y = x(find(which));
else 
  y = x(:, find(which));
end
