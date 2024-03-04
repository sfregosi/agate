function [theta,dist] = sphereangle(lats, lons)
%SPHEREANGLE	Calculate great circle angles for a sphere
%
% theta = sphereangle(lats, lons)
%    Return the angles from the center of the sphere along great-circle
%    routes between adjacent points of the lats/lons vectors.  The
%    lats/longs are in degrees and should be vectors of the same size, or
%    either may be a scalar. If lats or lons is a non-vector array, it is
%    converted to a vector in MATLAB's usual column-major order. Results
%    are in radians, in a column vector whose length is one less than the
%    input vector(s).
%
% theta = sphereangle(latlons)
%    The latitude and longitude may alternatively be specified as a 2-column
%    array.
%
% [theta, dist] = sphereangle( ... )
%    Also return the distance on the surface of the Earth, in kilometers.
%    The Earth is assumed to be a sphere with radius 6375 km.
%
% See also latlong2xyz, latlong2meters, orthoProjection, earthRadius.
%
% Dave Mellinger, David.Mellinger@oregonstate.edu
% last modified 12/13/07

if (nargin == 1)
  lons = lats(:,2);
  lats = lats(:,1);
end

% Convert to radians.  Handle case where an arg is a scalar.
lats = lats(:) * (pi/180);
lons = lons(:) * (pi/180);
if (length(lats) == 1), lats = repmat(lats, length(lons), 1); end
if (length(lons) == 1), lons = repmat(lons, length(lats), 1); end

x = cos(lons) .* cos(lats);		% Note that
y = sin(lons) .* cos(lats);		%     x^2 + y^2 + z^2 = 1
z = sin(lats);

% Apply the law of cosines,   a . b = |a| |b| cos(theta)  with |a| = |b| = 1.
theta=acos(x(1:end-1).*x(2:end) + y(1:end-1).*y(2:end) + z(1:end-1).*z(2:end));

if (nargout > 1)
  earthRadius = 6375;				% radius of Earth, km
  dist = theta * earthRadius;
end
