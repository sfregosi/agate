function [sams,nChans,bytesPerSample,sRate,nLeft,dt] = ...
                                         psmIn(filename, start, nFrame, chans)
%PSMIN           Read a Pioneer-Seamount-format (PSM) sound file.
%
% [sams,nChans,bytesPerSample,sRate,nLeft,dt] = psmIn(filename)
%    From the given Pioneer Seamount format file, read the file and return,
%    respectively, all the samples in it, the number of channels (normally
%    4), the sample size in bytes, the sampling rate per channel in 
%    samples/s, the number of sample frames remaining in the 
%    file after your read (one sample frame equals one sample on all the
%    channels), and the date.
%       The samples are returned in a matrix that has the data from
%    each channel filling one column.  The date is encoded as by haruIn, 
%    i.e., as a vector
%                  [year-1900  yearday  hour  min  sec  msec]
%
%       Pioneer Seamount files should have names encoding their date/time
%    of creation.  For example, in 'r0126914.02m', the 'r' is always there, 
%    '01' indicates the year (2001), '269' is the year day, '14' is the 
%    hour of the day, and '02' is the minute.  The 'm' is also always 
%    there.  THIS ROUTINE USES THE FILE NAME TO DERIVE THE YEAR for 'dt', 
%    since the year is not encoded within the file itself.  dt is encoded
%    as in datenum (q.v.).
%       Pioneer Seamount data and tphase data are stored in the same format.
%
% ... = psmIn(filename, start, n, chans)
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
%    auIn	 for NeXT/Sun format (.snd/.au) files
%    fread       (MathWorks) generic file-reading routine
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu

% Test: sams = psmIn('\\back40\hdd1\Pioneer\r0124423.58m00', 0, 20);
% Test: osprey C:\Dave\sounds\PioneerSeamount\r0124413.43m00

% psmParam is a structure specifying the data layout of psm/SOSUS files.
% psmParam.endian is 'B' big-endian (Sun/Mac/tphase) data or 'L' for
%     little-endian (Intel/Windows/Pioneer Seamount) data.
% psmParam.byteResol is a vector specifying the number of bytes per sample
%     for successive channels of data in the file.  Each number in this vector
%     must be 1 or 2, and the length of the vector is the number of channels of
%     data in the file.
% psmParam.fpb is the number of data frames per block, which is different
%     for Pioneer and tphase data.
%
% NOTE: SLN made edits because we found that SOSUS data had 6 different formats
% (sample rate, endian etc. has changed a lot over the years. See
% SOSUS_dataformathistory.txt

global psmParam psmParamAll
while (~gexist4('psmParam'))
  printf
  printf('Are these recordings from')
  printf('   (1) Pioneer Seamount,')
  printf('   (2) 1991 Whidbey Island (250 Hz, 16 channel, little endian),')
  printf('   (3) 1991 Whidbey Island (128 Hz, 16 channel, little endian),')
  printf('   (4) 1992 day 100 - 1995 day 142 Whidbey Island (128 Hz, 16 channel, big endian),')
  printf('   (5) 1995 day 143 - 2000 day 285 Whidbey Island (128 Hz, 32 channel, big endian),')
  printf('   (6) 2000 day 286 - 2003 day 308 Whidbey Island (250 Hz, 64 channel, big endian),')
  printf('or (7) 2003 day 309 - present Whidbey Island (250 Hz, 64 channel, little endian)?')
  x = input('Please enter a number: ');

   psmParamAll = struct(...
      'fpb',         {4096   1024   1024   1024   512  256  256   }, ...
      'endian',      {'L'    'L'    'L'    'B'    'B'  'B'  'L'   }, ...
      'sRate',       {1000   250    128    128    128  250  250   }, ...
      'byteResol',   {[2 2 2 2]
                      [ones(1,6) 2*ones(1,10)]
                      [ones(1,6) 2*ones(1,10)]
                      [ones(1,6) 2*ones(1,10)]
		      [2*ones(1,32)]
		      [2*ones(1,64)]
                      [2*ones(1,64)]
                      }.');
  psmParam = psmParamAll(x);
    
  printf
  printf('If you need to change your answer to this question, type')
  printf('''clear global psmParam'' at the command prompt and I''ll ask')
  printf('the question again.')
  printf
end

sRate = psmParam.sRate;
nChans = length(psmParam.byteResol);

if (nargin < 2), start  = 0;   end
if (nargin < 3), nFrame = inf; end
if (nargin < 4), chans  = NaN; end
if (isnan(chans)), chans  = 0 : nChans-1; end

fd = fopen(filename, 'r', psmParam.endian);   % read-only
if (fd < 0)
  error(['Can''t open PSM-format file ' filename]);
end

framesPerBlock = psmParam.fpb;     % the same (?) for all blocks
headerBytes = 18;                  % the same (?) for all blocks

% Read header, set date.  USES THE FILENAME TO GET THE YEAR!
str = setstr(fread(fd, 18, 'char').');
[dtnums,cnt] = sscanf(str, '%d:%d:%d:%d.%d');
if (cnt < 4)
  error(['Can''t read PSM file; first block in file ' filename ...
	  ' does not have date/time stamp.']);
end
f = pathRoot(pathFile(filename));
yr = str2num(f(2 : end-5));    % works for both r9936423.59m and p199906423.59m
yr = mod(yr - 90, 100) + 90;   % works for years 1990-2090
dv = [yr dtnums.'];
dt = datenum([dv(1)+1900 1 dv(2) dv(3) dv(4) dv(5)+dv(6)/1000]);

bytesPerFrame = sum(psmParam.byteResol);
dataBytesPerBlock = bytesPerFrame * framesPerBlock;
bytesPerBlock = headerBytes + dataBytesPerBlock; % may be wrong for last block?

nBytes      = flength(fd);
nBlocks     = floor(nBytes / bytesPerBlock);
nDataBytes  = (nBlocks-1) * dataBytesPerBlock + ...
                           (nBytes - (nBlocks-1)*bytesPerBlock - headerBytes);
nFrameAvail = nBlocks * framesPerBlock;
nFrame      = min(start + nFrame, nFrameAvail) - start;
nLeft       = nFrameAvail - (start + nFrame);

% Advance to the point where reading starts.
startBlock = floor(start / framesPerBlock);
startFrame = start - startBlock * framesPerBlock;
fseek(fd, startBlock * bytesPerBlock + headerBytes + ...
    startFrame * bytesPerFrame, 'bof');

sams = zeros(nFrame, length(chans));
pos = 1;
nf = nFrame;		% number of frames left to read
while (nf > 0)
  n = min(nf, framesPerBlock - startFrame);   % # frames to read this time
  [s,nread] = fread(fd, n * bytesPerFrame, 'int8');
  if (nread < n * bytesPerFrame)
    error(['Unexpected end of file in ' filename ' .']);
  end
  s = reshape(s, bytesPerFrame, n).';
  for ch = 1 : length(chans)
    off = sum(psmParam.byteResol(1 : chans(ch))) + 1;
    if (psmParam.byteResol(chans(ch)+1) == 1)
      sams(pos : pos + n - 1, ch) = s(:, off);
    else
      if (lower(psmParam.endian) == 'l')
        sams(pos : pos + n - 1, ch) = mod(s(:, off), 256) + s(:,off+1)*256;
      else
        sams(pos : pos + n - 1, ch) = s(:, off)*256 + mod(s(:,off+1), 256);
      end
    end
  end
  nf = nf - n;
  pos = pos + n;
  startFrame = 0;             % start reading at beginning of next block
  %fseek(fd, headerBytes, 'cof');       % skip next header
  wstate = warning('off', 'MATLAB:nonIntegerTruncatedInConversionToChar');
  hdr = setstr(fread(fd, headerBytes, 'char').');
  warning(wstate);
  %hdr = setstr(fread(fd, 4, 'char').');
end

fclose(fd);

% This is a return value, but a meaningless one because the number of 
% bytes per sample varies from one frame to another.
bytesPerSample = 2;
