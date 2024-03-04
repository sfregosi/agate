function y = digit(x, a0, a1, base)
% y = DIGIT(x, n)
%   Return the nth digit from the end of x.  The units digit is
%   number 0, the tens digit number 1, the hundreds digit number 2, etc.
%   Negative n works; negative x is converted to positive.
%
% y = DIGIT(x, n, m)
%   Return the value that is the nth through mth digits.
%   n and m may be in either order.
%   Example:  digit(1234567, 2, 3)  ==>  45
%
% y = DIGIT(x, n, m, base)
%   As above, but lets you specify the base.  Default is 10.
%
% Look at the MATLAB file format for an example of where DIGIT is useful.

if (nargin < 4), base = 10; end
if (nargin < 3), a1 = a0; end

n = min(a0, a1);
m = max(a0, a1);

y = rem(floor(abs(x) / base^n), base^(m-n+1));
