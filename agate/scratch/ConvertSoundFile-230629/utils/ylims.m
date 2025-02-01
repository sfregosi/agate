function lims = ylims(lo, hi)
%YLIMS		set y-limits of the current plot
%
% ylims(lo,hi)
%   This is shorthand for set(gca, 'YLimits', [lo hi]),
%   except that it does the right thing if lo > hi.
%
% ylims([lo hi])
%   Same as above.
%
% ylims(vec)
%   This is shorthand for set(gca, 'YLimits', [min(vec) max(vec)]).
%
% ylims('auto')
%   Set the y-axis limits so the endpoints are nice round numbers.
%   MATLAB does the work.
%
% ylims('manual')
%   Freezes the limits so MATLAB will not change them upon, say, printing.
%
% ylims('fit')
%   Set the y-axis limits so the first and last data points in the plot are
%   at the ends of the displayed range.
%
% ylims('fit+' [,whitespace])
%   Like fit (above), with a margin of extra white space at each end of the 
%   plot.  The fraction of white space is given by whitespace; it defaults 
%   to 0.10.
%
% ylims('mouse')
%   Gets two mouse clicks from the user on the figure and sets the
%   x- and y-limits to the specified rectangle.
%
% ylims('mousey')
%   Gets two mouse clicks from the user on the figure and sets
%   the y-limit, but not the x-limit, to the specified range.
%
% --------------------
%
% yl = ylims(...)
%   All of the above forms return the new y-limits.
%
%
% See also YLIM (MathWorks's version of this), XLIMS, ZLIMS, 
%    SET(gca, ...), GET(gca).
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu
% 9 May 01

if (nargin == 0)
  % do nothing
elseif (isstr(lo))
  if (strcmp(lo, 'auto') | strcmp(lo, 'manual'))
    set(gca, 'YLimMode', lo);
  elseif (strcmp(lo, 'fit') | strcmp(lo, 'fit+'))   % fit axis limits to data
    m = Inf;
    M = -Inf;
    for ch = get(gca, 'Children').'
      tt = get(ch, 'Type');
      %if (any(strmtch1(tt, 'line','image','patch','surface')))
      if (any(strmtch1(tt, str2mat('line','image','patch','surface'))))
	d = get(ch, 'YData');
	d(isnan(d) | isinf(d)) = [];
	m = min(m, min(min(d)));
	M = max(M, max(max(d)));
      end
    end
    if (strcmp(lo, 'fit+'))
      frac = 0.10;				% default: add 10% extra
      if (nargin > 1) frac = hi; end
      d = iff(M == m, M/2, (M - m)) * frac;	% add frac extra on each end
      M = M + d;
      m = m - d;
    end
    if (m == M), m = m - 1; M = M + 1; end
    if (~isinf(m) & ~isinf(M))
      set(gca, 'YLim', [m M]);
    end
  elseif (strncmp(lo, 'mouse', 5))		% mouse, mousey
    disp('Please mouse-click twice on the figure.')
    [x,y] = ginput(2);
    set(gca, 'YLim', [min(y) max(y)]);
    if (strcmp(lo, 'mouse'))
      set(gca, 'XLim', [min(x) max(x)]);
    end
  else
    error(['Unknown option passed to ylims: ''' lo '''']);
  end
elseif (nargin == 1) 				% 1 numeric arg: vector limits
  if (length(lo) == 2), ylims(lo(1), lo(2));
  else ylims(min(lo), max(lo));
  end
else						% 2 numeric args
  yl = get(gca, 'YLim');
  if (strcmp(get(gca, 'YDir'), 'reverse'))
    yl = fliplr(yl);
  end
  if (isnan(lo)), lo = yl(1); end
  if (isnan(hi)), hi = yl(2); end
  if (lo < hi)
    set(gca, 'YLim', [lo hi], 'YDir', 'normal');
  else
    set(gca, 'YLim', [hi lo], 'YDir', 'reverse')
  end
end

if (nargout > 0 | nargin == 0)
  lims = get(gca, 'YLim');
  if (strcmp(get(gca, 'YDir'), 'reverse'))
    lims = fliplr(lims);
  end
end
