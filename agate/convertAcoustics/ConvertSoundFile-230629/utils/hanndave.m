function win = hanndave(n)
%hanndave       Hann (hanning) window
%
% win = hanndave(n)
%   See "Hann function" in Wikipedia. That one is centered on 0 while this one
%   starts at 0. The endpoints are not zero, because this is intended to be used
%   as a window function, and if a window is 0, it's just throwing away data.

win = cos(pi * (1:n).'/(n+1) + pi/2) .^ 2;
