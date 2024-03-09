
% Print last mouse-click position.

lmpoint = get(gca, 'CurrentPoint');
lmpoint = lmpoint(1,1 : iff(lmpoint(1,3) == -1, 2, 3));
printf('%11.3f ', lmpoint);
