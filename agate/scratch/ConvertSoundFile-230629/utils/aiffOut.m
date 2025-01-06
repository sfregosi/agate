function aiffOut(filename, x, sRate, offset)

%aiffOut	Write a sound file in Audio Interchange File Format.
%
% aiffOut(filename, x, sRate)
%    Create an AIFF file with sound data x sampled at sRate Hz.  If x
%    has multiple columns, then a multi-channel file will be created.
%
% aiffOut(filename, x, sRate, offset)
%    As above, but start writing at sample frame OFFSET.  (One sample frame
%    is one sample on all channels.)  To write a file with several successive
%    calls, use offset=0 in the first call to write the first N1 sample
%    frames, then offset=N1 in the next call to write the next N2 sample
%    frames, then offset=N1+N2 in the next call, and so on.
%
% See also 
%    soundOut    a general-purpose interface to all the sound output routines
%    soundIn     a general-purpose interface to all the sound input routines
%    wavOut	     for WAVE-format (.wav) files
%    binaryOut   for binary headerless (.bNNN) files
%    auOut       for Sun/NeXT format (.au/.snd)  files
%    fwrite      (MathWorks) generic file-reading routine
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu

if (nargin < 4), offset = 0; end

% Expect column vectors.
if (nRows(x) < nCols(x) & nRows(x) > 16)
  disp('aiffOut: warning: multiple channels must be in columns.')
end

% All of these are in numbers of samples (not bytes).
npts = nRows(x);
nchan = nCols(x);
nhere = npts * nchan;
ntotal = (offset + npts) * nchan;

% Open file.
fid = fopen(filename(1,:), iff(offset == 0, 'w+', 'r+'), 'b'); % AIFF is big-endian
if (fid < 0)
  error(['Cannot open file ' filename]);
end

if (offset == 0)
  % Write the AIFF file header.
  
  % Write FORM chunk.  The FORM chunk contains all the other chunks.
  fwrite(fid, 'FORM',         'char');
  fwrite(fid, 46 + nhere * 2, 'uint32');
  fwrite(fid, 'AIFF',         'char');
  
  % Write COMM chunk.
  fwrite(fid, 'COMM',	'char');
  fwrite(fid, 18,	'uint32');  % length of this chunk after here
  fwrite(fid, nchan,	'uint16');  % number of channels
  fwrite(fid, npts,	'uint32');  % number of samples per channel
  fwrite(fid, 16,	'uint16');  % sample size

  % Write sampling rate as an 80-bit long double.
  % The 80 bit number is formed by a 2 byte exponent and an 8 byte
  % mantissa.  The number that it represents is
  % 
  % 	2^(exponent-expoffset)*mantissa             where expoffset is 16383
  %
  expon = floor(log(sRate) / log(2));
  mant = sRate / 2^expon;
  mant1 = floor(mant * 2^31);
  mant2 = floor(((mant * 2^31) - mant1) * 2^32);
  fwrite(fid, expon + 16383, 'uint16');
  fwrite(fid, mant1,         'uint32');
  fwrite(fid, mant2,         'uint32');
  
  % write SSND chunk
  fwrite(fid, 'SSND',        'char');
  fwrite(fid, 8 + nhere * 2, 'uint32'); % length of this chunk after here
  fwrite(fid, [0 0],         'uint32'); % offset, ???

else

  % The offset is non-zero.  The header has already been written; fix it up
  % for the new length of the file.
  
  % Fix up FORM chunk length (FORM chunk is whole file).
  fseek(fid, 4, 'bof');
  fwrite(fid, 46 + ntotal * 2, 'uint32');
  
  % Fix up number of samples per channel.
  fseek(fid, 22, 'bof');
  fwrite(fid, offset + npts, 'uint32');
  
  % Fix up SSND chunk length.
  fseek(fid, 42, 'bof');
  fwrite(fid, 8 + ntotal * 2, 'uint32');
  
  % Move to where to write samples.
  if (fseek(fid, 54 + offset * nchan * 2, 'bof') < 0)
    error(['Moving to the specified offset point failed, probably because '...
	'offset does not equal the number of samples previously written.']);
  end
end

% Write the samples and close the file.
fwrite(fid, x.', 'int16');	% column-major, which interleaves chans
fclose(fid);
