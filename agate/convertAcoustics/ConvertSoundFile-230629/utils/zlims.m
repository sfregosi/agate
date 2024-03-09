function lims = zlims(lo, hi)
%ZLIMS		set z-limits of the current plot
%
% zlims(lo,hi)
%   This is shorthand for set(gca, 'ZLimits', [lo hi]),
%   except that it does the right thing if lo > hi.
%
% zlims([lo hi])
%   Same as above.
%
% zlims(vec)
%   This is shorthand for set(gca, 'ZLimits', [min(vec) max(vec)]).
%
% zlims('auto')
%   Set the z-axis limits so the endpoints are nice round numbers.
%   MATLAB does the work.
%
% zlims('manual')
%   Freezes the limits so MATLAB will not change them upon, say, printing.
%
% zlims('fit')
%   Set the z-axis limits so the first and last data points in the plot are
%   at the ends of the displayed range.
%
% zlims('fit+' [,whitespace])
%   Like fit (above), with a margin of extra white space at each end of the 
%   plot.  The fraction of white space is given by whitespace; it defaults 
%   to 0.10.
%
% --------------------
%
% zl = zlims(...)
%   All of the above forms return the new z-limits.
%
%
% See also ZLIM (MathWorks's version of this), XLIMS, YLIMS, 
%    SET(gca, ...), GET(gca).
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu
% 9 May 01

if (nargin == 0)
  % do nothing
elseif (isstr(lo))
  if (strcmp(lo, 'auto') | strcmp(lo, 'manual'))
    set(gca, 'ZLimMode', lo);
  elseif (strcmp(lo, 'fit') | strcmp(lo, 'fit+'))   % fit axis limits to data
    m = Inf;
    M = -Inf;
    for ch = get(gca, 'Children').'
      tt = get(ch, 'Type');
      %if (any(strmtch1(tt, 'line','image','patch','surface')))
      if (any(strmtch1(tt, str2mat('line','image','patch','surface'))))
	d = get(ch, 'ZData');
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
      set(gca, 'ZLim', [m M]);
    end
  else
    error(['Unknown option passed to zlims: ''' lo '''']);
  end
elseif (nargin == 1) 				% 1 numeric arg: vector limits
  if (length(lo) == 2), zlims(lo(1), lo(2));
  else zlims(min(lo), max(lo));
  end
else						% 2 numeric args
  zl = get(gca, 'ZLim');
  if (strcmp(get(gca, 'ZDir'), 'reverse'))
    zl = fliplr(zl);
  end
  if (isnan(lo)), lo = zl(1); end
  if (isnan(hi)), hi = zl(2); end
  if (lo < hi)
    set(gca, 'ZLim', [lo hi], 'ZDir', 'normal');
  else
    set(gca, 'ZLim', [hi lo], 'ZDir', 'reverse')
  end
end

if (nargout > 0 | nargin == 0)
  lims = get(gca, 'ZLim');
  if (strcmp(get(gca, 'ZDir'), 'reverse'))
    lims = fliplr(lims);
  end
end
