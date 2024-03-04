function h = findvisible(fig)
%FINDVISIBLE	Find all visible objects in a figure.
%
% h = findvisible(fig)
%   Find all visible objects in the given figure, which defaults to gcf.  
%   This is done by tracing the 'Children' links, so it is susceptible
%   to changes in handlevisibility.  The result, a column vector,
%   does not include fig itself.

if (nargin < 1)
  fig = gcf;
end

todo = fig;			% the to-do list; may include invisible objs
i = 1;
h = [];
while (i <= length(todo))
  new = get(todo(i), 'Children');
  todo = [todo; new];
  newvis = new(find(strmtch1('on', get(new, 'Visible'))));
  h = [h; newvis];
  i = i+1;
end
