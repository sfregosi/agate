function A = spherePolygonArea(lat, lon)
% A = spherePolygonArea(lat, long)  DOESN'T WORK YET - NEED SPHERESURFACEANGLE
return

%   Measure the area of a convex polygon on the surface of a sphere.  The
%   vertices of the polygon are specified IN DEGREES as latitudes (from -90 
%   to +90 degrees) and longitudes (from -180 to 180 degrees or 0 to 360
%   degrees). Note that the corners of the polygon are connected by great
%   circle segments, so they don't follow latitude lines (except the equator).
%
%   The return value A is an area in fractions of a sphere (a value from
%   0 to 1), NOT stearadians.  Multiply by 4*pi if you want stearadians.
%
% A = spherePolygonAngle(latlong)
%   As above, but the lat/longs may be specified as a Nx2 array instead of 
%   separate vectors.

% Dave Mellinger
% Jun. 2012

% Make inputs into Nx2 array if they aren't yet.
if (nargin >= 2)
  lat = [lat(:) lon(:)];
elseif (nRows(lat) == 2 && nCols(lat) ~= 2)
  lat = lat.';
end

sumTri = 0;
for i = 3 : nRows(lat)
  angsum = triangleArea(lat(1,:), lat(i-1,:), lat(i,:));
  sumTri = sumTri + angsum;
end

A = sumTri / (4*pi);		% convert stearadians to fraction of a sphere

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function a = triangleArea(x,y,z)
% Return area of triangle (x,y,z) in stearadians.

a = sphereSurfaceAngle([x;y;z]) ...
  + sphereSurfaceAngle([y;z;x]) ...
  + sphereSurfaceAngle([z;x;y]) ...
  - pi;
