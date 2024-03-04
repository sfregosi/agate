function [sams,nChans,bytesPerSample,sRate,nLeft] = ...
    auIn(filename, start, nFrame, chans)
%AUIN           Read a Sun/NeXT-format (.au or .snd) sound file.
%
% [sams,nChans,bytesPerSample,sRate,nLeft] = auIn(filename)
%    From the given AU file, read the file and return, respectively,
%    all the samples in it, the number of channels (e.g. 2 for stereo), 
%    the sample size in bytes, the sampling rate per channel in samples/s,
%    and the number of sample frames remaining after your read (one sample
%    frame equals one sample on all the channels).
%       The samples are returned in a matrix that has the data from
%    each channel filling one column.
%
% ... = auIn(filename, start, n, chans)
%    You can also read only part of the file.  'start' is the sample
%    number to start reading at; the first sample is start=0, which
%    is the default.  'n' is the number of samples per channel to read.
%    If n=Inf (the default), read the whole sound.  'chans' is a vector
%    specifying which channels are desired, with channel 0 being the
%    first channel.  chans defaults to [0 : nChans-1].
%
%    start and n may both be 0.  In this case, you get back nChans, 
%    nLeft, etc. without actually reading any samples.
%
% See also
%    soundOut    a general-purpose interface to all the sound output routines
%    soundIn     a general-purpose interface to all the sound input routines
%    wavIn	 for WAVE-format (.wav) files
%    binaryIn    for binary headerless (.bNNN) files
%    aiffIn      for AIFF (.aif) files
%    auread      (MathWorks) similar, but reads the whole file at once
%    fread       (MathWorks) generic file-reading routine
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu

if (nargin < 2), start = 0;    end
if (nargin < 3), nFrame = Inf; end

fd = fopen(filename, 'r', 'b');    % .au is big-endian (high-order byte first)
if (fd < 0), error(['File not present: ' filename]); end

% Read file header.
x = setstr(fread(fd, 4, 'char').');
if (~strcmp(x, '.snd'))
  fclose(fd);
  error(['File is not an AU file; can''t read it: ' filename]);
end
offset   = fread(fd, 1, 'int32');  % where in the file the data starts
nBytes   = fread(fd, 1, 'int32');  % is ignored; see below
format   = fread(fd, 1, 'int32');
sRate    = fread(fd, 1, 'int32');
nChans   = fread(fd, 1, 'int32');

if (nargin < 4), chans = 0 : nChans-1; end

mu = 0;               % mulaw encoding?  mu may get changed in the switch()
if (format==1), bytesPerSample = 1; numfmt = 'uchar'; mu=1; end; % 8-bit mulaw
if (format==2), bytesPerSample = 1; numfmt = 'char';        end; % 8-bit linear
if (format==3), bytesPerSample = 2; numfmt = 'int16';       end; %16-bit linear
if (format==4), bytesPerSample = 3; numfmt = 'int24';       end; %24-bit linear
if (format==5), bytesPerSample = 4; numfmt = 'int32';       end; %32-bit linear
if (format==6), bytesPerSample = 4; numfmt = 'float32';     end; %32-bit float
if (format==7), bytesPerSample = 8; numfmt = 'float64';     end; %64-bit float
if (format < 1 | format > 7)
  error(['Unknown .au/.snd file encoding ' num2str(format) ' in ' filename]);
end

% Determine number of bytes from file length.  The header's nBytes field is
% ignored, since some files have it wrong.
fseek(fd, 0, 'eof');
nBytes       = ftell(fd) - offset;
nFramesTotal = floor(nBytes / nChans / bytesPerSample);
nFrame       = min(nFramesTotal - start, nFrame);
nSamsToRead  = nFrame * nChans;

% Read the samples.
fseek(fd, offset + start * bytesPerSample * nChans, 'bof');
sams = fread(fd, nSamsToRead, numfmt);
fclose(fd);

if (mu)
  sams = mu2lin(sams) * 65536;
  %sams = mu2lin(sams);
end

% Make the samples into the correct set of columns.
sams = reshape(sams, nChans, nFrame).';  % handle de-interleaving
sams = sams(:, chans+1);                 % pick desired set of channels
nLeft = nFramesTotal - nFrame;
