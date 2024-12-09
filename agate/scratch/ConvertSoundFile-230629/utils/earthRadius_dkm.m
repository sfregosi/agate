function r = earthRadius(lat)
%earthRadius		return the Earth's radius for a given latitude
%
% r = earthRadius(latitude)
%    Given a latitude IN DEGREES, return the radius of the Earth at that
%    latitude in kilometers.
%
%    The Earth is assumed to be an oblate ellipsoid (oblate spheroid) 
%    with polar radius 6356.752 km and equatorial radius 6378.137 km.
%    These are the WGS 1984 values, which are what GPS uses.   
%
%    The Earth's actual mean-sea-height radius, which varies over time
%    because of earthquakes, melting ice, tides, etc., and over space 
%    because of continents, rock density differences, etc., is within 
%    0.110 km of the value returned here.  Wikipedia's page "Earth radius"
%    explains many of the vagaries of calculating the radius.
%
% See also sphereangle, orthoProjection, latlong2xyz, latlong2meters.
%
% David.Mellinger@oregonstate.edu

a = 6378.137;		% equatorial radius, km (WGS 1984)
b = 6356.752;		% polar radius, km (WGS 1984)

latR = lat * pi/180;	% convert to radians

r = sqrt(((a^2 * cos(latR)).^2 + (b^2 * sin(latR)).^2) ./ ...
         ((a   * cos(latR)).^2 + (b   * sin(latR)).^2));
