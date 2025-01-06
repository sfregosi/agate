function [z,ym] = matchvec(x, y, nbd)
%MATCHVEC	Figure out which elements of two vectors are (nearly) equal.
%
% z = matchvec(x, y)
% Given two vectors x and y, return a boolean array z such that
% z(i,j) is 1 if x(i) == y(j), and 0 otherwise.
% 
% z = matchvec(x, y, nbd)
% As above, but the equality between elements of x and y need not be
% exact; they need only be within distance nbd.
%
% [xm,ym] = matchvec(...)
% Return boolean row vectors xm, indicating which elements of x were 
% matched by some element of y, and ym, indicating which elements of y 
% were matched by some element of x.

if (nargin < 3), nbd = 0; end

z = abs((x(:) * ones(1,length(y))) - (ones(length(x),1) * y(:)')) <= nbd;

if (nargout > 1)

  % Because of any()'s behavior, have to special-case 0- and 1-element vectors.
  if (nRows(z) == 0),     ym = zeros(1,length(y));
  elseif (nRows(z) == 1), ym = any([z;z]);
  else                    ym = any(z);
  end

  if (nCols(z) == 0),     z = zeros(1,length(x));
  elseif (nCols(z) == 1), z = any([z,z]');
  else                    z = any(z');
  end

end
