function lims = xlims(lo, hi)
%XLIMS		set x-limits of the current plot
%
% xlims(lo,hi)
%   This is shorthand for set(gca, 'XLimits', [lo hi]),
%   except that it does the right thing if lo > hi.
%
% xlims([lo hi])
%   Same as above.
%
% xlims(vec)
%   This is shorthand for set(gca, 'Xlimits', [min(vec) max(vec)]).
%
% xlims('auto')
%   Set the x-axis limits so the endpoints are nice round numbers.
%   MATLAB does the work.
%
% xlims('manual')
%   Freezes the limits so MATLAB will not change them upon, say, printing.
%
% xlims('fit')
%   Set the x-axis limits so the first and last data points in the plot are
%   at the ends of the displayed range.
%
% xlims('fit+' [,whitespace])
%   Like fit (above), with a margin of extra white space at each end of the 
%   plot.  The fraction of white space is given by whitespace; it defaults 
%   to 0.10.
%
% xlims('mouse')
%   Gets two mouse clicks from the user on the figure and sets the
%   x- and y-limits to the specified rectangle.
%
% xlims('mousex')
%   Gets two mouse clicks from the user on the figure and sets
%   the x-limit, but not the y-limit, to the specified range.
%
% --------------------
%
% xl = xlims(...)
%   All of the above forms return the new x-limits.
%
%
% See also XLIM (MathWorks's version of this), YLIMS, ZLIMS, 
%    SET(gca, ...), GET(gca).

if (nargin == 0)
  % do nothing
elseif (isstr(lo))
  if (strcmp(lo, 'auto') | strcmp(lo, 'manual'))
    set(gca, 'XlimMode', lo);
  elseif (strcmp(lo, 'fit') | strcmp(lo, 'fit+'))   % fit axis limits to data
    m = Inf;
    M = -Inf;
    for ch = get(gca, 'Children').'
      tt = get(ch, 'Type');
      %if (any(strmtch1(tt, 'line','image','patch','surface')))
      if (any(strmtch1(tt, str2mat('line','image','patch','surface'))))
	d = get(ch, 'XData');
	d(isnan(d) | isinf(d)) = [];
	m = min(m, min(min(d)));
	M = max(M, max(max(d)));
      end
    end
    if (strcmp(lo, 'fit+'))
      frac = 0.10;				% default: add 10% extra
      if (nargin > 1) frac = hi; end
      d = (M - m) * frac;			% add frac extra on each end
      M = M + d;
      m = m - d;
    end
    if (m == M), m = m - 1; M = M + 1; end
    if (~isinf(m) & ~isinf(M))
      set(gca, 'XLim', [m M]);
    end
  elseif (strncmp(lo, 'mouse', 5))		% mouse, mousex
    disp('Please mouse-click twice on the figure.')
    [x,y] = ginput(2);
    set(gca, 'XLim', [min(x) max(x)]);
    if (strcmp(lo, 'mouse'))
      set(gca, 'YLim', [min(y) max(y)]);
    end
  else
    error(['Unknown option passed to xlims: ''' lo '''']);
  end
elseif (nargin == 1) 				% 1 numeric arg: vector limits
  if (length(lo) == 2), xlims(lo(1), lo(2));
  else xlims(min(lo), max(lo));
  end
else						% 2 numeric args
  xl = get(gca, 'XLim');
  if (strcmp(get(gca, 'XDir'), 'reverse'))
    xl = fliplr(xl);
  end
  if (isnan(lo)), lo = xl(1); end
  if (isnan(hi)), hi = xl(2); end
  if (lo < hi)
    set(gca, 'XLim', [lo hi], 'XDir', 'normal');
  else
    set(gca, 'XLim', [hi lo], 'XDir', 'reverse')
  end
end

if (nargout > 0 | nargin == 0)
  lims = get(gca, 'XLim');
  if (strcmp(get(gca, 'XDir'), 'reverse'))
    lims = fliplr(lims);
  end
end
