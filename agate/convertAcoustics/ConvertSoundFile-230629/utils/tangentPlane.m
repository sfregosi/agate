function v = tangentPlane(lat,lon)
%tangentPlane		find plane tangent to a point on a sphere
%
% v = tangentPlane(latlong)
%   Given N point(s) on a sphere described by latlong, a 2-column array with
%   columns of [latitude longitude] IN DEGREES and N rows, return a 2x3xN
%   array of vectors v that represents N planes tangent to each of the N points.
%   Each 2x3 slice of the array comprises two 3-element vectors of length 1,
%   the first row of 3 elements representing the x-axis and the second row
%   representing the y-axis.  The x-axis points eastward along a line of
%   latitude, and the y-axis points northward along a line of longitude.
%   If the point is the north or south pole, the x-axis points towards
%   Greenwich, i.e. along 0 longitude, and the y-axis is 90 degreees 
%   counterclockwise from it.
%
%  v = tangentPlane(lat, long)
%   Same as above, but with  the lat/longs provided as two separate arguments.
%   Each of 'lat' and 'long' should be a vector.

% Dave Mellinger

err = nargchk(1,2,nargin);
if (err)
  error(err)
end
if (nargin == 1)
  if (nCols(lat) ~= 2)
    error('Provide lat/long as a 2-element row vector, or as a 2-column array.')
  end
  lon = lat(:,2);
  lat = lat(:,1);
else
  if (any(size(lat) ~= size(lon)))
    error('Latitude and longitude vectors must be the same size.');
  end
  lon = lon(:);
  lat = lat(:);
end
if (any(lat > 90))
  error('Latitude is greater than 90 degrees, which makes no sense.')
end

ixN    = find(lat >= 0 & lat <  90);	% index of points in northern hemisphere
ixS    = find(lat <  0 & lat > -90);	% index of points in southern hemisphere
ixNPole = find(lat == 90);		% index of points at north pole
ixSPole = find(lat == -90);		% index of points at south pole

% Find a point (vLat,vLon) that is 90 degrees 'north' of (lat,lon).  'north'
% wraps around at the north pole.
xLat = zeros(length(lat), 1);
xLon = zeros(length(lon), 1);
yLat = zeros(length(lat), 1);
yLon = zeros(length(lon), 1);

xLat(ixN) = lat(ixN);
xLon(ixN) = lon(ixN) + 90;
yLat(ixN) = 90 - lat(ixN);	% goes over the pole
yLon(ixN) = vLon(ixN) + 180;

xLat(ixS) = lat(ixS);
xLon(ixS) = lon(ixS) + 90;
yLat(ixS) = 90 + lat(ixS);
yLon(ixS) = lon(ixS);

xLat(ixNPole | ixSPole) = 0;
xLon(ixNPole | ixSPole) = 0;
