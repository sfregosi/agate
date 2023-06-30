function t = removeExtraBlanks(s)
%removeExtraBlanks	Remove duplicate blanks from a string
%
% t = removeExtraBlanks(s)
%   In string s, change every sequence of two or more blanks to a single blank.

x = (s == ' ');
t = s([logical(1) ~(x(1 : length(x) - 1) & x(2 : length(x)))]);
