function d = pathDir(p)
% function dirname = pathDir(pathname)
%    Return the directory that a given path is located in.
%    On Unix, this is everything up to the last /,
%    on Windows, everything up to the last \, and
%    on the Mac, everything up to the last :.
%    If pathname has no directory, '/' is returned on Unix and '' on the Mac.
%
% See also pathRoot, pathExt, pathFile, filesep, fileparts.

p = char(p);			% handle strings
if (~isempty(p))
  i = find(p == '/' | p == '\');
else
  i = [];
end
if (~isempty(i))
  d = p(1:i(length(i))-1);
else
  d = '';		% Mac
  if (isunix) 
    d = '.';		% Unix
  end
end
