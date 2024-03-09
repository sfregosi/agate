function [y0,y1,y2,y3] = aiffIn(filename, typ, start, nframe, chans)
%AIFFIN         Read an Audio Interchange File Format sound file.
%
% [nchan,nframe,sampleSize,sRate] = aiffIn(filename, 'COMM')
%    From the given AIFF file, read the Common Chunk in the file header 
%    and return, respectively, the number of channels (e.g. 2 for stereo), 
%    the number of sample frames (i.e. number of samples in each channel), 
%    the sampleSize in bits, and the sampling rate.
%
% sams = aiffIn(filename, 'SSND', start, n, chans)
%    From the AIFF file, read the Sound Data Chunk and return samples.
%    'start' is the sample number to start reading at (the first sample is 
%    start=0), and n is the number of samples per channel to read.  If n=Inf,
%    read the whole sound.  chans is a vector specifying which channels are
%    desired, with channel 0 being the first channel.  All of the arguments
%    after 'SSND' are optional; if chans is missing, all channels are 
%    returned as separate columns.
%       The samples are returned in a matrix, with each channel's samples
%    filling one column of the matrix.  The matrix has as many columns
%    as the length of chans.
%
% bytes = aiffIn(filename, other_type)
%    From the AIFF file, read a chunk whose type is given by other_type,
%    and return it as a vector of bytes (values 0-255).  The entire chunk 
%    is returned.
%
% See also 
%    soundOut    a general-purpose interface to all the sound output routines
%    soundIn     a general-purpose interface to all the sound input routines
%    wavIn       for WAVE-format (.wav) files
%    binaryIn    for binary headerless (.bNNN) files
%    auIn        for Sun/NeXT format (.au/.snd)  files
%    fread       (MathWorks) generic file-reading routine
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu

if (nargin < 2), typ = 'SSND'; end

if (~strcmp(typ, 'COMM'))
  [nc,nf,ss] = aiffIn(filename, 'COMM');% work around MATLAB misfeature
end

fd = fopen(filename, 'r', 'b');    % AIFF is big-endian (high-order byte first)
if (fd < 0), error(['File not present: ', filename]); end
[x,n] = fread(fd, 12, 'char');
x = setstr(min(255, max(0, x)));
if (n<12 | ~strcmp(x(1:4).', 'FORM') | ~strcmp(x(9:12).', 'AIFF'))
  fclose(fd);
  error(['File is not an AIFF file; can''t read it: ', filename]);
end

cont = 1;
while(cont)
  x = setstr(fread(fd, 4, 'char').');
  [len,n] = fread(fd, 1, iff(version4, 'long', 'uint32'));
  if (n < 1)
    fclose(fd); error(['Unexpected end of file while reading ', filename]);
  end
  if (strcmp(x, typ))
    cont = 0;
  else
    fseek(fd, len, 0);                  % skip len bytes
  end
end

if (strcmp(typ, 'COMM'))
  y0       = fread(fd, 1, 'uint16');    % nChan
  y1       = fread(fd, 1, iff(version4, 'long', 'uint32'));     % nFrame
  y2       = fread(fd, 1, 'uint16');    % sampleSize
  exp      = fread(fd, 1, 'uint16');    % read a 10-byte float
  [mant,n] = fread(fd, 2, iff(version4, 'ulong', 'uint32'));
  if (n < 1), 
    fclose(fd); error(['Unexpected end of file when reading ', filename]);
  end
  mant = mant(1) / 2^31 + mant(2) / 2^63;
  if (exp >= 32768), mant = -mant; exp = exp - 32768; end
  exp = exp - 16383;
  y3 = mant * 2^exp;                    % sRate
  
elseif (strcmp(typ,'SSND'))
  if (nargin < 3), start  = 0;     end
  if (nargin < 4), nframe = nf;    end
  if (nargin < 5), chans  = 0:nc-1;end
  if (nframe == Inf), nframe = nf; end
  off = fread(fd, 1, iff(version4, 'long', 'uint32'));  % offset
  nbyte = ceil(ss/8);
  dtype = iff(version4 & nbyte==4, 'long', ['int' num2str(nbyte*8)]);
  fseek(fd, 4+off + nbyte*start*nc, 0); % skip blockSize uint32, unused bytes
  y0 = [];
  while (nframe > 0)
    q = min(nframe, round(1048576 / nc));       % read roughly 1M at once
    [s,n] = fread(fd, q*nc, dtype);             % s is 1-col interleaved vector
    if (n < q*nc)
      fclose(fd); error(['Unexpected end of file when reading ', filename]); 
    end
    s = reshape(s, nc, length(s)/nc);           % make into rows, one per chan
    if (nbyte*8 ~= ss), s = s / 2^(nbyte*8 - ss); end   % fix left-aligned bits
    y0 = [y0; s(chans + 1, :).'];               % columns
    nframe = nframe - q;
  end

else
  y0 = fread(fd, len, 'uchar');

end

fclose(fd);
