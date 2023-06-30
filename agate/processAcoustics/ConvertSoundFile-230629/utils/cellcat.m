function x = cellcat(varargin)
%CELLCAT	Concatenate cell arrays.
%
% x = cellcat(x, y, z)
%   Concatenate the cell arrays x, y, and z together into a single cell array.
%   Works only along rows (dimension 2).  There can be any number of
%   arguments, not only 3 as shown here.
%
%   For instance,
%       cellcat(0, {1 2 3}, {4 {5} 'abc'}, [7 8])  
%   is the same as
%       {0 1 2 3 4 {5} 'abc' [7 8]}
%
% See also cat, [], {}.
%
% Dave Mellinger  3/00
% David.Mellinger@oregonstate.edu

n = 0;
for i = 1:nargin
  n = n + iff(iscell(varargin{i}), length(varargin{i}), 1);
end

x = cell(1, n);
p = 1;
for i = 1:nargin
  y = varargin{i};
  if (length(y) > 0)
    if (iscell(y)) 
      [x{p : p+length(y)-1}] = deal(y{:});
      p = p + length(y);
    else
      x{p} = y;
      p = p + 1;
    end
  end
end
