function [data,name,sz] = readMatlabFile(filename, offset, n, varNum)
% READMATLABFILE    Read part or all of a variable stored in a .mat file.
%
% data = readMatlabFile(filename)
%    Read the given file and return the matrix for its first variable.
%    No check is made to ensure that the file is in fact a MATLAB file.
%    An extension of .mat is NOT added to the filename.
%    Files in both big- and little-endian format are handled.
%
%    LIMITATION: readMatlabFile can handle only MATLAB files with ordinary 
%                MATLAB variables, i.e. real or complex 8-byte floats.
%                Sparse arrays are not handled, though it does try to
%                figure out big/little endian byte ordering.
%
% data = readMatlabFile(filename, offset)
%    As above, but skip the first offset numbers in the variable.
%    If offset > 0, the row- and column-dimensions of the matrix are 
%    ignored; the matrix returned (data) is always a column vector.  
%    You can reshape it if necessary using the matrix dimensions (see below).
%
% data = readMatlabFile(filename, offset, n)
%    As above, but read only the first n numbers of the matrix.
%    If n == Inf, read the whole matrix.
%
% data = readMatlabFile(filename, offset, n, varNum)
%    As above, for reading MATLAB files with more than one variable
%    in them.  The first variable in the file is varNum=1.
%
% data = readMatlabFile(filename, offset, n, 'varName')
%    As above, but you can specify the name of the variable instead of
%    its position in the file.
%
% [data,name] = readMatlabFile( ... )
%    As above, but also returns the variable name as a string.
%
% [data,name,sz] = readMatlabFile( ... )
%    As above, but also return the dimensions of the MATLAB variable.
%    This is the size of the whole matrix, even if you read only
%    part of it.
%
% See also readBinary.

if (nargin < 2), offset = 0; end
if (nargin < 3), n = Inf;    end
if (nargin < 4), varNum = 1; end

lengths = [8 4 4 2 2 1];
types = str2mat('double','float','int32','int16','uint16','char');

% Figure out if it's big- or little-endian.
if (isstr(filename))
  fd = fopen(filename, 'r', 'b');	% try big-endian
  if (fd < 0), error(['Can''t open file ' filename ' for reading.']); end
else
  fd = filename;
  fseek(fd, 0, 'bof');
end
x = fread(fd, 1, iff(version4, 'long', 'int32')).';
if (floor(x / 2^16) ~= 0)		% switch to little-endian
  if (isstr(filename))
    fclose(fd);
    fd = fopen(filename, 'r', 'l');
    if (fd < 0)
      error(['Can''t open file ' filename ' for reading.']); 
    end
  else
    error(sprintf('\n%s\n%s%d%s', ...
	'For MATLAB files of wrong big-/little-endian flavor, ',... 
	'you must pass the file name (you passed the file id, ', fd, ')'));
  end
end

off = 0;
if (isstr(varNum))
  % find variable named varNum
  [dummy,len] = readBinary(fd, off, 0, 'c');
  cont = 1;
  while (cont)
    if (off >= len)
      fclose(fd);
      error(['Couldn''t find variable ''', varNum, ''' in file ', filename]);
    end
    stuff = readBinary(fd, off, 5, 'L');
    name = readBinary(fd, off+20, stuff(5)-1, 'c').';
    if (strcmp(name, varNum)), break; end
    numlen = lengths(digit(stuff(1),1) + 1);
    off = off + 20 + stuff(5) + stuff(2)*stuff(3)*numlen*(stuff(4)+1);
  end
else
  % find varNum'th variable in file
  for i = 1:varNum-1
    stuff = readBinary(fd, off, 5, 'L');
    len = lengths(digit(stuff(1),1) + 1);
    off = off + 20 + stuff(5) + stuff(2)*stuff(3)*len*(stuff(4)+1);
  end
end

stuff = readBinary(fd, off, 5, 'L');
off = off + 20;

if (digit(stuff(1),3) ~= 1), 
  fclose(fd);
   error('readMatlabFile.m: Can only read MATLAB type 1 (Big Endian) files.');
end
if (digit(stuff(1),2) ~= 0  &  stuff(2) > 1  &  stuff(3) > 1),
   disp('Warning: ReadMatlabFile doesn''t handle row-major arrays well.');
end

len = lengths(digit(stuff(1),1)+1);
typ = deblank(types(digit(stuff(1),1)+1,:));

name = readBinary(fd, off, stuff(5)-1, 'c').';
name = setstr(name);
off = off + stuff(5);
sz = stuff(2) * stuff(3);

n = min(n, sz - offset);
data = readBinary(fd, off + offset*len, n, typ);
off = off + sz*len;
if (stuff(4))		% read imaginary part if necessary
   data = data + sqrt(-1)*readBinary(fd, off + offset*len, n, 'd');
   off = off + sz*8;
end
if (n >= sz), data = reshape(data, stuff(2), stuff(3)); end
if (digit(stuff(1),0) == 1), data = setstr(data); end

sz = [stuff(2) stuff(3)];

fclose(fd);
