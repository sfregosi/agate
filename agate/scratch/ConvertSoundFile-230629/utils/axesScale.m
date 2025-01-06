function s = axesScale(ax, units, dims)
% scale = axesScale(axesobj, distanceunits, dim)
%
% Return the scaling, in units-per-screendistance, of an axes object.
% The units are the units specified on the x- and y-axes of the axes.
%
% All arguments are optional.  
%    The axes object defaults to the current axes (gca).
%    The distanceunits argument tells what to measure the screen size in;
%        if this argument is absent or equals the empty string, the default
%        is 'inches'.
%    The dim arg tells what axes to return; the default is [1 2], meaning 
%        return a two-element vector with the respective scale values for 
%        x and y.  If it equals 1, just return x scale, etc.

if (nargin < 1), ax = gca;             end
if (nargin < 2), units = '';           end
if (isempty(units)), units = 'inches'; end
if (nargin < 3), dims = [];            end
if (~length(dims)), dims = [1 2];      end

set(ax, 'Units', units);
pos = get(ax,'position');
s = [(diff(get(ax,'xlim')) / pos(3)) ...
     (diff(get(ax,'ylim')) / pos(4))];
s = s(max(min(dims,2),1));
