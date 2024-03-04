function [y,hOffset] = energySum(spect, sRate, fRate, timeSpread, freqs)
% [y,hOffset] = energySum(spect, sRate, fRate, timeSpread, freqs)
%    Sum the numbers in a given frequency range in a spectrogram. 'freqs' is a
%    two-element vector with the low and high frequencies, in hertz, to sum
%    over. The spectrogram 'spect' is assumed to go from 0 to just below the
%    Nyquist frequency, and fRate specifies its frame rate. timeSpread is how
%    many seconds to average over for each output value (default is 1 s), and
%    freqs specifies the frequency range.  If freqs is missing or [], the whole
%    frequency range is used; if timeSpread is 0, no time-averaging is done.
%    The return value y is a row vector.
%   
%    If spect is 3-D, with spectrograms stacked up in Z-planes, do the sum in
%    each spectrogram independently.  y is then a 3-dimensional array, 1xNxZ.
%
%    If freqs has 4 elements (2 pairs of frequencies), use the second pair as a
%    frequency range to subtract from the principal sum.  (The spectrogram is
%    assumed to have log-scaled values, so this subtraction corresponds to
%    division of pressure or power values.) This can be used to eliminate
%    earthquakes.
%   
%    The second return argument hOffset is the "filter warmup time" -- the
%    offset, in seconds, of the start of the result y from the actual start of
%    the sound.

if (nargin < 3), timeSpread = 1; end
if (nargin < 4), freqs = []; end
if (isempty(freqs)), freqs = [0 sRate/2]; end

% Pick out the frequency range of spect to use.
fftSize = nRows(spect) * 2;
binBW	= sRate / fftSize;
fbin	= round(freqs / binBW) + 1;	% add 1 for MATLAB indexing
range   = max(1, fbin(1)) : min(fftSize/2, fbin(2));

% Do the 'energy' sum.
s = sum(spect(range, :, :), 1) / length(range);

% Divide by another freq range, if specified.
if (length(fbin) > 2)
  sRange = max(fbin(3),2) : min(fbin(4), fftSize / 2);
  sb = sum(spect(sRange,:, :)) / length(sRange);
  s = s - sb;				% subtraction in log space is division
end

% Sum adjacent elements. This is distinct from the smoothing done in execute.m.
n = round(timeSpread * fRate);
if (n > 1)		% don't bother if smoothing range <= 1 sample
  if (~ismatrix(s)), error('N-dim spectrograms cannot be smoothed yet.'); end
  y = corr(ones(1, n) / n, s);		% average over n elements
  y0 = max(1,floor(n/2));
  y = y(y0 : y0+length(s)-1);		% correct for hOffset
else
  y = s;
end

hOffset = 0;
