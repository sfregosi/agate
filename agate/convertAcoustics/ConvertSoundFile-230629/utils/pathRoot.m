function r = pathRoot(p)
% root = pathRoot(pathname)
%    Given a pathname, return the pathname sans extension.
%    This includes the directory name(s) in the path.
%
% See also pathDir, pathExt, pathFile, filesep.

p = char(p);			% handle strings

extSep = '.';
r = p;
w = find(p == extSep, 1, 'last');
if (~isempty(w))
  if (w > length(pathDir(p)))	% check that '.' is not in dirname
    r = p(1 : w-1);
  end
end
