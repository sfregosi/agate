function [sams,nChans,sampleSize,sRate,nLeft,dt] = ...
                                      cssIn(filename, start, nFrame, chans)
%cssIn   Read data from a CSS-format file (from Del Bohnenstiehl at LDEO)
%
% [sams,nchan,sampleSize,sRate,nLeft,dt] = cssIn(filename, start, n, chans)
%    Read CSS file format (from CTBTO via Del at LDEO).
%    
%    Input arguments:
%      start      is the starting sample number; default is 0, meaning the
%                 first sample in the file
%      n          is the number of samples to read per channel; default is Inf,
%                 meaning read the entire file
%      chans      says which channels to read; default is all of them; channel
%                 numbering starts at 0
%
%    Output arguments:
%      sams       is a column vector of samples (or multi-column array, if
%                 chans's length is >= 2)
%      nchan      says how many channels are in the file
%      sampleSize is the number of bytes per sample, 1 or 2
%      sRate      is the sampling rate, Hz
%      nLeft      is the number of sample frames remaining in the file after
%                 reading (use cssIn(filename, 0, 0) to get the total number
%                 of samples in the file)
%      dt         is the date/time in GMT that the file starts, encoded as
%                 in datenum
%
% Dave Mellinger
% 30 Aug 2002

if (nargin < 2), start  = 0;   end
if (nargin < 3), nFrame = inf; end
if (nargin < 4), chans  = NaN; end

wfdiscName = [pathRoot(pathRoot(filename)) '.wfdisc'];

[t0,nFrameNominal,sRate,fn] = textread(wfdiscName, ...
  '%*15c %f %*d %*d %*4d%*3d %*f %d %f %*f %*f %*80c %s %*d %*d %*s');
k = pathFile(filename);

% Figure out which line of the wfdisc file to use.
ix = strmatch(k(2:end), fn);
if (isempty(ix))
  error(['Error reading the .wfdisc file: There is no filename in ' 10 ...
	  'it matching the input file name, ''' pathFile(filename) '''.']);
end
if (length(ix) > 1)
  error(['Error reading the .wfdisc file: There are >= 2 filenames in ' 10 ...
	  'it matching the input file name, ''' pathFile(filename) '''.']);
end

t0            = t0(ix);
nFrameNominal = nFrameNominal(ix);
sRate         = sRate(ix);
nChans        = 1;                    % true for all CSS files?
sampleSize    = 4;                    % true for all CSS files?
valueOffset   = 119194;

if (isnan(chans))
  chans = 0 : nChans-1;
end

% Convert date to datenum format.
dt = datenum(1970,1,1,0,0,t0);			% new encoding
%dt = datevec(datenum(1970,1,1,0,0,t0));	% old encoding, which was...
%dt(1) = dt(1) - 1900;				% ...an odd sort of vector

fd = fopen(filename, 'r', 'b');       % big-endian format
if (fd < 0)
  error(['Can''t open the data file ''' filename ''' .']);
end
nFrameTotal = floor(flength(fd) / sampleSize / nChans);
if (nFrameTotal ~= nFrameNominal)
  global cssInLastWarn
  warnNow = pathFile(filename);
  if (~strcmp(cssInLastWarn, warnNow))
    warn(['The .wfdisc file ''' wfdiscName ''' and the actual data file' 10 ...
	    '''' filename ''' disagree about the number of samples present.']);
    cssInLastWarn = warnNow;
  end
end
start  = min(start, nFrameTotal);
nFrame = min(nFrame, nFrameTotal - start);
nLeft  = nFrameTotal - (start + nFrame);
fseek(fd, start * sampleSize * nChans, 'bof');

% Read the data, reshape into sams array.
sams = fread(fd, nFrame * nChans, 'long');
sams = reshape(sams, nChans, nFrame).';
sams = sams(:, chans+1) - valueOffset;
fclose(fd);
