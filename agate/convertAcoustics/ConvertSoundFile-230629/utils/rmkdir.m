function rmkdir(dirr)
%RMKDIR		recursive mkdir allowing many-element paths
%
% rmkdir(newdirectory)
%   Create newdirectory and, if necessary, its parent directories. Unlike mkdir,
%   does not signal an error if newdirectory already exists.

if (~exist(pathDir(dirr), 'dir'))
  rmkdir(pathDir(dirr));
end

if (~exist(dirr, 'dir'))
  mkdir(pathDir(dirr), pathFile(dirr));
end
