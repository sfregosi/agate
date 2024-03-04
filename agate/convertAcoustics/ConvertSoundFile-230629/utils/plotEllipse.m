function ln = plotEllipse(ctr, sz, rot, xyscale)
%PLOTELLIPSE	Plot an ellipse/circle of a specified size, center, and rotation
%
% ln = plotEllipse(center, size, rotationDeg)
%    Plot an ellipse centered at the given position, with the given size, and
%    rotated clockwise by the specified amount IN DEGREES. The rotation defaults
%    to 0. 'size' has the desired diameters (not semi-major axes) of the
%    ellipse. 'center' and 'size' should be length-2 vectors (though if 'size'
%    is a scalar it specifies a diameter for the a circle). Assumes that the x-
%    and y-limits of the axes will not change from their current values. For
%    plotting circles on a lat/lon grid, multiply the size by
%               [sec(latitudeInDegrees * pi / 180)  1]
%
% ln = plotEllipse(center, size, rotationDeg, xyscale)
%    The last argument, xyscale, should be the ratio of the size of the
%    y-axis to the size of the x-axis in the completed plot.  This allows
%    the x- and y-limits to change after the ellipse is plotted. 

if (length(sz) < 2), sz = [sz sz]; end
if (nargin < 3), rot = 0; end
if (nargin < 4)
  xyscale = diff(get(gca, 'YLim')) / diff(get(gca, 'XLim'));
end

th = linspace(0, 2*pi, 500);			% 500 points in the ellipse
xy  = [cos(th)*sz(1); sin(th)*sz(2)].' / 2;	% specify semi-size of ellipse
rot = rot * pi/180;				% convert angle to radians
xy  = [xy(:,1)*xyscale xy(:,2)] * [cos(rot) -sin(rot); sin(rot) cos(rot)];
ln  = line(xy(:,1)/xyscale + ctr(1), xy(:,2) + ctr(2));
