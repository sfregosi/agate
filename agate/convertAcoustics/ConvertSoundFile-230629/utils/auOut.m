function auOut(filename, x, sRate, offset)

%auOut  Write a sound file in Sun/NeXT audio file format.
%
% auOut(filename, x, sRate)
%    Create a .au file with sound data X sampled at sRate Hz.  If x
%    has multiple columns, then a multi-channel file will be created.
%    Samples are written in 16-bit linear format.  x should
%    be scaled to be in the range [-32768, +32767].
%
% auOut(filename, x, sRate, offset)
%    As above, but start writing at sample frame OFFSET.  (One sample frame
%    is one sample on all channels.)  To write a file with several successive
%    calls, use offset=0 in the first call to write the first N1 sample
%    frames, then offset=N1 in the next call to write the next N2 sample
%    frames, then offset=N1+N2 in the next call, and so on.
%
% See also 
%    soundOut    a general-purpose interface to all the sound output routines
%    soundIn     a general-purpose interface to all the sound input routines
%    wavOut	 for WAVE-format (.wav) files
%    binaryOut   for binary headerless (.bNNN) files
%    aiffOut     for AIFF (.aif) files
%    auwrite     (MathWorks) similar, but doesn't permit writing the file in
%                separate parts; allows other sample codings than 16-bit linear
%    fwrite      (MathWorks) generic file-reading routine
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu
% 9 May 01

if (nargin < 4), offset = 0; end

% Expect column vectors.
if (nRows(x) < nCols(x) & nRows(x) > 16)
  disp('auOut: warning: multiple channels must be in columns.')
end

% All of these are in numbers of samples (not bytes).
npts = nRows(x);
nchan = nCols(x);
nhere = npts * nchan;
ntotal = (offset + npts) * nchan;

% Open file.
fid = fopen(filename(1,:), iff(offset == 0, 'w+', 'r+'), 'b'); % AU is big-endian
if (fid < 0)
  error(['Cannot open file ' filename]);
end

if (offset == 0)
  % Write the AU file header.
  
  fwrite(fid, '.snd',   'char');    % magic number
  fwrite(fid, 32,       'uint32');  % length of header
  fwrite(fid, ntotal*2, 'uint32');  % total data length
  fwrite(fid, 3,        'uint32');  % encoding -- 16-bit linear
  fwrite(fid, sRate,    'uint32');  % number of samples per channel
  fwrite(fid, nchan,    'uint32');  % sample size
  fwrite(fid, [0 0],    'uint32');  % info, 8 bytes

else

  % The offset is non-zero.  The header has already been written; fix it up
  % for the new length of the file.
  fseek(fid, 8, 'bof');
  fwrite(fid, ntotal * 2, 'uint32');
  
  % Move to where to write samples.
  if (fseek(fid, 32 + offset * nchan * 2, 'bof') < 0)
    error(['Moving to the specified offset point failed, probably because '...
           'offset does not equal the number of samples previously written.']);
  end
end

% Write the samples and close the file.
fwrite(fid, x.', 'int16');      % column-major, which interleaves chans
fclose(fid);
