function [n,x,p] = loghist(y,m)
%LOGHIST	Histogram scaled logarithmically in y
%
% [n,x,p] = loghist(y,m)
%    Plot a histogram like hist(x,m), but scale the y-axis logarithmically.
%    The bottom edge of the plot is at y=0.5, and the histogram is white.  
%    Unlike hist, this function always makes a plot.  The return values n and
%    x are like the return values of hist.  As with hist, m defaults to 10.
%
%    p is the set of patch objects plotted.  Use something like
%        set(p, 'FaceColor', 'r')
%    to change the color of the histogram.
%
% See also hist, bar, patch.
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu
% 12 Mar 02

if (nargin < 2)
  m = 10;
end

% Any of the following could be turned into optional input args.
ybot = 0.5;		% bottom edge of histogram bars; must be positive
barwidth = 1.0;		% width of histogram bars; see bar.m
barcolor = 'w';		% make the bars white

% The only thing really different from hist() is that the bottom edge of
% the patch objects is at y=ybot, not y=0. (Of course, y=0 can't be plotted
% logarithmically.)
[n,x] = hist(y,m);
p = bar(x, n, barwidth, barcolor); 

xd = get(p, 'XData');
yd = get(p, 'YData');
yd0 = find(yd == 0);
yd(yd0) = ones(length(yd0), 1) * ybot;
% Matlab bug: need to set XData too.
set(p, 'XData', xd, 'YData', yd, 'EdgeColor', 'k')
set(gca, 'YScale', 'log')
ylims(ybot, NaN)			% adjust bottom edge to be at ybot
