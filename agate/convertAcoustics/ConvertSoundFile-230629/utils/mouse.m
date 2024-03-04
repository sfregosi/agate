% Print out the x- and y-locations of points in the graph window
% clicked with the mouse.  Type ^C to stop mousing.
% Values are stored in the array 'mousepoints'.
% 
% If there are multiple subplots, the points are always relative to
% the last subplot painted, even if you click in a different subplot.
% Use axes(h) to change the chosen axes to handle h, or subplot(xxx) 
% to pick a subplot by number.

disp('Values will be stored in the array ''mousepoints''.');
disp('Type ^C or Command-. to stop mousing.');
disp('       x          y')

first = 1;	% allow user to ^C first time before clearing mousepoints
while 1,
  [x,y] = ginput(1);
  if (first), mousepoints = []; first = 0; end
  printf('%10g  %10g', x, y);
  mousepoints = [mousepoints; x y];
end
