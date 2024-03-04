function nbytes = flength(filename)
% FLENGTH     File length in bytes.
%
% nbytes = flength(filename)
%   Return the length in bytes of FILENAME.
%
% nbytes = flength(fid)
%   Return the length in bytes of the open file FID.
%
% See also ftell, fseek, fopen, length, size.

if (isnumeric(filename))
  fid = filename;
  k = ftell(fid);
  fseek(fid, 0, 'eof');
  nbytes = ftell(fid);
  fseek(fid,  k, 'bof');
else
  fid = fopen(filename, 'r');
  fseek(fid, 0, 'eof');
  nbytes = ftell(fid);
  fclose(fid);
end
