function [result,fRate,gramParams] = ...
  davespect(seq, frameSize, nOverlap, zeroPad, windowFn, sRate)
%DAVESPECT    Compute the short-time periodic windowed FFT of a signal.
%
% gram = davespect(signal,frameSize,[nOverlap[,zeroPad[,windowFn[,sRate]]]])
%    When signal is a row or column vector: For each frame, window it 
%    with a Hanning window of length frameSize, compute the FFT, remove
%    the negative frequencies, and take log(abs()) of the resulting
%    elements.  Then hop ahead by (frameSize - nOverlap) elements to
%    the next frame. nOverlap defaults to frameSize/2.
%
%    When signal is a matrix: Do the above operation on each column.
%    (The degenerate case of a 1xN 'matrix' is of course a vector, and
%    there is no way here to do the FFT on each column of it.)
%    The result is a 3-D array, with result(:,:,N) being the spectrogram
%    for the Nth column of the input.
%
%    If the zeroPad argument is supplied, that many zeros are appended
%    to the frame before computing the FFT.  zeroPad+frameSize should be
%    a power of two.
%
%    If a windowFn string is supplied, then that windowing function is
%    used instead of the default 'hanning'.
%   
%    The resulting array has (frameSize+zeroPad)/2 rows and
%    a number of columns determined by the framesize and overlap values
%    and the signal length.  Low frequencies in the result come first,
%    i.e., they have low row indices.
%   
%    If the input sound ever has a long sequence of zeros, then the FFT
%    output has zeros.  The gram returned will contain -Inf values, as it's
%    logarithmic.
%
% gram = davespect(signal, gramParams, sRate)
%    Spectrogram parameters are specified in a structure with these fields:
%	frameSizeS	frame size, in seconds
%	overlapFrac	[optional] e.g., 0.5 or 0.25; default is 0.5
%	zeroPadFrac	[optional] e.g., 0, 1, 3, or 7; default is 0
%	window		[optional] e.g., 'hamming'; default is hanning
%
% [gram,fRate] = davespect ( ... )
%    The second output argument 'fRate' is the frame rate, i.e., the number of
%    time-slices (columns) per second in the returned spectrogram.  In order to
%    calculate fRate, the sRate parameter must be one of the input arguments.
%
% [gram,fRate,gramParams] = davespect(signal, gramParams, sRate)
%    A third return argument is the gramParams structure with fields in units
%    of samples, including frameSize, nOverlap, and zeroPad.  All of these are
%    integers.  Also included is the field windowFn, which is a string.
%
% This function used to be called 'spectrogram', but Matlab's signal processing
% toolbox started using that name sometime around 2006 and I had to switch to
% davespect to avoid the name collision.
%
% See also parseGramParams, specgram, spectrogram.
%
% Dave Mellinger
% David.Mellinger, oregonstate.edu

hanning(1);

% Parse args.
if (isstruct(frameSize))
  % 'frameSize' arg is really this struct, 'nOverlap' is really sRate.
  gramParams = frameSize;	% rename the arg
  sRate = nOverlap;		% rename the arg
  [frameSize,nOverlap,zeroPad,windowFn] = parseGramParams(gramParams, sRate);
else
  if (nargin < 3), nOverlap = frameSize/2;	end
  if (nargin < 4), zeroPad  = 0; 		end
  if (nargin < 5), windowFn = 'hanning';	end
end

% Put integer values back into gramParams.  This works even if gramParams
% doesn't exist yet.
gramParams.frameSize = frameSize;
gramParams.nOverlap  = nOverlap;
gramParams.zeroPad   = zeroPad;
gramParams.windowFn  = windowFn;

if (size(seq,1) == 1), seq = seq(:); end	% make column vector

[inrows, incols] = size(seq);
nfft    = frameSize + zeroPad;
seqsize = inrows;
outcols = 1 + floor((seqsize - frameSize) / (frameSize - nOverlap));
outrows = nfft / 2;
window  = repmat(feval(windowFn, frameSize), 1, incols);  % column vector(s)
outpos  = 1:outrows;

result  = zeros(outrows, outcols, incols);

wstate = warning('off', 'MATLAB:log:logOfZero');% disable warning message
for i = 1:outcols
  start = 1 + (frameSize - nOverlap) * (i - 1);
  frame = seq(start:(start + frameSize - 1), :);	   % column vector(s)
  %frame = frame - repmat(mean(frame,1), nRows(frame), 1); % subtract mean
  spectrum = fft(frame .* window, nfft);		   % column vector(s)
  result(:,i,:) = log(abs(spectrum(outpos,:)));
end
warning(wstate);		% restore warning message

if (exist('sRate', 'var'))
  fRate = sRate / (frameSize - nOverlap);
end
