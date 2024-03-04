function [seq,nLeft] = binaryIn(filename, byteOffset, n, typ, fmt)
%BINARYIN       Open a file, read data from it, close it, and return the data.
% 
% seq = binaryIn(filename, byteOffset, n, typ)
%    From the file filename, skip byteOffset bytes (NOT samples, NOT sample 
%    frames) from the beginning, then read n objects of type typ and return
%    as a column vector.  If filename is actually a number (not a string), 
%    use it as the file number to read from, and don't mess with opening
%    and closing it.  typ is one of the types listed in fread, with these
%    exceptions:
%
%       int and uint are always 32 bits  (and always big-endian??)
%       intN and uintN work only when N=8, 16, or 32 (is this true of fread?)
%       these one-letter abbrevations work too:
%           c    char        (8 bits)
%           s    short       (16 bits)
%           l    long        (32 bits (64 bits on some machines!))
%           f    float       (32 bits, or short float)
%           d    double      (64 bits, or long float)
%
%    For the record, the accepted types given in fread are
%       char, schar, short, int, long, uchar, ushort, uint, ulong,
%       int8, int16, int32, float, double, float32, float64
%
% seq = binaryIn(filename, byteOffset, n, typ, machineformat)
%    As above, but use the specified machine format for reading numbers.
%    Sun/HP/SGI/Mac files are 'b' (big-endian), Vax/PC are 'l' (little-endian),
%    and others can be seen with "help fopen".
%   
% [seq,nLeft] = binaryIn(filename, byteOffset, n, typ [,fmt])
%    A second output arg returns the number of elements of the specified type
%    that are left in the file after reading.  Thus
%             [dummy,nbytes] = binaryIn(filename, 0, 0, 'c')
%    tells how many bytes are in a file.  nLeft is always an integer.
%
% See also
%    soundOut    a general-purpose interface to all the sound output routines
%    soundIn     a general-purpose interface to all the sound input routines
%    wavIn	 for WAVE-format (.wav) files
%    auIn        for Sun/NeXT format (.au/.snd)  files
%    aiffIn      for AIFF (.aif) files
%    fread       (MathWorks) generic file-reading routine
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu
% 9 May 01

typ = setstr(typ + (typ <= 'Z' & typ >= 'A') * 32);	% convert to lowercase

if     (strcmp(typ, 'c')), typ = 'char';
elseif (strcmp(typ, 's')), typ = 'short';
elseif (strcmp(typ, 'l')), typ = 'long';
elseif (strcmp(typ, 'f')), typ = 'float';
elseif (strcmp(typ, 'd')), typ = 'double';
end
if     (strcmp(typ, 'char')),   len = 1;
elseif (strcmp(typ, 'schar')),  len = 1;
elseif (strcmp(typ, 'short')),  len = 2;
elseif (strcmp(typ, 'int')),    len = 4;
elseif (strcmp(typ, 'long')),   len = 4;
elseif (strcmp(typ, 'float')),  len = 4;
elseif (strcmp(typ, 'double')), len = 8;
elseif (strcmp(typ, 'uchar')),  len = 1;
elseif (strcmp(typ, 'ushort')), len = 2;
elseif (strcmp(typ, 'uint')),   len = 4;
elseif (strcmp(typ, 'ulong')),  len = 4;
elseif (strcmp(typ, 'float32')),len = 4;
elseif (strcmp(typ, 'float64')),len = 8;
elseif (strcmp(typ, 'int8')),   len = 1;
elseif (strcmp(typ, 'int16')),  len = 2;
elseif (strcmp(typ, 'int32')),  len = 4;
elseif (strcmp(typ, 'uint8')),  len = 1;
elseif (strcmp(typ, 'uint16')), len = 2;
elseif (strcmp(typ, 'uint32')), len = 4;
elseif (strncmp(typ, 'integer*', 8)), len = str2num(typ(9:length(typ)));
else
  error(['Unknown data type code ', typ, '.']);
end

if (nargin < 5), fmt = 'native'; end
if (length(fmt) == 0), fmt = 'native'; end

% Open filename (if it's a string), or else assume it's the open-file number.
if (isstr(filename))
  fd = fopen(filename, 'r', fmt);
  if (fd < 0), error(['Can''t open the file for reading: ', filename]); end
else
  fd = filename;
end

fseek(fd, byteOffset, 'bof');
[seq,nr] = fread(fd, n, typ);
if (n ~= Inf & nr ~= n)
  error(['Couldn''t read ' num2str(n) ' items from file ' filename]);
end
if (nargout > 1)
  pos = ftell(fd);
  fseek(fd, 0, 'eof');
  nLeft = floor((ftell(fd) - pos) / len);
end

% Close file if necessary.
if (isstr(filename))
  fclose(fd);
end
