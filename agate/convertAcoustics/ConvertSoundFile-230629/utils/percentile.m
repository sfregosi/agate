function y = percentile(x, pct)
% y = PERCENTILE(x, pct)
%   Example: percentile(x, 0.10) is the value that is greater than 10% of the
%   elements of the vector x and less than the remaining 90%. If the length of x
%   is such that there is no element of x exactly corresponding to the 'pct'
%   position, linear interpolation of the two adjacent values is used. pct must
%   be between 0 and 1 inclusive.
%
%     percentile(x, 1)   is a slow way to get max(x).  
%     percentile(x, 0.5) is the median of x.
%     percentile(x, 0)   is a slow way to get min(x).  
%
%   If x is a matrix, percentile operates on columns, returning multiple
%   columns. If x has 3 or more dimensions, operates on the first dimension.
%   This hasn't been tested very much.
%
%   If pct is a vector, multiple rows are returned, one per element of pct. A
%   matrix-valued x and vector-valued pct can be combined so that the return
%   value is an array with rows corresponding to elements of pct and columns
%   corresponding to columns of x.
%
% See also median, sort, max, min.

if (size(x,1) == 1 && length(size(x)) < 3), x = x.'; end
if (any(pct < 0) || any(pct > 1))
  error('Percentile values should be between 0 and 1.');
end

s = size(x);
x = sort(x, 1);

% Find indices of desired values in x. These might not be integers.
n = ((size(x,1) - 1) * pct(:) + 1);
% Interpolate.
r = rem(n, 1);
r1 = r * ones(1, prod(s(2:length(s))));
y = (1-r1) .* x(n-r,:);
ix = find(r);			% when n=size(x,1), x(n+1,:) doesn't exist

if (size(y,2) > 0)
  y(ix,:) = y(ix,:) + r1(ix,:) .* x(n(ix)-r(ix)+1,:);
end

if (length(s) >= 3)
  y = reshape(y, [length(pct) s(2:length(s))]);
end
