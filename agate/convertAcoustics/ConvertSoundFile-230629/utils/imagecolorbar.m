function obj = imagecolorbar(C, rightside)
%IMAGECOLORBAR	draw a colorbar indicating the range of displayed values
%
% obj = imagecolorbar(C)
%    Given an array C that was drawn with IMAGESC (q.v.), draw a colorbar
%    at the right edge showing whale colors correspond to what values.
%    The axes object for the colorbar is returned.
%
% obj = imagecolorbar(C, rightside)
%    A second arg says whether to position the color bar at the right (1)
%    or bottom (0) of the image.
%
%
% See also IMAGE, IMAGESC, AXES, COLORMAP.

ncolors = 100;				% number of color cells shown
barpos = [0.91  0.20  0.04  0.60];	% where to display the color bar

if (nargin < 2), rightside = 1; end

m = min(min(C));
M = max(max(C));

% Make original object smaller.
set(gca, 'Units', 'normalized');
x = get(gca, 'Position');
im = linspace(m, M, ncolors);		% the image to display as the colorbar
if (rightside)
  % Leave room at right side.
  set(gca, 'Position', [0.1 x(2) 0.7 x(4)]);
  im = im';
else
  % Leave room at bottom.
  set(gca, 'Position', [x(1) 0.1 x(3) 0.7]);
  barpos = barpos([2 1 4 3]);		% exchange x and y
end

hold on;
axes('Units', 'normalized', 'Position', barpos);
hold off
imagesc([0 1], [m M], im);
set(gca, 'YDir', 'normal', 'XTick', [], 'TickDIr', 'out');

obj = gca;
