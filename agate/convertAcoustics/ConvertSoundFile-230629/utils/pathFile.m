function f = pathFile(p)
%pathFile	return the file component, including extension, of a full path
%
% filename = pathFile(pathname)
% Given a pathname, strip off the leading directory names. If pathname is a cell
% array of paths, apply pathFile to each element of the array.
%
% See also pathRoot, pathExt, pathDir, pathFileDisk, filesep, fileparts.

if (iscell(p))
  f = cellfun(@(x) pathFile(x), p, 'UniformOutput', false);
else
  p = char(p);				% handle strings
  w = [0  find(p == '/' | p == '\')];	% 0 handles case where there's no / or \
  f = p(w(end)+1 : end);
end
