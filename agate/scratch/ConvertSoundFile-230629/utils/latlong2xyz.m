function [xyz,xyzEarth] = latlong2xyz(latD, lonD)
%latlong2xyz	Convert lat/long in degrees into an (x,y,z) position
%
% xyz = latlong2xyz(lat, lon)
%    Given latitude and longitude IN DEGREES, convert them to [x y z] vectors.
%    lat and lon are vectors of length N; the result is an Nx3 array.  The
%    origin of the (x,y,z) coordinate system is the center of the Earth; the
%    positive X-axis points toward (lat=0, lon=0), the positive Y-axis points
%    toward (lat=0, lon=90 E), and the positive Z-axis points toward the
%    celestial north pole. The length of the returned xyz vector is 1 -- that
%    is, the result is in units of Earth radii.
%
%    Remember that (lat,lon) are backwards of (x,y) -- that is, lat is in the
%    y-direction and lon is in the x-direction. 
%
% xyz = latlong2xyz(latlon)
%    The input argument may also be an Nx2 array of points, with latitude in
%    the first column and longitude in the second. lat/lon are IN DEGREES.
%
% [xyz,xyzEarth] = latlong2xyz( ... )
%    A second return argument gives the result in kilometers for a point on the
%    Earth, using an Earth radius at the center of your lat/lon array. See also
%    earthRadius.m.
%
% See also latlong2meters, sphereangle, earthRadius, orthoProjection.
%
% David.Mellinger@oregonstate.edu

if (nargin == 1)
  lonD = latD(:,2);
  latD = latD(:,1);
end

latR  = latD(:) * (pi/180);	% convert to radians
lonR  = lonD(:) * (pi/180);	% convert to radians

xyz  = [cos(latR).*cos(lonR)  cos(latR).*sin(lonR)  sin(latR)];

if (nargout > 1)
  radius = earthRadius(mean([min(latD(:)) max(latD(:))]));
  xyzEarth = xyz * radius;
end
