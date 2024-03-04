function y = corr(x1,x2,f,donorm)
%CORR    Compute correlations faster than DSP toolbox, and with bandpassing
%
% y = corr(x)
%    Compute the autocorrelation of vector x.  Does NOT handle matrices the way
%    xcorr (in the Signal Processing toolbox) does; instead, a matrix is
%    treated as columns of vectors.  If x is a vector of length N, then length
%    of the result y is N*2-1, and the zeroth lag is at y(N). If x is a matrix
%    with N rows, then the result has 2*N-1 rows, with the zeroth lag for each
%    column at y(N,:).
%
% y = corr(x1,x2)
%    Return the cross-correlation of vectors x1 and x2, which need not be the
%    same length.  This is similar to xcorr, but faster (xcorr efficiently
%    computes 3 correlations and throws 2 away).  Also, if the lengths of x1
%    and x2 are different, corr returns a correct-length result, unlike xcorr.
%    The length of the result is length(x1)+length(x2)-1.
%
% y = corr(x1,x2,f)
%    As above, but also filters by the bandpass filter f.  f is a two-element
%    vector, with values in [0,1], that specifies the passband; in f, 0
%    represents 0 Hz and 1 represents the Nyquist frequency.  Filtering is done
%    by the FFT + zeroing out + IFFT process; since the FFT and IFFT are
%    computed by the correlation algorithm anyway, the computational cost of
%    filtering is negligible. If f is empty, filtering is skipped.
%
% y = corr(x1,x2,f,donorm)
%    If donorm is non-zero, the return vector (or vectors, if x is a matrix) is
%    normalized to have a length of 1.
%
% The sign convention: if x1 and x2 are two vectors such that x2 is a delayed
% version of x1, then the peak in corr(x1,x2) is AFTER the midpoint (the 
% delay=0 point).  This sign convention is the same as xcorr's but opposite
% of Canary's.
%
% See also xcorr, cov, conv.
%
% 2/94 David K. Mellinger  David.Mellinger@oregonstate.edu

% First make sure x1,x2 are column vectors.  Also handle autocorrelation case.
rowvec = (size(x1,1) == 1);
if (rowvec), x1 = permute(x1, [2 1 3:ndims(x1)]); end
if (nargin < 2)
  x2 = x1;
else
  if (size(x2,1) == 1), x2 = permute(x2, [2 1 3:ndims(x2)]); end
end
if (nargin < 4), donorm = false; end

% Pad with 0's for fft & circular corr.
n1 = nRows(x1);
n2 = nRows(x2);
%nfft = 2 * 2^nextpow2(max(n1,n2));
nfft = 2^nextpow2(n1 + n2);

% Do correlation by fft-conj-dotmul-ifft method.  fft operates column-wise. The
% ifft is done below.
sz1 = size(x1); sz2 = size(x2);
y = conj(fft([x1; zeros([nfft-n1 sz1(2:end)])])) ...      % conj x1
  .*     fft([x2; zeros([nfft-n2 sz2(2:end)])]);          % ...but not x2

% Filter.
if (nargin > 2 && ~isempty(f))
  % Filter.
  if (length(f) == 1), f = [0 f]; end	% one number means lowpass filter
  n = nfft/2;
  i0 = round(f(1) * n);
  i1 = round(f(2) * n);
  y(   1 : i0, :) = 0;
  y(i1+1 : n, :)  = 0;
  y(nfft+1-i0 : nfft, :)    = 0;
  y(nfft+1-n  : nfft-i1, :) = 0;
end

y = ifft(y);                                 % ifft operates column-wise too
szY = size(y);
y = reshape([y(nfft+2-n1:nfft, :); y(1:n2, :)], [n1+n2-1 szY(2:end)]);
if (donorm)
  y = y ./ repmat(sqrt(sum(y.^2, 1)), nRows(y), 1);
end

% Make output have same form as input.
if (all(isreal(x1)) && all(isreal(x2)))
  y = real(y);				% remove small imaginary part
end
if (rowvec)
  y = permute(y, [2 1 3:ndims(y)]); 
end
