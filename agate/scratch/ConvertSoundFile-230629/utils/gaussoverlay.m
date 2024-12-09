function [plt,x,y] = gaussoverlay(mean, sd, area)
% plt = gaussoverlay(mean, sd, area)
%    Given a specification of a gaussian (mean, stdev, and total area
%    under the curve), overlay a graphic of it on the current plot.
%    Returns the plot object, allowing you to change its color
%    (like set(plt, 'Color', 'r')), line style, etc.
%
% [plt,x,y] = gaussoverlay(mean, sd, area)
%    Also return the x- and y-coords of the points in the curve that 
%    were plotted.
%
% See also gauss, plot (for colors and line styles).
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu

hold on
s = 4 * sd;		% plot curve 4 stdevs away from the mean
ng = 100;		% number of points to compute in gaussian
x = linspace(mean-s, mean+s, ng);
y = gauss(x,mean,sd) * area;
plt = plot(x, y);
hold off
