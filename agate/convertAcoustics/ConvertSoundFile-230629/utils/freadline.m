function ln = freadline(fd)
% freadline	Read a line from a file.
%
% ln = freadline(fid)
%    Read the rest of the current line from the specified file and return it.
%    The line can be terminated with CR, LF, or both.
%    Like fgetl, the line-terminating characters are NOT returned.
%    If the end of the file is reached, -1 is returned.
% 
%
% See also fgetl, fread, fscanf.

ln = '';
while (1)
  [x,count] = fread(fd, 1, 'char');
  if (count < 1)
    % End of file; have we read anything yet for this line?
    if (length(ln) == 0)
      ln = -1;			% haven't read anything ==> return -1
    end
    return
  end
  if (x == 10 | x == 13)
    [y,count] = fread(fd, 1, 'char');
    if (count < 1), return; end		% end of file
    if (~((x == 10 & y == 13) | (x == 13 & y == 10)))
      fseek(fd, -1, 0);
    end
    return
  end
  ln = [ln x];
end
