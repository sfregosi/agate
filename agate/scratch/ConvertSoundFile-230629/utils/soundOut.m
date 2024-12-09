function soundOut(filename, data, sRate, offset, nBits)
%soundOut        Write part or all of a sound file. Knows several file formats.
%
% soundOut(filename, sound, sRate)
%    Write sound from the given sound vector(s) to the given filename.
%    The file format is decided from the file name extension; see 
%    soundFileType.m.
% 
%    This works for binary (.bNNN), AIFF (.aif), WAVE (.wav), and Sun audio
%    (.au/.snd) files; hopefully more formats will be added soon.
%
%    Some file formats (.wav, .aif, .au) allow the sound samples to be in any
%    one of several encodings.  soundOut always uses 16-bit linear encoding.
%
% soundOut(filename, sound, sRate, offset)
%    An additional argument, offset, if used for writing files in several 
%    sequential passes instead of all at once.  offset says how many 
%    sample frames after the start of the file the data should be written.
%    (A sample frame is one sample on all channels; for a one-channel file,
%    it equals the number of samples.)  To write a file in several passes, 
%    use offset=0 on the first call with the first sample frames -- say, N1 of
%    them.  On the next pass, use offset=N1 to write the next N2 sample frames.
%    On the next pass, use offset=N1+N2.  And so on.
%
% soundOut(filename, sound, sRate, offset, nBits)
%    As above, but also specify the number of bits per sample to write out;
%    currently, THIS OPTION WORKS ONLY FOR .WAV FILES.  A negative number 
%    says to write floating-point samples, in which case nBits should be -32 
%    or -64.
%
% See also 
%    soundIn     the complement of soundOut: reads sound files
%    wavOut	 for WAVE-format (.wav) files
%    binaryOut   for binary headerless (.bNNN) files
%    auOut       for Sun/NeXT format (.au/.snd)  files
%    aiffOut     for AIFF (.aif) files
%    auwrite, wavwrite  (MathWorks) similar to auOut/wavOut, but don't allow
%                  writing the file in separate parts; do allow other sample
%                  encodings than 16-bit linear
%    fwrite      (MathWorks) generic file-reading routine
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu
% 9 May 01

if (nargin < 4 || isempty(offset)), offset = 0;  end
if (nargin < 5 || isempty(nBits)),  nBits  = 16; end

typ = soundFileType(filename);

if (strcmp(typ, 'aif'))
  aiffOut(filename(1,:), data, sRate, offset);

elseif (strcmp(typ, 'wav'))
  wavOut(filename(1,:), data, sRate, offset, nBits);

elseif (strcmp(typ, 'snd'))
  auOut(filename(1,:), data, sRate, offset);

elseif (strcmp(typ, 'binary'))
  binaryOut(filename(1,:), offset * 2, data, 'int16', 1);

elseif (strcmp(typ, 'mp3'))
  if (offset ~= 0)
    error(['"offset" is nonzero, but I can handle writing of .mp3 files' 10 ...
      'only when you write a whole file at once.\n(While writing %s)'],...
      filename(1,:));
  end
  if (~exist('mp3write', 'file'))
    error(['You need to add Dan Ellis''s mp3write to your MATLAB path.' 10 ...
      'If you don''t have it, get it from the MathWorks File Exchange site.']);
  end
  mp3write(data, sRate, 16, filename(1,:));	% nBits must be 16 in mp3write
  
else
  error([filename ': Unknown file format for extension ''' typ '''.']);
end
