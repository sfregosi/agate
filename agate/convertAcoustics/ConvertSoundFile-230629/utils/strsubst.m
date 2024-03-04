function y = strsubst(x, pat, sub)
%STRSUBST       Substitute one substring for another.
%
% y = strsubst(x, pattern, substitute)
% Substitute 'substitute' for each occurrence of 'pattern' in string x.
% Any of the strings may be empty.
%
% See also strrep.

y = x;
if (length(pat) <= length(x))
  for i = fliplr(findstr(x, pat))
    y = [y(1 : i-1), sub, y(i+length(pat) : length(y))];
  end
end
