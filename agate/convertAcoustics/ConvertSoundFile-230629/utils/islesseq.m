function y = islesseq(x0, varargin)
%ISLESSEQ		True for sequences of arguments all nondecreasing.
%
% y = islesseq(x0, x1, x2, ...)
%   Returns 1 if x0 <= x1 <= x2 <= ... , and 0 otherwise.  Each x must be the
%   same size as the others, or scalar, and y will be the same size as the x's.
%
% See also <=, le, isless.

y = ones(size(x0));
x = x0;
for i = 1 : nargin-1
  y = y & (x <= varargin{i});
  x = varargin{i};
end
