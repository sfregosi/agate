function [peakIx,pkSpan,train] = dpeaks(x, nbd, thresh, durLims)
%DPEAKS		Return the peak values in a sequence
%
% peakIx = dpeaks(seq, nbd)
%    Finds all the peaks in vector seq that are local maxima and at least as
%    high as any other point within nbd elements.  If nbd is 0, returns the
%    maxima in seq.  Returns a column vector of indices into seq. If a peak is
%    broad (i.e., several successive values in seq are the same), uses the
%    lowest index of the several possible.  As a special case, if nbd < 0, just
%    returns the whole array.
%
% peakIx = dpeaks(seq, nbd, thresh)
%    As above, but a peak must additionally be at least as big as thresh.
%
% peakIx = dpeaks(seq, nbd, thresh, durLims)
%    As above, but additionally seq must be over thresh for a duration at least
%    as long as durLims(1). If durLims has two elements, then seq must also be
%    over threshold no longer than durLims(2). Like nbd, values in durLims are
%    measured in samples. durLims defaults to [0 inf].
%
% [peakIx,pkSpan] = dpeaks( ... )
%    As above, but also return the start/stop indices of each detection -- the
%    indices from when seq was last below threshold before the peak, and when
%    seq went back below after the peak. 'pkSpan' is a 2xN array with one row
%    for each element of peakIx.
%
% [peakIx,pkSpan,train] = dpeaks( ... )
%    Also return a "peak train" the same length as seq which has a
%    single-sample-wide spike where each peak occurs and zeroes elsewhere.
%    'train' is a column vector.
%
% See also fitpeaks.
%
% Dave Mellinger

if (nargin < 4), durLims = [0 inf]; end
if (length(durLims) == 1), durLims = [durLims inf]; end

x = x(:);
n = length(x);
if (nbd < 0 || n < 2)
  peakIx = 1:length(x);
else
  % endpoints can be peaks too
  if (all(x(1) >= x)), p0 = x(1) > x(n);	% all are equal
  else                 p0 = x(1) > x(2);
  end
  p1 = (x(n-1) < x(n));
  
  % p is the initial guess at the peak locations
  p = find([p0; (x(1:n-2) < x(2:n-1)) & (x(2:n-1) >= x(3:n)); p1]);
  if (nargin > 2), p = p(x(p) >= thresh); end	% detect.m also uses >=
  
  % Now test points in p for being greater than neighbors.
  v = x(p);
  peakIx = zeros(length(p), 1);
  k = 0;
  for i = 1:length(p)
    if (v(i) >= x(max(1,p(i)-nbd) : min(n,p(i)+nbd)))
      k = k + 1;
      peakIx(k) = p(i);
    end
  end
  peakIx = peakIx(1:k);
end

pkSpan = NaN;		% in case we need argout #2 but don't have thresh
if (nargin >= 3)
  % Get ixLess = indices of seq below threshold (plus guard 1's at ends)
  ixLess = [1; (x < thresh); 1];	% indices of values below thresh
  pkSpan = zeros(length(peakIx), 2);
  for i = 1 : length(peakIx)
    ix0 = find(ixLess(          1 : peakIx(i)), 1, 'last') - 1;
    ix1 = find(ixLess(peakIx(i)+2 : end      ), 1, 'first') + peakIx(i);
    pkSpan(i,:) = [ix0 ix1];
  end
  ixKeep = (durLims(1) < diff(pkSpan,1,2)) & (diff(pkSpan,1,2) < durLims(2));
  peakIx = peakIx(ixKeep);
  pkSpan = pkSpan(ixKeep, :);
end

if (nargout >= 3)
  train = zeros(n, 1);
  train(peakIx) = x(peakIx);
end
