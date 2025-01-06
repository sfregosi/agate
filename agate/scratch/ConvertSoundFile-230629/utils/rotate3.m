function rotpts = rotate3(pts, axis, theta)
%ROTATE3        Rotate points in 3-space about a specified axis.
%
% rotatedPoints = rotate3(points, theta, [azimuth elevation]) 
%    Rotate the set of points in 3-space through angle theta about an axis 
%    defined by [azimuth elevation].  Angles are in radians.  points is a
%    3-column matrix, one point per row, and rotatedPoints is the same size.
%
%    Theta may be a vector, in which case it contains a set of angles.  
%    If the size of points is m-by-3 (i.e., m points) and the length of 
%    theta is n, then the size of rotatedPoints will be m-by-3n, with each
%    xyz triple represented n times horizontally, one triple for each 
%    element of theta.
%
% rotatedPoints = rotate3(points, theta, [x y z]) 
%    As above, but the axis of rotation is specified as a 3-vector.

% Convert axis to a unit vector.
if (length(axis) == 2)			% azim, elev
  axis = [cos(axis(2))*cos(axis(1))  cos(axis(2))*sin(axis(1))  sin(axis(2))];
elseif (length(axis) ~= 3)
  error('Axis must be specified as [azimuth elevation] or [x y z].');
end
axis = axis(:)/sqrt(sum(axis.^2));

% Construct rotation matrix.
x   = axis(1);
y   = axis(2);
z   = axis(3);
p   = cos(theta(:)');
q   = sin(theta(:)');
pm1 = 1 - p;

rx = [x.^2*pm1+p ;  x*y*pm1-z*q;  x*z*pm1+y*q];
ry = [x*y*pm1+z*q;  y.^2*pm1+p ;  y*z*pm1-x*q];
rz = [x*z*pm1-y*q;  y*z*pm1+x*q;  z.^2*pm1+p ];
      
n = length(theta) * 3;
r = [reshape(rx,1,n); reshape(ry,1,n); reshape(rz,1,n)];

% Do it!
rotpts = pts*r;
