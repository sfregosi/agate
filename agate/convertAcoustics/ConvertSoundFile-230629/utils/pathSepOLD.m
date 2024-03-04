function x = pathSep
% x = pathSep
% Return the character that separates directory names.
% This is : on the Mac, / on Unix, and \ on the PC.
%
% See also pathRoot, pathExt, pathFile, pathDir, filesep, fullfile.

if (version4)
  c = computer;
  if (isunix)
    x = '/';
  elseif (strcmp(c(1,3), 'MAC'))
    x = ':';
  elseif (isvms)
    x = '.';
  else
    x = '\';		% PC
  end
else
  % MathWorks finally provided one in version 5.
  x = filesep;
end
