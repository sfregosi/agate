function y = powerset(x)
%POWERSET	Generate all subsets of a given set.
%
% y = powerset(x)
%    Given a vector x, return a cell array y consisting of all possible
%    subsets of x.  There are 2^length(x) of them.  The uniqueness of 
%    x's elements is not checked; use unique() to do that.
%
% Examples:
%   powerset([1 2]) ==> {[] [1] [2] [1 2]}
%   powerset('abc') ==> {'' 'a' 'b' 'ab' 'c' 'ac' 'bc' 'abc'}
%
% See also ISMEMBER, UNIQUE.
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu
% 2 Mar 2004

n = length(x(:));
indices = false(1, n);
y = cell(1, 2^n);
for yI = 1 : 2^n-1
  y{yI} = x(indices);

  % Flip all leading 1's in 'indices', as well as the first 0.
  i = 1;
  while (1)
    if (indices(i)), indices(i) = false; i = i + 1;	% a leading 1
    else indices(i) = true; break; 			% the first 0
    end
  end
end
y{2^n} = x;		% doing this means we don't have to test i>n in loop






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Two alternative implementations (17-22x slower, but much cleaner):
%n = length(x(:));
%y = cell(1, 2^n);
%for yI = 0 : 2^n-1
  % Choose one:
  %y{yI+1} = x(logical(fliplr(encode(yI, 2, n))));	% 22x slower
  %y{yI+1} = x(fliplr(dec2bin(yI, n) == '1'));		% 17x slower
%end
