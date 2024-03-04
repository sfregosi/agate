function n = fibinverse(f)
%FIBINVERSE	Find a number's index in the Fibonacci sequence
%
% n = fibinverse(f)
%   Given a Fibonacci number f, find its index in the Fibonacci sequence. f can
%   be a scalar or array, and negative or zero f is permitted.
%
%   The number 1 occurs twice in the Fibonacci sequence, at positions 1 and 2.
%   This function returns 1 in this case, not 2. (Consequently,
%   fibinverse(fibonacci(1:N)) is not 1:N, as it starts out 1 1 3 4 5 6....)
%   Similarly, for Fibonacci numbers that occur at both positive and negative
%   indices, the positive one is returned here.
%
%   It's assumed that the Fibonacci sequence starts with 1, not 0.
%
% See also fibonacci.

phi = sqrt(5)/2 + 0.5;
x = abs(f) * sqrt(5) + 0.5;
n = floor(log(x) / log(phi));

% Handle the special cases of f==0, f==1.
n(f == 0) = 0;
n(f == 1) = 1;

% Handle negative f.
ix = (f < 0);
n(ix) = -n(ix);
