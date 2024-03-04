function x = strrindex(str, sub)
% pos = STRRINDEX(str, sub)
% Returns the position of the last occurrence of sub in str.
% Returns 0 if not found.
% sub and str are usually strings (text vectors) but don't have to be.
%
% See also strindex (forward search), findstr, strcmp, strncmp, strmatch, 
% strmtch1.

n = nCols(sub)-1;
tries = find(str == sub(1));
tries = tries(find(tries <= nCols(str) - n));

for x = fliplr(tries)
  if (str(x:x+n) == sub)
    return
  end
end
x = 0;
