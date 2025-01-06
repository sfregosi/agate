function m = nRows(array)
%   nRows(array) returns the number of rows in the array.  This is the size
%   of the first dimension, i.e., it is shorthand for size(array,1).
%
% See also nCols, size.

m = size(array,1);
