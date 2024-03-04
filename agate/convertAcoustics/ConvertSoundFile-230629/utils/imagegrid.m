function surf = imagegrid(xpts, ypts, c)
%IMAGEGRID	Draw an image like imagesc, but at specified x- and y-points
%
% surf = imagegrid(c, xpts, ypts)
%   xpts defines the x-values where the samples in c are, and likewise for
%   ypts.  You should have xpts==size(c,2) and ypts=size(c,1).
%   The return value surf is a surface object, from pcolor (q.v.).
%
% See also image, imagesc, pcolor.


x = mean([xpts(1 : end-1); xpts(2:end)]);
y = mean([ypts( 1 : end-1); ypts( 2:end)]);
x = [(xpts(1)-(x(1)-xpts(1))) x (xpts(end)+(xpts(end)-x(end)))];
y = [(ypts (1)-(y(1)-ypts (1))) y (ypts (end)+(ypts (end)-y(end)))];

surf = pcolor(x, y, c([1:end end], [1:end end]));

set(surf, 'LineStyle', 'none')
set(gca, 'CLim', [min(c(:)) max(c(:))])  % needed for pcolor
