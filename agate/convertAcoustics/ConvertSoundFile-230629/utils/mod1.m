function y = mod1(x, m)
%MOD1		modulo function, but returns m instead of 0
%
% y = mod1(x, m)
%    Return x (mod m), except that if the result is 0, return m instead.
%    This is equal to (x-1 (mod m)) + 1.
%    
%    This function is useful if you have a series of items in a vector v
%    you want to cycle through repeatedly with some index i:
%    use  mod1(i, length(v)).
%
%    Note that mod1, like mod, always returns a positive number when m 
%    is positive.

y = rem(rem(x-1, m) + m, m) + 1;
