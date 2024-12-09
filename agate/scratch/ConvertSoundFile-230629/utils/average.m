function y = average(x, n)
%y = average(x, n)
%    Return in y the average of each n adjacent values of x.
%    y is n-1 elements shorter than x.
%
% This was originally written by Steve Mitchell.
% I lost his version and wrote this, so blame any mistakes on me.
% Dave Mellinger

y = filter(ones(1,n)/n, 1, x);
y(1 : n-1) = [];
