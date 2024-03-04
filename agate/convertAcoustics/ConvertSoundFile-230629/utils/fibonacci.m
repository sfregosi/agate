function f = fibonacci(n)
%FIBONACCI	Return the Nth Fibonacci number
%
% f = fibonacci(n)
%   Return the nth Fibonacci number. n can also be a vector or array, in which
%   case a vector or array of Fibonacci numbers is returned. Negative or zero n
%   is permitted.
%
%   It's assumed the Fibonacci sequence starts with 1, not 0, so 
%   fibonacci(1) is 1.
%
%   NB! Values of fibonacci(71) and above may be wrong because of
%   floating-point accuracy limitations.
%
% See also fibinverse.

phi = sqrt(5)/2 + 0.5;
f = round((phi.^n - (-phi).^-n) ./ sqrt(5));	% Binet's formula
