function fig = gettagfig(tag)
%gettagfig	Get a figure with a given tag, or create if it doesn't exist
%
% fig = gettagfig(tag)
%    Search all figures for one with the given tag.  If it exists, return it;
%    if not, create it, give it the tag, and return it.

% David.Mellinger@oregonstate.edu

h = findobj('Tag', tag);
for i = 1 : length(h)
  if (strcmp(get(h, 'Type'), 'figure'))
    fig = h;
    return
  end
end

fig = figure('Tag', tag);
