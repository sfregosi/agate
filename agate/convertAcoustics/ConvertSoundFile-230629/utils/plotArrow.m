function ln = plotArrow(x, y, xArrow, yArrow, arrowhead)
% ln = plotArrow(x, y, xArrow, yArrow)
%    Plot a set of points with associated velocity vectors.
%    The velocities are specified by (xArrow, yArrow).
%    The return value is the vector of line objects that make up the arrows.

ln = plot([x; x+xArrow], [y; y+yArrow]);
