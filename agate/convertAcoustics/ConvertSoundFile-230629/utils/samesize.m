function b = samesize(x1, varargin)
%SAMESIZE	Are two or more arrays the same size?
%
% b = samesize(x1, x2, ...)
%   Returns 1 if x1 is the same size (same number of dimensions and same
%   size of each dimension) as the remaining arguments.  There can be any
%   number of remaining arguments, including 0.  The comparison is
%   done using ndims, so trailing singleton dimensions are ignored.

b = true;
if (nargin < 1), return; end

nd = ndims(x1);
sz = size(x1);

for i = 1 : length(varargin)
  nd1 = ndims(varargin{i});
  sz1 = size(varargin{i});
  if (nd1 ~= nd || any(sz(1:nd) ~= sz1(1:nd)))
    b = false;
    return
  end
end
