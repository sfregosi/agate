function str = mlFileNameFilter(str)
%mlFileNameFilter    Convert a file name to a MATLAB variable name.
%
% outfilename = mlFileNameFilter(infilename)
% Return a filename stripped of the characters MATLAB doesn't like.
% This is useful when you use LOAD to read a non-MATLAB file.
%
% See also loadascii.

% strip directory names and extension
str = pathRoot(pathFile(str));

% strip digits from the front (no longer done in MATLAB 4.1)
%for x = 1:length(str)
%   if (~max(str(x) == '0123456789')), break; end;
%end
%str = str(x:length(str));
%if (max(str(1) == '0123456789')),
%   disp('Warning: MATLAB version of filename has no characters; using ''x''.');
%   str = 'x';
%end

% strip remaining extensions
x = strrindex(str, '.');
if (x), str = str(1:x-1); end

% strip funky characters  (no longer done in MATLAB 4.1)
%x = 1;
%while (x <= length(str)),
%   if (sum(str(x) == '!@#$^&*()-+=[{}]\|;:''",<>/?`~')),
%      str = [str(1:x-1), str(x+1:length(str))];
%   else
%      x = x + 1;
%   end
%end
