function [sound,sRate,left,nChan,dt,nBits] = ...
    soundIn(filename, offset, maxRead, chan, fmt)
%soundIn        Read part or all of a sound file.  Knows several file formats.
%
% sound = soundIn(filename)
%    Read a sound file and return the sound as a column vector.  The file 
%    format is determined from the file extension.  Works on these types 
%    of files:
%
%	file type	extension
%	---------	---------
%	WAV			.wav
%	AIFF files	.aif
%	Sun/NeXT audio	.au or .snd
%	MATLAB files	.mat	(see below)
%	binary files	.b<n>  or  .f<n>  (see below)
%	FLAC		.flac, .ogg, .aifc (compressed)
%   PMAR        .dat (and filename must start with pmNNNN)
%   other		.adc, .dac, .m11, .m7, .dy22, .dy11, .irc, .macspeech,
%                       .TIM, Haru files, Scripps files, EARS files
%
%    For MATLAB files, there must be variables named 'sound' and 'srate'.  
%
%    Binary files are specified with names like 'b8', where the 8 specifies 
%    the sampling rate in hundreds of Hertz (so .b8 would be 800 Hz).
%    Binary files are assumed to have mono 16-bit linear samples.
%
%    If the filename is a string array with more than one row, then 
%    the additional rows can be used to specify certain things about 
%    the file:
%
%       type=<extension>
%               Specify a file type.  This is useful when the file itself
%               doesn't have the right extension.  Examples:
%                   type=aif     specify that it's an AIFF file
%                   type=WAV     specify that it's a WAV file
%                   type=b2      specify that it's a 200-Hz 16-bit binary file
%               The extension is NOT appended to the file name; it's used
%               only for determining the file type.  So if you had a file 
%               named foo.dat that happened to be an AIFF file, you could
%               read it with "s = soundIn(str2mat('foo.dat','typ=aif'));"
%       chan=<n>
%               Specify a channel number. This is useful only for multi-channel
%               files like AIFF and WAV files.  Channel numbers start from 0,
%               even for MATLAB files.  If the channel number is passed in both
%               the filename and the 'chan' argument, the argument wins.
%       fmt=<machineformat>
%               Specify the byte-ordering of numbers in the file.  Sun/Mac/HP
%               use 'b' (big-endian) and Vax/PC use 'l' (little-endian).
%               See fopen for the full list of possibilities.
%
%    Example of this string-array usage:
%         x = soundIn(str2mat('myfile', 'type=wav'));
% 
% sound = soundIn(filename, offset)
%   As above, but skip the first offset sample frames in the file.  One
%   sample frame is one sample on each channel.  This works only for WAVE, 
%   AIFF, MATLAB, binary, and .snd/.au files.
%
% sound = soundIn(filename, offset, maxRead)
%    As above, but read at most maxRead samples.  If maxRead is Inf
%    or is not present (or is less than 0), read to the end of the file.
%    Using maxRead==0 will tell you how many samples are in the file.
%
% sound = soundIn(filename, offset, maxRead, chans)
%    Specify the channel number(s) to read.  Channel numbering begins at 0.
%    This is meaningful only for multi-channel formats, like .aif and .wav.
%    chans should be a vector of values, not necessarily contiguous, like
%    [0 2 3 5]. If you use NaN for chans, all channels are read.
%
% sound = soundIn(filename, offset, maxRead, chans, machineformat)
%    Specify the machine format (e.g., 'b' for big-endian like Sun/Mac/HP,
%    'l' for little-endian like PC/Vax).  See fopen for all of the options.
%    This option is useful only for binary files; all the other types have
%    a fixed format (e.g., AIFF files are always big-endian, WAVE are always 
%    little-endian, and MATLAB files already encode the big/little endian 
%    information, so machineformat is ignored for these three types.)
%    If the machineformat is not specified, or it's empty (''), it defaults
%    to the native machine format.
%
% [sound,sRate,left,nChan,dt,nBits] = soundIn( ... )
%    Additional return arguments:
%       sRate    sampling rate, in Hz; works well with maxRead=0
%       left     number of samples per channel left in the file after reading
%       nChan    number of channels in the file (for multi-channel formats)
%       dt       date file starts [and ends], encoded as in datenum; is [] if
%                  the file header doesn't include a datestamp
%       nBits    number of bits per sample; negative indicates floating-point
%                [NB: currently, nBits is implemented for only some file types]
%
%    Using this form of soundIn with the input argument maxRead equal to 0
%    is useful for finding out how long the file is, i.e., how many samples
%    per channel there are.
%
% See also 
%    soundOut    the complement of soundIn: writes sound files
%    wavIn       for WAVE-format (.wav) files
%    binaryIn    for binary headerless (.bNNN) files
%    auIn        for Sun/NeXT format (.au/.snd)  files
%    aiffIn      for AIFF (.aif) files
%    auread, wavread  (MathWorks) similar to auIn/wavIn, but don't allow
%                  reading the file in separate parts
%    fread       (MathWorks) generic file-reading routine
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu

if (nargin < 2), offset = 0;     end
if (nargin < 3), maxRead = Inf;  end
if (nargin < 4), chan = NaN;     end
if (nargin < 5), fmt = 'native'; end

if (maxRead < 0), maxRead = Inf; end

left     = -1;       % unknown
sRate    = 0;        % unknown
dt       = [];       % for formats (most of them) that don't provide a date
nChan    = 1;
try_read = 0;
nBits	 = 16;	     % for formats (most of them) that don't provide nBits

[typ,filename,ext,chan1,fmt1] = soundFileType(filename);
if (~isempty(chan1) && nargin < 4), chan = chan1; end
if (~isempty(fmt1)  && nargin < 5), fmt  =  fmt1; end

if (strcmp(typ, 'mat'))
  if (strcmp(ext, 'm22')), sRate = 22254+54/99; end	% may be overridden
  x = length(filename) - length(ext) - 1;
  last2 = filename(x-1:x);
  if (strcmp(last2, '_5')), sRate = 22255/4;  end	% BARP filename hacks
  if (strcmp(last2, '_2')), sRate = 22255/11; end
  if (strcmp(last2, '_h')), sRate = 500;      end
  
  if (strcmp(ext, 'mat'))				% MATLAB file
    varN = 1;			% first locate the 'Csnd' or 'sound' variable
    nChan = -1;
    while (nChan < 0 || ~sRate)	% go until both sound and sRate are found
      [~,name,sz] = readMatlabFile(filename, 0, 0, varN);
      if (strcmp(name, 'Csnd') || strcmp(name, 'sound'))% Csnd is Canary's name
        if (isnan(chan)), chan = 0 : sz(2)-1; end         % all channels
	maxRead = min(maxRead, sz(1) - offset);
	sound = readMatlabFile(filename, offset + sz(1)*chan(1), maxRead,varN);
	if (length(chan) > 1)
	  sound = sound(:, chan - chan(1) + 1);
	end
	left = sz(1) - maxRead - offset;
	nChan = sz(2);
      end
      if (strcmpi(name, 'srate') || strcmpi(name, 'samplingrate'))
	sRate = readMatlabFile(filename, 0, 1, varN);
      end
      varN = varN + 1;
    end      
  else
    try_read = 1;					% SoundEdit file
  end

elseif (strcmp(typ, 'snd'))			% NeXT/Sun files
  [~,nChan] = auIn(filename, 0, 0);
  if (isnan(chan)), chan = 0 : nChan-1; end
  [sound,nChan,~,sRate,left] = auIn(filename, offset, maxRead, chan);

elseif (strcmp(typ, 'str'))			% Navy file
  % nsamp nbeams day hour minute second     sRate(float)
  vec     = readBinary(filename,   0, 6, iff(version4,'long','integer*4'),fmt);
  sRate   = readBinary(filename, 4*6, 1, 'f', fmt);
  nSamp   = vec(1);         % samples per channel
  nChan    = vec(2);
  nBeamsMax = 40;
  if (isnan(chan)), chan = 0 : nChan-1; end
  byteoffset  = 28 + nBeamsMax*4 + chan(1)*nSamp*4 + offset*4;
  maxRead = min(maxRead, nSamp - offset);
  sound = readBinary(filename, byteoffset, maxRead, 'f', fmt);
  if (nChan > 1)
    sound = reshape(sound, nChan, nSamp).';
  end
  if (length(chan) ~= nChan)
    sound = sound(:, chan - chan(1) + 1);
  end
  left = nSamp - maxRead - offset;		% samples left ON THIS BEAM

elseif (strcmp(typ, 'tim'))			% HyperSignal .TIM file
  % maxamp framesize srateRem FFTorder ampexp lenRem bits nchan srateQuo lenQuo
  [vec,left] = readBinary(filename, 0, 10, 'integer*2', fmt);
  sRate      = vec(9)  * 32767 + vec(3);
  nChan      = bitand(vec(8), 63) + 1;
  extHdr     = bitand(vec(7), 4) / 4;	% long (128-byte) or short (20) header?
  off1       = iff(extHdr, 128, 20);	% bytes of header
  % In theory, nSamp is vec(10) * 16384 + vec(5).  In practice, not.
  nSamp      = (left + 10 - off1/2) / nChan;	% samples/channel in file

  maxRead = min(maxRead, nSamp - offset);
  sound   = readBinary(filename, off1 + offset*nChan*2, maxRead, 's', fmt);
  left    = nSamp - maxRead - offset;		% samples left in this channel
  if (nChan > 1)
    sound = reshape(sound, nChan, nSamp).';
  end
  if (length(chan) ~= nChan)
    sound = sound(:, chan - chan(1) + 1);
  end

elseif (strcmp(typ, 'aif'))
  [nChan,nSamp,~,sRate] = aiffIn(filename, 'COMM');
  maxRead = min(maxRead, nSamp - offset);
  if (isnan(chan)), chan = 0 : nChan-1; end
  sound   = aiffIn(filename, 'SSND', offset, maxRead, chan);
  left    = nSamp - maxRead - offset;
  
elseif (strcmp(typ, 'wav'))
  tryNo = 0;
  while (1)
    tryNo = tryNo + 1;
    fd = fopen(filename, 'r', 'l');
    if (fd >= 0), break; end
    mprintf('Open attempt #%d failed on %s.', tryNo, filename);
    if (tryNo >= 10)
      error('Unable to open file %s.', filename);
    end
    pause(10);
  end
  [nChan,~,sRate] = wavIn(fd, 'fmt ');  % read FORMAT chunk
  if (isnan(chan)), chan = 0 : nChan-1; end
  [sound,left,nBits] = wavIn(fd, 'data', offset, maxRead, chan);
  fclose(fd);
  dt = extractDatestamp(filename);
  
elseif (strcmp(typ, 'haru'))
  [~,nChan] = haruIn(filename, 0, 0);
  if (isnan(chan)), chan = 0 : nChan-1; end
  % Note channels in a Haru-file are numbered starting at 1, not 0.
  [sound,nChan,~,sRate,left,dt] = haruIn(filename,offset,maxRead,chan+1);

elseif (strcmp(typ, 'pmar'))
  [sound,nChan,~,sRate,left,dt] = pmarIn(filename, offset, maxRead, chan);

elseif (strcmp(typ, 'wispr'))
  [sound,nChan,~,sRate,left,dt] = wisprIn(filename, offset, maxRead, chan);

elseif (strcmp(typ, 'psm'))
  [sound,nChan,~,sRate,left,dt] = psmIn(filename, offset, maxRead, chan);

elseif (strcmp(typ, 'css'))
  [sound,nChan,~,sRate,left,dt] = cssIn(filename, offset, maxRead, chan);

elseif (strcmp(typ, 'ears'))
  [sound,nChan,~,sRate,left,dt] = earsIn(filename, offset, maxRead, chan);

elseif (strcmp(typ, 'mp3'))
  [sound,nChan,~,sRate,left]    = mp3In(filename, offset, maxRead, chan);
  sound = sound * 32768;

elseif (strcmp(typ, 'flac') || strcmp(typ, 'comprs'))
  % This is for .flac, .ogg, .aifc, and other compressed formats that MATLAB's
  % audioread can handle. FLAC 16-bit is more efficient than the other types.
  
  % Read into 'ai': Filename, CompressionMethod, NumChannels, SampleRate,
  % TotalSamples, Duration, BitsPerSample, BitRate, Title, Artist, Comment.
  ai = audioinfo(filename);
  nChan = ai.NumChannels;
  sRate = ai.SampleRate;
  
  left  = iff(isinf(maxRead), 0, ai.TotalSamples - (offset + maxRead));
  
  if (isnan(chan)), chan = 0 : nChan-1; end
  % Get 1-based [start end] sample indices.
  samIx = [offset+1 offset+max(maxRead,1)]; % MATLAB requires at least 1 sample
  if ((strcmp(typ, 'flac') || strcmp(typ, 'wav')) && ai.BitsPerSample == 16)
    % This is optimized for 16-bit samples, which is the most common format.
    % Only FLAC and WAVE have a valid BitsPerSample field in ai.
    
    
    if (0)
      % Read as int16 array.
      soundAllChans = audioread(filename, samIx, 'native');	%#ok<UNRCH> 
      sound = double(soundAllChans(:,chan+1));
    else
      % Read as double array (better for flac).
      soundAllChans = audioread(filename, samIx);
      sound = double(soundAllChans(:,chan+1)) * 32767;
    end
  else
    % All other cases.
    soundAllChans = audioread(filename, samIx);			% double array
    sound = soundAllChans(:,chan+1) * 32767;
  end
  
  if (strcmp(typ, 'flac') || strcmp(typ, 'wav'))
    nBits = ai.BitsPerSample;
  end

elseif (strcmp(typ, 'index'))
  [sound,nChan,~,sRate,left,dt] = indexIn(filename, offset, maxRead, chan);
  
elseif (strcmp(typ, 'whole'))
    try_read = 1;
  
elseif (strcmp(typ, 'binary') || strcmp(typ, 'float'))		% binary/float
  % Get sampling rate from extension name.
  sRate = 100 * str2double(strsubst(ext(2:length(ext)), '_', '.'));
  if (strcmp(ext, 'b1_3'))			% special case
    sRate = 128;
  end
  
  sampleFormat = iff(typ(1)=='b', 'integer*2', 'real*4');
  sampleLen    = iff(typ(1)=='b', 2, 4);
  [~,nSamp] = readBinary(filename, 0, 0, sampleFormat, fmt);
  maxRead = min(maxRead, nSamp - offset);
  sound   = readBinary(filename, offset*sampleLen, maxRead, sampleFormat, fmt);
  left    = nSamp - maxRead - offset;

else
   error(['Can''t figure out file type of ' filename]);
end

if (try_read)
  if (offset ~= 0)
    disp(['Warning: soundIn: Can''t use non-zero offset for files of type ',...
	    filename]);
  end
  if (sRate == 0), [sound,sRate] = readSound(filename);	    % mex-file reading
  else                     sound = readSound(filename);	    % mex-file reading
  end
  maxRead = min(maxRead, length(sound) - offset);
  sound = sound(offset+1 : maxRead);
  left = 0;
end

if isempty(dt)
  % No timestamp from inside the file. See if there's one in the file name.
  
  
end










