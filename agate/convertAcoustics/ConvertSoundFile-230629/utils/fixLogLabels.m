function fixLogLabels(whichAxis)
%fixLogLabels	change labels on a log plot from '10^n' to be like 10, 100, ...
%
% fixLogLabels(whichAxis)
%   In logarithmic plots, MATLAB labels the tick marks with labels like
%   10^0, 10^1, 10^2, ....  Fix these labels to be like 1, 10, 100, ....
%
%   The input argument 'whichAxis' should be a string specifying which axes
%   to fix: 'X', 'Y', 'Z', 'XY', 'YZ', etc.  If this argument is missing, all
%   logarithmic axes (e.g., with the XScale property of 'log') are fixed.

if (nargin < 1)
  whichAxis = '';
end

% Deal with percentage signs.
pct = any(whichAxis == '%');
whichAxis(whichAxis == '%') = '';

if (isempty(whichAxis))
  if (strcmp(get(gca, 'XScale'), 'log')), whichAxis = [whichAxis 'x']; end
  if (strcmp(get(gca, 'YScale'), 'log')), whichAxis = [whichAxis 'y']; end
  if (strcmp(get(gca, 'ZScale'), 'log')), whichAxis = [whichAxis 'z']; end
  if (isempty(whichAxis))
    return
  end
end

for ch = lower(whichAxis)
  if (~any(ch == 'xyz'))
    error('Unknown axis name ''%s''; should be ''x'', ''y'', or ''z''.', ...
	whichAxis)
  end    
  vals = get(gca, [ch 'Tick']);

  tickLabels = cell(1, length(vals));
  for j = 1 : length(vals)
    tickLabels{j} = sprintf('%g%s', vals(j) * iff(pct, 100, 1), ...
	iff(pct, '%', ''));
  end
  
  set(gca, [ch 'TickLabel'], tickLabels);
end
