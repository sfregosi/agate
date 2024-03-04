function e = pathExt(p)
% ext = pathExt(pathname)
% Given a pathname, return the extension (without its initial '.').
% If there is no '.' in the filename, return ''.
%
% See also pathDir, pathRoot, pathFile, filesep.

extchar = '.';			% character that starts an extension

e = '';				% default result
p = pathFile(char(p));		% get rid of directory part of path
w = find(p == extchar, 1, 'last');
if (~isempty(w))
  e = p(w+1 : end);
end
