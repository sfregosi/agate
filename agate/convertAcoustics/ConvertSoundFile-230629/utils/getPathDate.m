function dtnum = getPathDate(pathname)
%getPathDate	return the modify-date of the given file
%
% dtnum = getPathDate(pathname)
%   Given a path name, return its modify-date as a datenum. 'pathname' may also
%   be a cell array of pathnames, in which case a numeric array of datenums is
%   returned.
%
% Dave Mellinger

if (iscell(pathname))
  dtnum = cellfun(@(x) getPathDate(x), pathname);
else
  if (exist(pathname, 'dir'))
    % Special handling for directory names because dir() returns info about
    % every file in the directory. Get dir entry from parent dir listing. Also
    % have to handle a parent like 'C:' specially because Windows.
    if (any(pathname(end) == '\/')), pathname = pathname(1 : end-1); end
    dirArg = pathDir(pathname);
    dirArg = [dirArg iff(length(dirArg)==2 && dirArg(2)==':', '\', '')];
    parentInfo = dir(dirArg);
    info = parentInfo(strcmp({parentInfo.name}, pathFile(pathname)));
  else
    info = dir(pathname);
  end
  dtnum = info.datenum;
end
