function y = linspace(x1, x2, n)
%LINSPACE1	Linearly spaced vector that omits the final point.
%
% y = linspace1(x1, x2)
%   Return a row vector of 100 linearly spaced points starting with x1 and 
%   ending just before x2.  The 101st point in this series would be x2.
%
% y = linspace1(x1, x2, n)
%   Return a vector with n points instead of 100.
%
% Examples:
%   linspace1(10, 20, 5)  returns  [10 12 14 16 18].
%
%   This function is useful for determining the frequencies of an N-point FFT.
%   If FS is the sampling rate, then the frequencies of the first N/2 points
%   returned by fft() -- that is, the positive frequencies -- are just
%                     linspace1(0, FS/2, N)
%
% See also linspace, logspace, :.

if (nargin < 3)
  n = 100;
end

y = (0 : n-1) * ((x2 - x1) / n) + x1;
