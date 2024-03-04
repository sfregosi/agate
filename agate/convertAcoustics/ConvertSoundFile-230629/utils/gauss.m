function y = gauss(x, mean, sd)
%GAUSS		The Gaussian probability function (normal curve).
%
% y = gauss(x [,mean [,sd]])
%    The standard bell-shaped curve, i.e. the normalized Gaussian function.
%    x is the set of points at which to evaluate the Gaussian function.
%    The mean defaults to 0, and the standard deviation to 1.
%
%    Here's an example:
%           x = -4:0.01:4; plot(x, gauss(x))
%
%    The function is scaled so that the area under it is 1; to scale it
%    so the maximum of the curve is 1, just divide by gauss(0).
%
% See also gaussoverlay.
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu

if (nargin < 3), sd = 1.0; end
if (nargin < 2), mean = 0.0; end

y = 1 / sqrt(2 * pi) ./ sd .* ...
    exp( -1/2 * ((x - mean) ./ sd) .^ 2 );
