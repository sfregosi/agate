function success = byteswapfile(infilename, outfilename, silent)
% BYTESWAPFILE		Swap adjacent bytes of a file.
%
% success = byteswapfile(infilename, outfilename [,silent])
%    Swap adjacent bytes of a file.  If silent is 0 (or absent), generate
%    an error if the files can't be opened; otherwise silently return 0.
%    Returns 1 upon success.  Files that have an odd number of bytes have
%    the last byte removed upon copying.

if (nargin < 3), silent = 0; end

success = 0;					% can get changed later

% Open input file.
fdIn = fopen(infilename, 'r', 'l');		% little-endian
if (fdIn < 0)
  if (silent)
    return
  end
  error(['Can''t open input file ' infilename '.']); 
end

% Open output file.
fdOut = fopen(outfilename, 'w', 'b');		% big-endian
if (fdOut < 0)
  fclose(fdIn);
  if (silent)
    return
  end
  error(['Can''t open output file ' outfilename '.']); 
end

% Copy infile to outfile.
nread = 1;					% dummy value
while (nread > 0)
  [x,nread] = fread(fdIn, 500000, 'int16');
  nwrite = fwrite(fdOut, x, 'int16');
  if (nwrite < nread)
    error(['Can''t write to output file ' outfilename '; perhaps disk is full?']);
  end
end
fclose(fdIn);
fclose(fdOut);
success = 1;
