function lims = samelimits(whichaxis, subplots, lim)
%samelimits	Make axis limits the same for a set of axes.
%
% lims = samelimits(whichaxis, subplots)
%   For two or more subplots, make their axis limits the same.  'whichaxis'
%   is either 'x', 'y', 'z', or 'c' (for color).  The subplots may be
%   specified as a vector of axes object handles or a vector of subplot
%   numbers; in the latter case, the numbers may be either 3-digit numbers
%   MNP as used by subplot, or a cell vector of 3-element arrays [m n p].

if (nargin < 3), lim = []; end
if (length(lim) < 2 || any(isnan(lim)))
  % Find lowest and highest limits over all subplots.
  li = [];
  for i = 1 : length(subplots)
    switchto(subplots(i));
    li = minmax([li get(gca, [whichaxis 'Lim'])]);  % XLim, YLim, ZLim, or CLim
  end
  if (length(lim) < 1 || isnan(lim(1))), lim(1) = li(1); end
  if (length(lim) < 2 || isnan(lim(2))), lim(2) = li(2); end
end

% Apply these limits to all the plots.
for i = 1 : length(subplots)
  switchto(subplots(i));
  set(gca, [whichaxis 'Lim'], lim);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function switchto(plotnum)
% 'plotnum' is either MNP or {[M N P]} (a subplot) or a handle (an axes()).

if (iscell(plotnum)), subplot(plotnum{1}(1), plotnum{1}(2), plotnum{1}(3));
elseif (plotnum == round(plotnum)), subplot(plotnum);
else axes(plotnum);					% handle
end
