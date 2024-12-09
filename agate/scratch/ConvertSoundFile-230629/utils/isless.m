function y = isless(x0, varargin)
%ISLESS		True for sequences of arguments all increasing.
%
% y = isless(x0, x1, x2, ...)
%   Returns 1 if x0 < x1 < x2 < ... , and 0 otherwise.  Each x must be the
%   same size as the others, or scalar, and y will be the same size as the x's.
%
% See also <, lt, islesseq.

y = ones(size(x0));
x = x0;
for i = 1 : nargin-1
  y = y & (x < varargin{i});
  x = varargin{i};
end
