function y = isabsent(x)
%ISABSENT	Return true if an argument is [] or NaN, false otherwise.
%
% This shorthand is convenient for processing optional arguments to a function.
% Use it like this:
%
%     if (nargin < 2 || isabsent(arg2)), arg2 = ...default value...; end

y = (isempty(x) || all(isnan(x)));
