function [nFrameSize,nOverlap,nZeroPad,windowFn,fRate,binBW] = ...
    parseGramParams(p, arg2)
%parseGramParams	parse a gramParams structure
%
% [nFrameSize,nOverlap,nZeroPad,windowFn,fRate,binBW] = parseGramParams(p, filename)
% ... or ...
% [nFrameSize,nOverlap,nZeroPad,windowFn,fRate,binBW] = parseGramParams(p, sRate)
% ... or ...
% newGramParams = parseGramParams( ... )
%   Unpack a gramParams structure into individual variables.  The structure
%   has these fields:
%
%     frameSizeS	[required] amt of data used for each spectrogram frame,
%			    in seconds
%     overlapFrac	[optional] overlap in the frames between adjacent
%			    spectrogram frames; default is 0.5
%     zeroPadFrac	[optional] amount of zero-padding to do to the data
%			    samples before each FFT; default is 0.0
%     windowFn		[optional] window type; default is 'hanning'
%
% If there is a single return argument, then a new gramParams is returned with
% each of these values in a field. If there is more than one return argument,
% then the values are returned as separate, individual scalars.
%
% See also davespect, tonalFixParams.

if (ischar(arg2))
  % User specified a sound file name for 'sRate'. Get sample rate from file.
  [~,sRate] = soundIn(arg2, 0, 0);
else
  % User specified a sample rate.
  sRate = arg2;
end

nFrameSize = 2^round(log2(p.frameSizeS * sRate));
p.nFrameSize = nFrameSize;

nOverlap = nFrameSize * 0.5;
if (isfield(p, 'overlapFrac')), nOverlap = round(nFrameSize*p.overlapFrac); end
p.nOverlap = nOverlap;

nZeroPad = 0;
if (isfield(p, 'zeroPadFrac')), nZeroPad = round(nFrameSize*p.zeroPadFrac); end
p.nZeroPad = nZeroPad;

windowFn = 'hanning';
if (isfield(p, 'windowFn')), windowFn = p.windowFn; end
p.windowFn = windowFn;

fRate = sRate / (nFrameSize - nOverlap);
p.fRate = fRate;
binBW = sRate / (nFrameSize + nZeroPad);
p.binBW = binBW;

if (nargout == 1)
  nFrameSize = p;
end
