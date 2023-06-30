function y = strmtch1(str, strmat, str2,str3,str4,str5,str6,str7,str8,str9,...
    str10,str11,str12,str13,str14,str15,str16,str17,str18,str19,str20)
%STRMTCH1       Compare one string to a set of other strings.
%
% y = strmtch1(str,strmat)
%    Return a column vector of 1's and 0's, each element indicating whether 
%    str equals one of the rows of strmat.  Each row of strmat is effectively 
%    deblanked before the comparison; watch out that this makes
%    strmtch1('foo','foo ') return 1 instead of the expected 0.
%
% y = strmtch1(str, str1,str2,...)
%    As above, but uses lumps str1, str2, etc. into a string array first
%    (i.e., y = strmtch1(str, str2mat(str1,str2,...))).  Up to 20 strings
%    may be passed as arguments this way.
%
% See also strmatch, str2mat, deblank, find, strcmp, strncmp, strindex, 
% findstr.

n = 3;
while (n <= nargin)
  eval(['strmat = str2mat(strmat, str' num2str(n-1) ');']);
  n = n + 1;
end

if (length(str) > nCols(strmat))
  y = zeros(nRows(strmat), 1);

else
  % First pad str with blanks up to the width of strmat.
  str = [str, ' ' * ones(1, nCols(strmat) - length(str))];
  y = (ones(nRows(strmat),1) * str).' == strmat.';

  % length(str) == 1 is a special case, because all() behaves differently on it
  if (length(str) > 1)
    y = all(y);
  end
  y = y.';
end
