function x = strindex(str, sub)
% pos = STRINDEX(str, sub)
% Returns the position of the first occurrence of sub in str.
% Returns 0 if not found.
% sub and str are usually strings (text vectors) but don't have to be.
%
% See also strrindex (reverse search), findstr, strcmp, strncmp, strmatch, 
% strmtch1.

n = nCols(sub)-1;
tries = find(str == sub(1));
tries = tries(tries <= nCols(str) - n);

for x = tries
  if (str(x:x+n) == sub)
    return
  end
end
x = 0;
