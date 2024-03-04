function xyMeters = latlong2meters(q, lon, projPt)
%xyMeters		convert (latitude,longitude) coords to (x,y) meters
%
% xyMeters = latlong2meters(latlon)
%   Given an Nx2 array of positions with each row having a latitude and 
%   longitude IN DEGREES, return an array of N rows, each row having an
%   (x,y) position in meters.  The (x,y) positions returned are relative to
%   the position given in the first row of latlon, so the first row of the
%   return value xyMeters is always (0,0).
%
%   The input array, latlon, may have columns of
%         [latDegrees lonDegrees]
%   or
%         [latDegrees latMinutes lonDegrees lonMinutes]
%   or
%         [latDegrees latMinutes latSeconds lonDegrees lonMinutes lonSeconds]
%
%   WARNING: '(lat,lon)' is inherently backwards from '(x,y)' -- that
%   is, lat is the y direction and lon is the x.  So the values returned
%   are BACKWARDS from the values that are input.  It's done this way
%   because the standard in the nautical world is to have latitude first,
%   and the standard in mathematics is to have x first.
%
% xyMeters = latlong2meters(lat, lon)
%   You can also pass in the lat and lon arrays separately.  As above,
%   these should have each position on a separate row, and as above, the
%   position can be in degrees, or degrees-and-minutes, or 
%   degrees-and-minutes-and-seconds.  If lon is empty, then the arguments
%   are treated as in the first case up above, i.e. with a latlon array.
%
% xyMeters = latlong2meters(lat, lon, projPt)
% xyMeters = latlong2meters(latlon, [], projPt)
%   By default, the (lat,lon) points are orthographically projected onto a
%   plane tangent to the Earth at the first point of your array of points. You
%   can also specify the point, projPt, used for the projection, which is the
%   origin for the returned (x,y) values. This is helpful when you're
%   converting lat/long in multiple calls and you want the same projection used
%   every time. projPt should be a 2-element vector [lat lon], with values IN
%   DEGREES.
%
% See also latlong2xyz, orthoProjection, sphereangle, earthRadius.
%
% David.Mellinger@oregonstate.edu

if (nargin == 1 || (nargin >= 2 && isempty(lon)))
  if (nCols(q) == 2)           % Lat and long expressed in degrees.
    lat = q(:,1);
    lon = q(:,2);
  elseif (nCols(q) == 4)       % Lat and long expressed in degrees and minutes.
    lat = q(:,1:2) * [1; 1/60];
    lon = q(:,3:4) * [1; 1/60];
  elseif (nCols(q) == 6)       % Lat and long in degrees, minutes, seconds.
    lat = q(:,1:3) * [1; 1/60; 1/3600];
    lon = q(:,4:6) * [1; 1/60; 1/3600];
  else
    error('The lat/long argument is in the wrong format.');
  end
elseif (nargin >= 2)
  % Two args: first is lat, second is lon.
  lat = q;
  if (nCols(lat) == 2), lat = lat * [1; 1/60];         end
  if (nCols(lat) == 3), lat = lat * [1; 1/60; 1/3600]; end
  if (nCols(lon) == 2), lon = lon * [1; 1/60];         end
  if (nCols(lon) == 3), lon = lon * [1; 1/60; 1/3600]; end
end

if (any(abs(lat) > 90))
  error('Latitude is more than 90; you probably switched lat and long.')
end

if (nargin >= 3)                % user-specified projPt?
  if (length(projPt) ~= 2)
    error('The projection point should be specified as a [lat long] pair.');
  end
else                            % no projPt given; use first point of lat/lon
  projPt = [lat(1) lon(1)];
end

xyUnit = orthoProjection(lat, lon, projPt(1), projPt(2));
xyMeters = xyUnit * earthRadius(projPt(1)) * 1000;   % earthRadius returns km

% Print result if it's not being returned.
if (nargout < 1)
  printf('%10.2f    %10.2f\n', xyMeters.')
  clear xyMeters           % don't have MATLAB print it again 
end

