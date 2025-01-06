function [typ,outfilename,ext,chan,fmt] = soundFileType(filename)
% typ = soundFileType(filename)
%
%    Given a file name, figure out what type it is and return it as a text 
%    string.  Often the type is the same as the extension, but not always.
%    Handles multi-row filenames (where the second row specifies a filetype
%    extension or a channel number) correctly.  
%
%    This procedure is used mainly by soundIn.
%
%    Known types:
%
%	Type	Extension(s) (case insensitive)
%	----	----------------------------
%	wav		.wav, .wave			% WAVE file
%	mp3		.mp3				% MP3 file
%	mat		.mat, .m11, .m22		% MATLAB file
%	snd		.snd, .au			% NeXT/Sun audio file
%	aif		.aif, .aiff			% AIFF file
%	str		.str				% Navy format
%	haru	.dat, .sdat, .haru, .NNN	% Haru format (PMEL Vents)
%	psm	file: rNNNNNNN.NNm (or p...)	% Pioneer Seamount format
%	timv	.TIM				% HyperSignal format
%	css		.w				% CSS file (Del/LDEO)
%	ears    .h10, .h20, .h30, etc.		% EARS buoy data
%   flac	.flac				% FLAC-compressed file
%   comprs	.ogg, .aifc			% other compressed file 
%   pmar	.dat				% Seaglider PMAR acoustic system file
%	whole	.adc, .dac, .m11, .m7, .dy22, .dy11, .irc, .macspeech
%	binary	.b1, .b8, .b1_3, .b223, etc.	% 16-bit linear, with the 
%                                           %   number being SampleRate/100
%       index	.txt (with file_dates or Bilan in filename)
%	none	everything else
%
%    The file type "whole" is for files that can be read only in their entirety
%    with readSound.  Unfortunately, readSound doesn't exist on Suns.
%
%    Handles two-row filenames correctly.  The optional second and third rows
%    can specify various things about the file.  For example:
%	type=aif	this is an AIFF file (overrides any extension name)
%	chan=3		use channel 3 from the file (default is channel 0)
%	fmt=l		little-endian byte order (default is machine's default;
%                          this flag is ignored for some formats)
%
% [typ,filename,ext] = soundType(filename)
%    As above, but also return the extension and filename as separate entities.
%    This is useful when multi-row filenames are a possibility.
%
% [typ,filename,ext,chan] = soundType(filename)
%    As above, but also return the channel number specified on a multi-row
%    filename.  If no channel is specified, chan is [].
%
% [typ,filename,ext,chan,fmt] = soundType(filename)
%    As above, but also return the number format for the file.  This can
%    be 'b' for big-endian (Sun, Mac, HP, etc.) or 'l' for little-endian
%    (Vax,PC).  See fopen for the full list of possibilities.  '' is returned
%    if the user doesn't specify it.  

outfilename = char(filename(1,:));	% may get changed below
ext         = pathExt(outfilename);	% may get changed below
base        = pathRoot(pathFile(outfilename));
chan        = [];			% may get changed below
fmt         = '';

% Process the multi-row filename items.
for i = 2:nRows(filename)
  line = deblank(char(filename(i,:)));
  
  if (strncmp(line, 'type', 4))		% check 'type'
    ext = deblank(line(6:end));
    if (ext(1) == '.') 
      ext = ext(2:end); 
    end
  elseif (strncmp(line, 'chan', 4))	% check 'chan'
    x = line(6:end);		% do not combine lines (MATLAB 4.2c bug)
    chan = sscanf(x, '%d');
  elseif (strncmp(line, 'fmt', 3))	% check 'fmt'
    fmt = deblank(line(5:end));
  else
    error(['Unknown multi-row filename item: ', line])
  end
  
  % If this was the longer row, deblank the filename.
  if (nCols(line) == nCols(outfilename))
    outfilename = deblank(outfilename);
    ext = deblank(ext);
    base = deblank(base);
  end
end

ext = lower(ext);
lpo = lower(pathFile(outfilename));

% Is it a binary (integer) or float file extension?
if (length(ext) >= 2 && strcmp(ext(1), 'b'))
  e = strsubst(ext, '_', '.');
  [~,~,~,nxt] = sscanf(e(2:length(e)), '%g');
  if (nxt == length(e))
    typ = 'binary';
    return
  end
elseif (length(ext) >= 2 && strcmp(ext(1), 'f'))
  e = strsubst(ext, '_', '.');
  [~,~,~,nxt] = sscanf(e(2:length(e)), '%g');
  if (nxt == length(e))
    typ = 'float';
    return
  end
end

if (  strcmp(ext, 'mat') || ...			% MATLAB file
      strcmp(ext, 'm22') || ...
      strcmp(ext, 'm11'))
  typ = 'mat';
  
elseif (strcmp(ext, 'snd') || ...		% Sun/NeXT sound file
        strcmp(ext, 'au'))
  typ = 'snd';
  
elseif (strcmp(ext, 'str'))			% Navy file
  typ = 'str';
  
elseif (strcmp(ext, 'dat') && strcmpi(base(1:2), 'pm') && ...
    length(base) >= 6 && all(isdigit(base(3:6))))
  typ = 'pmar';
  
elseif (strcmp(ext, 'dat') && strcmpi(base(1:5), 'wispr') && ...
    sum(isdigit(base)) >= 12)	% WISPR files have a date/time stamp
  typ = 'wispr';
  
elseif (strcmp(ext, 'dat') || strcmp(ext, 'haru') || strcmp(ext, 'sdat') || ...
    (strindex(lower(base), 'datafile') > 0 ...
    && length(ext) == 3 && all(isdigit(ext))))	% Haru file
  typ = 'haru';
  
elseif (length(base) >= 8 && ...        % PSM file
     length(ext) >= 3 && ...
     (lpo(1) == 'p' || lpo(1) == 'r') && ...
     all(isdigit([base(2:8) ext(1:2)])) && ...
     lower(ext(3)) == 'm')
  % PSM file, like 'r0124423.58m' or 'r0124423.58m00' or 'p...'.
  typ = 'psm';
  
elseif (strcmp(ext, 'tim'))			% HyperSignal file
  typ = 'tim';
  
elseif (strcmp(ext, 'aif') || strcmp(ext, 'aiff'))	% AIFF file
  typ = 'aif';
  
elseif (strcmp(ext, 'wav') || strcmp(ext, 'wave'))	% WAV file
  typ = 'wav';
  
elseif (strcmp(ext, 'mp3'))				% MP3 file
  typ = 'mp3';
  
elseif (strcmp(ext, 'css') || (strcmp(ext,'w') && strindex(lpo,'.css') > 0))
  typ = 'css';						% CSS file (Del/LDEO)
  
elseif (any(strcmp(ext, {'h10','h20','h30','h40'})))
  typ = 'ears';						% EARS fmt (G/J Ioup, UNO)
  
elseif (strcmp(ext, 'flac'))				% FLAC file
  typ = 'flac';
  
elseif (any(strcmp(ext, {'ogg', 'aifc'})))		% other compressed fmts
  typ = 'comprs';

elseif (any(strcmp(ext, {'adc', 'dac', 'wav', 'm11', 'm7', 'dy22', ...
    'dy11', 'irc', 'macspeech'})))
  typ = 'whole';

elseif (strcmp(ext, 'txt') && ...
    (   strindex(lower(outfilename), 'file_dates') > 0 ...
    ||  strindex(lower(outfilename), 'bilan'     ) > 0))
  typ = 'index';					% file_dates index file
  
else						% unknown or non-soundfile
  typ = 'none';

end
