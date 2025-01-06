function [sams,nChans,bytesPerSample,sRate,nLeft] = ...
    mp3In(filename, start, nFrame, chans)
%MP3IN           Read an MP3 format (.mp3) sound file.
%
% [sams,nChans,bytesPerSample,sRate,nLeft] = mp3In(filename)
%    From the given MP3 file, read the file and return, respectively,
%    all the samples in it, the number of channels (e.g. 2 for stereo), 
%    the sample size in bytes, the sampling rate per channel in samples/s,
%    and the number of sample frames remaining after your read (one sample
%    frame equals one sample on all the channels).
%       The samples are returned in a matrix that has the data from
%    each channel filling one column.
%
% ... = mp3In(filename, start, n, chans)
%    You can also read only part of the file.  'start' is the sample
%    number to start reading at; the first sample is start=0, which
%    is the default.  'n' is the number of samples per channel to read.
%    If n=Inf (the default), read the whole sound.  'chans' is a vector
%    specifying which channels are desired, with channel 0 being the
%    first channel.  chans defaults to [0 : nChans-1] if it's absent, 
%    empty, or NaN.
%
%    start and n may both be 0.  In this case, you get back nChans, 
%    nLeft, etc. without actually reading any samples.
%
% This routine is essentially just a translator to convert arguments
% and call mp3read.m.
%
% See also
%    mp3read     (Dan Ellis) like this rountine, but w/args similar to wavread
%    soundOut    a general-purpose interface to all the sound output routines
%    soundIn     a general-purpose interface to all the sound input routines
%    wavIn	 for WAVE-format (.wav) files
%    binaryIn    for binary headerless (.bNNN) files
%    aiffIn      for AIFF (.aif) files
%    fread       (MathWorks) generic file-reading routine
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu

if (exist('mp3read.m', 'file') ~= 2)
  error(['I need to have the mp3read.m utility in MATLAB''s path.' 10 'See http://labrosa.ee.columbia.edu/matlab/mp3read.html .'])
end

% Read file info and set defaults if needed.
siz = mp3read(filename, 'size');	% [samples channels]
nSams  = siz(1);
nChans = siz(2);

if (nargin < 2), start  = 0; end
if (nargin < 3 || isinf(nFrame)), nFrame = nSams - start; end
if (nargin < 4 || any(isnan(chans)) || isempty(chans)), chans  = 0 : nChans-1; end

% The max(1,...) is here because mp3read reads the whole file if sam1 < sam0.
% Also note that mp3read uses 1-based indexing while I use 0-based.
[sams,sRate,bitsPerSample] = mp3read(filename, [start+1 start+max(1,nFrame)]);
if (nFrame <= 0), sams = zeros(0,length(chans)); end
bytesPerSample = ceil(bitsPerSample / 8);
nLeft = nSams - (start + nFrame);

sams = sams(:,chans+1);
