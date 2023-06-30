function wavOut(filename, x, sRate, offset, nBits)

%wavOut	Write a sound file in WAVE format, the standard format on PC's.
%
% wavOut(filename, x, sRate)
%    Create an WAV file with sound data x sampled at sRate Hz.  If x
%    has multiple columns, then a multi-channel file will be created.
%
% wavOut(filename, x, sRate, offset)
%    As above, but start writing at sample frame OFFSET.  (One sample frame
%    is one sample on all channels.)  To write a file with several successive
%    calls, use offset=0 in the first call to write the first N1 sample
%    frames, then offset=N1 in the next call to write the next N2 sample
%    frames, then offset=N1+N2 in the next call, and so on.
%
% wavOut(filename, x, sRate, offset, nBits)
%    nBits says how many bits/sample to write.  The default is 16, but 8, 24,
%    or 32 also work.  If nBits is negative, it means write floating-point
%    samples instead of integers; then 32 or 64 bits may be used.
% 
% See also 
%    soundOut    a general-purpose interface to all the sound output routines
%    soundIn     a general-purpose interface to all the sound input routines
%    binaryOut   for binary headerless (.bNNN) files
%    auOut       for Sun/NeXT format (.au/.snd)  files
%    aiffOut     for AIFF (.aif) files
%    wavwrite    (MathWorks) similar, but doesn't permit writing the file in
%                separate parts; allows other sample codings than 16-bit linear
%    fwrite      (MathWorks) generic file-reading routine
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu
% 9 May 01

if (nargin < 4), offset = 0; end
if (nargin < 5), nBits = 16; end

% Expect column vectors.
if (nRows(x) < nCols(x) && nRows(x) > 16)
  warning('wavOut: multiple channels must be in columns.')
end

% All of these are in numbers of samples (not bytes).
npts = nRows(x);
nchan = nCols(x);
nhere = npts * nchan;
ntotal = (offset + npts) * nchan;

% Open file.
fid = fopen(filename(1,:), iff(offset == 0, 'w+', 'r+'), 'l');  % little-endian
if (fid < 0)
  error(['Cannot open file ' filename]);
end

nbytes = ceil(abs(nBits) / 8);

if (offset == 0)
  % Write the WAV file header.
  
  % Write RIFF chunk.  The RIFF chunk contains all the other chunks.
  fwrite(fid, 'RIFF',          'char');
  fwrite(fid, 36 + nhere * nbytes,  'long');   % length excluding 'RIFF<len>'
  fwrite(fid, 'WAVE',          'char');
  
  % Write fmt chunk.
  fwrite(fid, 'fmt ',          'char');   % 'fmt ' or fmt\0 or 'FMT ' or FMT\0?
  fwrite(fid, 16,	       'long');   % length of this chunk after here
  fwrite(fid, 1,	       'short');  % linear coding ("WAVE_FORMAT_PCM")
  fwrite(fid, nchan,           'short');  % number of channels
  fwrite(fid, round(sRate),    'long');   % sample rate
  fwrite(fid, round(sRate) * nchan * nbytes, 'long'); % average bytes/second
  fwrite(fid, ceil(nchan * nbytes), 'short');  % block offset (???)
  fwrite(fid, abs(nBits),      'short');  % bits per sample

  % Write data chunk.
  fwrite(fid, 'data',	       'char');
  fwrite(fid, nhere * nbytes,  'long');   % length of this chunk after here

else

  % The offset is non-zero.  The header has already been written; fix it up
  % for the new length of the file.
  
  % Fix up RIFF chunk length, which includes whole file except RIFF<len>.
  fseek(fid, 4, 'bof');
  fwrite(fid, 36 + ntotal * nbytes, 'long');   % length excluding 'RIFF<len>'
  
  % Fix up data chunk length.
  fseek(fid, 40, 'bof');
  fwrite(fid, ntotal * nbytes, 'long');
  
  % Move to where to write samples.
  if (fseek(fid, 44 + offset * nchan * nbytes, 'bof') < 0)
    error(['Moving to the specified offset point failed, perhaps because ' ...
	    'offset does not equal the number of samples already written.']);
  end
end

% Figure out the 'precision' argument for fwrite.
prec = sprintf('%s%d', iff(nBits > 0, 'int', 'float'), abs(nBits));
if (nBits == 24), prec = 'bit24'; end		% special case

% Write the samples and close the file.
fwrite(fid, round(x).', prec);		% column-major, which interleaves chans
fclose(fid);
