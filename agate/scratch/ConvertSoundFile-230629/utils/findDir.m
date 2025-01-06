function s = finddir(varargin)
%FINDDIR	Find which of several directories actually exists.
%
% finddir('dirname1', 'dirname2', ...)
%   If dirname1 exists, return it.  Else if dirname2 exists, return it.  
%   Else if dirname3 exists, return it.  And so on.  If none of the
%   directories exists, generate an error.  The directory names can be
%   either relative, like 'foo/bar/baz', or absolute, like
%   '/usr/ken/foo' or 'C:\bill\foo'.
%
% finddir('no error', 'dirname1', 'dirname2', ...)
%   If any argument is the string 'no error', simply return an empty
%   string instead of generating an error if none of the directories
%   exist.  This 'no error' string can be anywhere in the list of
%   directories; it need not be the first one.
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu
% 8/6/02

noerror = 0;
dirlist = '';
for i = 1:nargin
  s = varargin{i};
  if (isstr(s))
    if (strcmp(s, 'no error'))
      noerror = 1;
    else
      dirlist = [dirlist char(10) '    ' s];
      if (exist(s, 'dir') == 7)
	return
      end
    end
  end
end

if (noerror)
  s = '';
else
  error(['finddir: Could not find any of these directories: ' dirlist]);
end
