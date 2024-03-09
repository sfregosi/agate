function y = isdigit(x)
%ISDIGIT	True for digit characters.
%
% y = isdigit(x)
%    Given a string x, return a value y the same shape as x with 1's where x
%    has digit characters and 0's elsewhere.  Digits are simply '0' to '9'.
%    x need not be a string, merely have values in the right range.
%
% See also ISLETTER, ISSPACE, ISSTR, IS2POWER, ISEMPTY, 

y = (x >= '0') & (x <= '9');
