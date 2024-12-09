function mprintf(fmt, varargin)
%MPRINTF	Like printf, but prefix the output with caller's m-file name
%
% mprintf(format_string, ...)
%   Print out the given format string and any arguments just like printf
%   or disp(sprintf(...)), but prefix it with 'foo: ' where foo is the name
%   of the calling m-file.  (If there are subfunctions in the file, these are
%   not shown, just the file name.)
%
% See also printf, sprintf, fprintf, error.

st = dbstack;
fprintf(1, '%s: ', pathRoot(st(2).file));  % fprintf doesn't print a newline
disp(sprintf(fmt, varargin{:}))		   % pass the rest off to sprintf
