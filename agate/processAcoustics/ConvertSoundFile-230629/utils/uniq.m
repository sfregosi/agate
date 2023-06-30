function [y,i] = uniq(x)
% y = UNIQ(x)
%    Return vector x with runs of identical elements shortened to one element.
%    This is a little like the unix uniq command.  Often you will want to sort
%    x into ascending or descending order before calling uniq.
%
%    If x is a matrix, it is reshaped to a vector.  The uniq operation can
%    not operate columnwise, since different numbers of elements might be
%    in each column after removing duplicates.
%
% [y,i] = UNIQ(x)
%    A second return argument specifies the indices of the elements that are
%    returned.  For runs of repeated elements, the index of the first in the 
%    sequence is used.  i is a row vector.
%
% See also sort.

if (length(x) == 0)
  y = x;
  i = [];
  return
end

y = x(:).';		% make into a vector

n = length(y);
i = find([1 y(1:n-1) ~= y(2:n)]);
y = y(i);

if (nRows(x) > nCols(x))
  y = y.';
end
