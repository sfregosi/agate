function y = signpow(x, e)
%SIGNPOW     Raise a number to a power, preserving sign.
%
% y = signpow(x,exponent)
%    Returns x to the e power, preserving the sign of x:
%
%                   e
%                |x|  * sign(x)

% Dave Mellinger
% 10/99

y = abs(x) .^ e .* sign(x);
