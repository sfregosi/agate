function [y0,y1,y2,y3] = wavIn(filename, typ, start, nframe, chans)
%WAVIN   Read a single 'chunk' of a WAV file.
%
% [nchan,sampleSize,sRate,fmt] = wavIn(filename, 'fmt')
%    From the given WAV file, read the WAVE chunk (the main header) and return,
%    respectively, the number of channels (e.g. 2 for stereo), the sample size
%    in bits/sample, the sampling rate (samples/s), and the format (1 means
%    linear [PCM] shorts, 3 means linear [PCM] longs, other values are invalid).
%
%    The file is assumed to have little-endian (PC-style, not Mac/Sun/HP style)
%    numbers.
%
% sams = wavIn(filename, 'data', start, n, chans)
%    From the WAV file, read the sound data chunk and return samples.
%    'start' is the sample number to start reading at (the first sample is 
%    start=0), and n is the number of samples per channel to read.  If n=Inf,
%    read the whole sound.  chans is a vector specifying which channels are
%    desired, with channel 0 being the first channel.  All of the arguments
%    after 'data' are optional; if chans is missing, all channels are 
%    returned.  If the sound is shorter than n samples, then a shortened
%    sams array is returned.
%       The samples are returned in a matrix, with each channel's samples
%    filling one column of the matrix.  The matrix has as many columns
%    as the length of chans.
%       NOTE: The full format of .WAV files is not yet handled.  Only the
%    first data chunk is looked at, and only linear samples (Microsoft
%    PCM format) is processed.  Samples must be no more than 16 bits long.
%
% [sams,left,nBits] = wavIn(filename, 'data' [,start [,n [,chans]]])
%    As above, but also return in 'left' the number of samples per channel
%    left after reading.  You can use wavIn(file, 'data', 0, 0) to get the 
%    number of samples per channel in the file.
%
%    If there is a third return argument, also return the number of bits
%    per sample in 'nBits'.  Negative numbers indicate floating-point formats.
%    (Not sure if this is possible in a WAVE file.)
%
% [sams,left,nBits,dates] = wavIn(filename, 'data' [,start [,n [, chans]]])
%    If the file came from an AURAL M-2 (i.e., it has an MTE1 chunk), then the
%    start- and stop-times of the file are also returned as a 2-element row
%    vector in 'dates'.  These have a precision of 1/100 s, and are encoded
%    as in datenum (q.v.).  For other WAVE files (i.e., most WAVE files in
%    the world), 'dates' is [].
%
% [nChan,nBits,sRate,sampleFormat] = wavIn(filename, 'fmt ')
%    This form of a wavIn call is intended for internal use in this function, 
%    but you can use it too to obtain header information.
%
% bytes = wavIn(filename, other_type)
%    From the WAV file, read a chunk whose type is given by other_type,
%    and return it as a vector of bytes (values 0-255).  The entire chunk 
%    is returned.
%
% [...] = wavIn(fd, ...)
%    The file specifier can also be an open file number as returned by fopen.
%    Upon return, the position in the file is restored to the same place as upon
%    the call to wavIn. Use an fopen call like fopen(filename, 'r', 'l').
%
% See also 
%    soundOut    a general-purpose interface to all the sound output routines
%    soundIn     a general-purpose interface to all the sound input routines
%    binaryIn    for binary headerless (.bNNN) files
%    auIn        for Sun/NeXT format (.au/.snd)  files
%    aiffIn      for AIFF (.aif) files
%    wavread     (MathWorks) similar, but reads the whole file at once
%    fread       (MathWorks) generic file-reading routine
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu

while (length(typ) < 4), typ = [typ ' ']; end			%#ok<AGROW>

if (isnumeric(filename))
  fd = filename;
  fdPlace = ftell(fd);
  fseek(fd, 0, 'bof');
else
  fd = fopen(filename, 'r', 'l'); % WAVE is little-endian (low-order byte first)
  if (fd < 0), error(['File not present: ' filename]); end
end

if (~strcmpi(typ, 'fmt '))
  [nc,ss,~,fmt] = wavIn(fd, 'fmt ');	% work around MATLAB misfeature
end

[x,n] = fread(fd, 12, 'char');
if (n<12 || ~strcmp(char(x(1:4).'), 'RIFF') || ...
      ~strcmp(char(x(9:12).'), 'WAVE'))
  fclose(fd);
  error(['File is not a .WAV file; can''t read it: ', filename]);
end

y3 = extractDatestamp(pathFile(filename));      % get date from filename
if (isnan(y3)), y3 = []; end                    % default value for dates
while (1)
  x = char(fread(fd, 4, 'char').');
  [len,n] = fread(fd, 1, iff(version4, 'long', 'int32'));
  if (n < 1)
    fclose(fd);
    error(['Unexpected end of file while looking for chunk type "' typ ...
	'" in WAV file ' char(filename)]);
  end
  while (length(x) < 4), x = [x ' ']; end			%#ok<AGROW>
  x1 = find(x == 0);
  x(x1) = char(' ' * ones(1, length(x1)));
  if (strcmpi(x, typ))
    break
  elseif (strcmp(x, 'MTE1'))
    % Read the date/time fields for AURAL M-2 WAVE files.  Precision: 1/100 s.
    b = fread(fd, len*2, 'ubit4');		% read BCD nybbles
    c = 10 * b(26:2:56) + b(25:2:55);		% convert BCDs to integers
    y3 = [datenum([c(1)+2000 c(2)  c(3)  c(5)  c(6)   c(7)+c(8)/100]) ...
          datenum([c(9)+2000 c(10) c(11) c(13) c(14) c(15)+c(16)/100])];
  else
    fseek(fd, len, 0);			% skip len bytes
  end
end

% Sometimes the 'len' from a chunk is wrong.  Attempt to fix that.
if (len == 0), len = inf; end
len = min(len, flength(fd) - ftell(fd));

if (strcmpi(typ, 'fmt '))
  % Read header info.
  y3       = fread(fd, 1, 'short');	% fmt
  y0       = fread(fd, 1, 'short');	% nChan
  y2       = fread(fd, 1, iff(version4, 'long', 'int32'));	% sRate
  fseek(fd, 6, 0);			% bytesPerSec (4 bytes), blockAlign (2)
  y1       = fread(fd, 1, 'ushort');	% sampleSize
  
  % Check for WAVEFORMATEXTENSIBLE. The actual sample reading doesn't care that
  % this is WAVEFORMATEXTENSIBLE, so just re-use y3 since the same values (1
  % for SHORT and 3 for FLOAT) apply.
  if (y3 == -2)
    fseek(fd, 8, 'cof');
    y3 = fread(fd, 1, iff(version4, 'long', 'int32'));
  end
  
elseif (strcmpi(typ, 'data'))

  if (fmt ~= 1 && fmt ~= 3 && fmt ~= -2)    % 1 is integer PCM, 3 is float PCM
    error('Unknown .wav file format: %d (I know only PCM formats 1 and 3)', ...
	fmt);
  end

  if (nargin < 3), start  = 0;     end
  if (nargin < 4), nframe = inf;   end
  if (nargin < 5), chans  = 0:nc-1;end

  nbyte = ceil(ss/8);			% bytes/sample

  % Can't use int/uint for the data type because they're always big-endian.
  if     (ss <=  8), dtype = 'uchar';
  elseif (ss <= 16), dtype = 'short';
  elseif (ss <= 24), dtype = 'bit24';
  elseif (ss <= 32), dtype = iff(fmt == 3, 'float', 'long');
  else error('Can''t read samples that are %d bits wide.', ss);
  end

  fseek(fd, nbyte*start*nc, 0);		% skip blockSize ulong, unused bytes
  ntot = len / nc / nbyte - start;	% number left in chunk (samples/chan)
  nleft = min(nframe, ntot);		% number left to read  (ditto); is <=
  					%    than length of file.
  y0 = zeros(nleft, length(chans));	% The Answer
  ix = 0;				% where to put next set of samples
  s = 1;				% dummy value to get loop started
  while (nleft > 0 && ~isempty(s))
    q = min(nleft, round(1048576 / nc));  % read roughly 1MB
    s = fread(fd, q*nc, dtype);
    s = reshape(s, nc, length(s)/nc);
    if (ss <= 8), s = s - 128; end			% fix 1-byte uint samps
    if (nbyte*8 ~= ss), s = s / 2^(nbyte*8 - ss); end	% fix left-aligned bits
    y0(ix+1 : ix+nCols(s), :) = s(chans+1, :).';
    ix = ix + nCols(s);
    nleft = nleft - nCols(s);
    ntot = ntot - nCols(s);
  end
  y1 = ntot;
  y2 = iff(fmt == 1, ss, -ss);		% negative indicates float format

else
  y0 = fread(fd, len, 'uchar');

end

if (isnumeric(filename))
  fseek(fd, fdPlace, 'bof');
else
  fclose(fd);
end
