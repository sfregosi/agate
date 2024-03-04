function y = roundnum(x, p)
% ROUNDNUM    Round a number to fewer significant digits.
%
% y = roundnum(x)
% Round x off to have only one significant digit.
%
% y = roundnum(x, prec)
% Round x to have prec significant digits.

if (nargin < 2), p = 1; end

z = 10 .^ (1 - p + floor(log10(x)));
y = z .* round(x./z);
