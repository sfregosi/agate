function writeBinary(filename, offset, data, typ, tr)
% WRITEBINARY    Open a file, write data to it, close it.
%
% writeBinary(filename, offset, data, typ [,trunc])
%    From the file filename, skip offset bytes from the beginning, then
%    write the data array (column-major order) as type typ.  typ is 
%    one of the types listed in fread, with these exceptions:
%   
%       int and uint are always 32 bits
%       intN and uintN work only when N=8, 16, or 32 (is this true of fread?)
%       these abbrevations work too:
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
%    If the trunc argument is present and non-zero, truncate the file
%    TO ZERO LENGTH before writing.  If you do this, the offset should be 0.
%
% See also
%    soundOut    a general-purpose interface to all the sound output routines
%    soundIn     a general-purpose interface to all the sound input routines
%    wavOut	 for WAVE-format (.wav) files
%    auOut       for Sun/NeXT format (.au/.snd)  files
%    aiffOut     for AIFF (.aif) files
%    fwrite      (MathWorks) generic file-reading routine
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
else
  error(['Unknown data type code ', typ, '.']);
end

if (nargin < 5), tr = 0; end
if (tr)
  fd = fopen(filename(1,:), 'w');
else
  fd = fopen(filename(1,:), 'a+');		% fseek is done below
end

if (fd < 0), error(['Can''t open the file for writing: ', filename]); end
nw = fwrite(fd, data, typ);
fclose(fd);
if (nw ~= prod(size(data)))
  error(['Couldn''t write ',num2str(prod(size(data))),' items to file ', ...
	  filename]);
end
