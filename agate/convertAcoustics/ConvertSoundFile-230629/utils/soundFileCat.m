function soundFileCat(out, varargin)
%soundFileCat	Concatenate sound files.
%
% soundFileCat(outfile, infile1, infile2, ...)
%   Concatenate the sound samples in the infiles to create outfile.  
%   The types of sound files that may be read and written are determined
%   by soundIn.m and soundOut.m (q.v.).
%
%   The files that are concatenated are read and written in chunks, not
%   all at once.  This makes it possible to concatenate arbitrarily large
%   sound files, provided of course that you have enough disk space.
%
% soundFileCat(outfile, 'append', infile1, infile2, ...)
%   As above, but if outfile already exists, it is appended to instead of
%   being overwritten.
%
% See also soundIn, soundOut.
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu
% April 1, 2002

if (length(varargin) < 1)
  return
end

vi = 1;			% index into varargin
warnedRate = 0;		% have we issued a warning yet?
outOffset = 0;		% current sample position in outfile
nChan = NaN;		% number of channels in the infiles
sRate = NaN;		% sampling rate of the infiles

% Deal with 'append'.
if (strcmp(varargin{vi}, 'append'))
  vi = vi + 1;
  fp = fopen(out, 'r');
  if (fp >= 0)
    fclose(fp);
    [dummy,sRate,outOffset,nChan] = soundIn(out, 0, 0);
  end
else
  delete(out);		% make sure it's empty when we start
end

for i = vi : length(varargin)
  fname = varargin{i};
  disp(fname)
  [dummy,sRate1,nLeft,nChan1] = soundIn(fname, 0, 0)
  
  % Check for mismatched sRate and nChan.  The latter is fatal, the former not.
  if (~isnan(sRate) & sRate1 ~= sRate & ~warnedRate)
    warning('soundFileCat: The input sound files do not all have the same sample rate.');
    warnedRate = 1;
  end
  sRate = sRate1;
  if (~isnan(nChan) & nChan1 ~= nChan & ~warnedChan)
    error('soundFileCat: The input sound files must all have the same number of channels')
  end
  nChan = nChan1;
  
  inOffset = 0;
  while (inOffset < nLeft)
    n = min(65536, nLeft - inOffset);	% do in 65536-sample-frame chunks
    x = soundIn(fname, inOffset, n);
    soundOut(out, x, sRate, outOffset);
    inOffset  = inOffset  + n;
    outOffset = outOffset + n;
  end
end
