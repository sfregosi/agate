function [x,y] = fitpeaks1(seq, pks, nbd)
%FITPEAKS    Do parabolic fits to points near peaks.
%
% [x,y] = fitpeaks(seq, peakIx)
%    Given a vector seq, fit a quadratic to the curve seq at each of the points
%    seq(peakIx) using the 5 points around each peak, then find the extremum of
%    each quadratic and return it.  peakIx may be a vector or matrix; x and y 
%    are the same shape upon return. This is useful to find the times of peaks
%    more precisely than the sample period.
%
% [x,y] = fitpeaks(seq, peakIx, nbd)
%    As above, but use the given neighborhood size (in samples) for calculating
%    the parabola. The default is 2, meaning to use 5 indices (peak-2 : peak+2).
%
% See also dpeaks.

if (nargin < 3)
  nbd = 2;
end

n = prod(size(pks));
x = zeros(1,n);
y = zeros(1,n);

% Can't vectorize this loop: polyfit can take only one vector at a time.
for i = 1:n
  % Find appropriate indices to fit parabola to.
  ix = [pks(i)-nbd  pks(i)+nbd];
  while (min(ix) < 1)
    if (diff(ix) > 3), ix(1) = ix(1) + 1;
    else ix = ix + 1;
    end
  end
  while (max(ix) > length(seq))
    if (diff(ix) > 3), ix(2) = ix(2) - 1;
    else ix = ix - 1;
    end
  end
  idx = ix(1) : ix(2);

  % Fit it.  Subtract min(idx) so polyfitting is not badly conditioned.
  quadFit = polyfit(idx - min(idx), seq(idx), 2);
  maxIx = roots(polyder(quadFit));	% is empty if quadFit is zeros
  if (isempty(maxIx)), maxIx = pks(i) - min(idx); end
  x(i) = maxIx + min(idx);
  y(i) = polyval(quadFit, maxIx);
end

x = reshape(x, size(pks));
y = reshape(y, size(pks));
