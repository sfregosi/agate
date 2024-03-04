function f = filelist(pattern)
%FILELIST	Return an array of filenames from a Unix 'ls' command.
%
% f = filelist(pattern)
%    Return an array of filenames.  Each row is blank-padded on the end.
%    The pattern argument is used in Unix's ls command, so it can
%    be a directory name, a filename wildcard, or whatever.
%
% See also UNIX, LS (which should do what this does), DEBLANK.


if (nargin < 1), pattern = ''; end

% Use /bin/ls rather than plain ls to avoid csh aliases like 'ls -ACF'.
[ret,list] = unix(['/bin/ls -1 ' pattern]);

if (ret)			% ls didn't work -- bad pattern
  f = '';
  return
end

% 'list' is a 1xN vector; convert it to a matrix.
breaks = [0, find(list == 10)];
f = setstr(ones(length(breaks)-1, max(diff(breaks))) * ' ');
for i = 1:length(breaks)-1
  n = breaks(i+1) - breaks(i) - 1;
  f(i,1:n) = list(breaks(i)+1 : breaks(i+1)-1);
end
