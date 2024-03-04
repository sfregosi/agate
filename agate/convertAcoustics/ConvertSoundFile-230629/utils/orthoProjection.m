function [xy,xyEarth] = orthoProjection(latDeg, lonDeg, latPDeg, lonPDeg)
%orthoProjection	Calculate the (x,y) projection of a lat/long point
%
% xy = orthoProjection(latDeg, longDeg, latP, longP)
%    Given a point p=(latDeg,longDeg) IN DEGREES on the surface of a unit
%    sphere, calculate its orthographic projection onto the plane tangent to
%    the sphere at the point (latP,longP) [which are also in degrees]. The
%    result is a 2-element row vector [x y]. latDeg and longDeg may be column
%    vectors representing N points, in which case the result will be an Nx2
%    array.  In the (x,y) projected space, the positive X-axis is tangent to
%    the latitude line pointing eastward and the positive Y-axis is tangent to
%    the longitude line pointing along the surface of the sphere toward the
%    north pole. The origin of this (x,y) coordinate system is the latP/longP
%    point.
%
%    The latitude and longitude ARE IN DEGREES, NOT RADIANS!
%
%    ALSO BEWARE: The input args have the vertical arg (latitude) first,
%    while the output args have the horizontal arg (x) first. This is because
%    of opposing standards: the nautical world normally puts latitude first, 
%    while mathematics normally puts x first.
%
% [xy,xyEarthKm] = orthoProjection(latDeg, longDeg, latP, longP)
%    A second return argument gives the result in kilometers for a point on
%    the Earth.  See also earthRadius.m.
%    
% ... = orthoProjection(latlongDeg, latlongP)
%    As above, but the input points are in pairs -- i.e., latlongDeg is a
%    pair, [lat long], as is latlongP.  If latlongDeg has more than one point,
%    successive points are on successive rows in both latLongDeg and the return
%    value(s).
%
% See also sphereangle, earthRadius, latlong2meters, latlong2xyz.
%
% David.Mellinger@oregonstate.edu

% Handle the case where input args are lat/long pairs.
if (nargin == 2)
  lonPDeg = lonDeg(:,2);
  latPDeg = lonDeg(:,1);
  lonDeg = latDeg(:,2);
  latDeg = latDeg(:,1);
else
  latDeg = latDeg(:);               % make column vector
  lonDeg = lonDeg(:);               % make column vector
end

% Calculate and apply the projection matrix.
P = orthoProjectionMatrix(latPDeg * (pi/180), lonPDeg * (pi/180));
xyz  = latlong2xyz(latDeg, lonDeg);     % convert to (x,y,z) coords
xy = xyz * P;                           % apply map projection
xyEarth = xy * earthRadius(latPDeg);	% earthRadius is in km


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function P = orthoProjectionMatrix(latR, lonR)
% Calculate the projection matrix P for an orthographic map projection.
% P projects an (x,y,z) point onto the plane that is tangent to the
% given (latitude,longitude) point; "orthographic" means that the
% projection is done perpendicular to the plane.  In the projection, the
% positive X axis points eastward and the positive Y axis points
% northward along the surface.
%
% lat and long ARE IN RADIANS.
%
% For orientation of the (x,y,z) coordinate system, see latlong2xyz.m.
%
% If you have a point q represented as [x y z], then q*P is a 2-element
% row vector with the [x y] coordinates of the projected point.

P = [
    -sin(lonR)	-sin(latR)*cos(lonR) 
    cos(lonR)	-sin(latR)*sin(lonR)
    0		cos(latR)
    ];
