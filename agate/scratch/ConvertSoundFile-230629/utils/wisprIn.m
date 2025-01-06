function [sams,nChans,bytesPerSample,sRate,nLeft,dt] = ...
                                   wisprIn(filename, startFrame, nFrame, chans)
%wisprIn           Read a WISPR sound file.
%
% [sams,nChans,bytesPerSample,sRate,nLeft,dt] = wisprIn(filename)
%    From a WISPR .dat file, read the file and return, respectively, all the
%    samples in it, the number of channels (normally 1), the sample size in
%    bytes, the sampling rate per channel in samples/s, the number of sample
%    frames remaining in the file after your read (one sample frame equals one
%    sample across all the channels), and the date.
%       The samples are returned in a matrix that has the data from
%    each channel filling one column. The date is encoded as by datenum.
%
% ... = wisprIn(filename, start, n, chans)
%    You can also read only part of the file. 'start' is the sample frame number
%    to start reading at; the first sample is start=0, which is the default. 'n'
%    is the number of samples to read per channel (i.e., number of sample
%    frames) to read. If n=Inf (the default), it means to read the whole sound.
%    'chans' is a vector specifying which channels are desired, with channel 0
%    being the first channel. chans defaults to NaN, which means read all
%    channels. (So far WISPR files are 1-channel, so the chans argument isn't
%    needed, but this may change in the future.)
%
%    start and n may both be 0.  In this case, you get back nChans, nLeft, etc.
%    without actually reading any samples.
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
% David.Mellinger@oregonstate.edu

if (nargin < 2), startFrame  = 0;   end
if (nargin < 3), nFrame = inf; end
if (nargin < 4), chans  = NaN; end

nChans = 1;			% default; not specified in WISPR header
bytesPerSample = 2;		% default

fp = fopen(filename, 'r', 'l');	% open for reading, little-endian
if (fp < 0)
  error('Can''t open file %s for reading.', filename);
end
  
WISPR_HEADER_SIZE = 512;
WISPR_BLOCK_SIZE = 512;

dt = 0;
%% Read header.

% Main loop: Read a header line, parse it, and store the value. The loop exits
% when it hits a \0 (NUL) character (the normal case), or after reading
% WISPR_HEADER_SIZE (512) characters (so we don't read sound data as header).

wisprVersion = '';	 %#ok<NASGU>  might get overridden below
lineNum = 0;
nReadTotal = 0;		% number of bytes
while (nReadTotal < WISPR_HEADER_SIZE)
  lineNum = lineNum + 1;
  ln = fgets(fp, WISPR_HEADER_SIZE);

  % Reached end of header lines, as indicated by a \0 character?
  len = length(ln);
  if (len < 1 || ln(1) == 0)
    break
  end
  nReadTotal = nReadTotal + len;

  % Strip trailing CR/LF, whitespace, and ';'.
  while (~isempty(ln) && any(ln(end) == [9 10 13 ' ;']))
    ln(end) = '';
  end

  % On first line in file, try to read the WISPR version number. This isn't used
  % anywhere yet, but might be in the future if the file format changes.
  if (lineNum == 1)
    [wisprVersion,nScan] = sscanf(ln, '%% WISPR %s');		%#ok<ASGLU> 
    if (nScan == 1)
      continue
    end
  end

  % Parse an ordinary "varname = value;" line. If the line isn't in this format
  % and textscan fails, just ignore the line.
  x = textscan(ln, "%s = %s");
  if (length(x) >= 2)
    varname = x{1}{1};
    value   = x{2}{1};
    switch(varname)
      case 'sampling_rate'
	sRate = sscanf(value, "%f");
      case 'sample_size'
	bytesPerSample = sscanf(value, "%f");
      case 'time'
	[x,nScanned] = sscanf(value, "'%d:%d:%d:%d:%d:%d");
	if (nScanned == 6)	% was sscanf successful?
	  dt = datenum(x(3)+2000, x(1), x(2), x(4), x(5), x(6)); %#ok<DATNM> 
	end
      case 'file_size'
	% Parse a file size. file_size in the WISPR file header is the number
	% of 512-byte (WISPR_BLOCK_SIZE) blocks; it's read as an int64 but then
	% converted to double because int64s don't behave normally for MATLAB.
	fsize = sscanf(value, "%ld");
	nBytesFromHeader = double(fsize) * WISPR_BLOCK_SIZE;

    end	% switch
  end	% if (nScan...)
end	% while

% Figure out how many samples are in the file. This is the lesser of how many
% the header claims are there, and how many are actually present based on file
% length.
fseek(fp, 0, 'eof');
nBytesFromLen = ftell(fp) - WISPR_HEADER_SIZE;
nBytes = iff(nBytesFromHeader == 0, nBytesFromLen, ...
  min(nBytesFromLen, nBytesFromHeader));
nFramesInFile = nBytes / bytesPerSample / nChans;


% Check various fields for validity.
%if (wi->sRate >= 50 &&
%wi->nSamp > 1000 &&
%(wi->bytesPerSample == 2 || wi->bytesPerSample == 3) &&
%wi->timeE >= 946684800) {		%that's 1/1/2000
%return wi;
%} else {
%return NULL;
%}

%% Read samples.

fseek(fp, startFrame * bytesPerSample * nChans + WISPR_HEADER_SIZE, 'bof');
nFramesToRead = min(nFrame, nFramesInFile - startFrame);
if (bytesPerSample ~= 3)
  prec = sprintf('int%d', bytesPerSample * 8);
  sams = fread(fp, [nChans nFramesToRead], prec).';
else
  ch = fread(fp, [3 nChans*nFramesToRead], 'uint8');
  if (nFramesToRead == 0), ch = zeros(3,0); end
  s1 = int32(ch(3,:)*2^16 + ch(2,:)*2^8 + ch(1,:)); % WISPR files: little endian
  ix = (ch(3,:) >= 0x80);			% indices of negative samples
  s1(ix) = typecast(bitor(s1(ix), -(2^24)), 'int32');
  sams = double(reshape(s1, nChans, nFramesToRead).');
end
if (~isnan(chans) && nCols(sams) > 1)
  if (isnan(chans)), chans = 0 : nCols(sams)-1; end
  sams = sams(:, chans + 1);
end
nLeft = nFramesInFile - startFrame - nFramesToRead;

fclose(fp);
