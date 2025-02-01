function ret = uiTabs(cmd, x0, x1, x2, x3, x4)
%UITAB		Display a multiple-tab window, let user click between it.
%
% uiTab(position, labels, paintfcns [,tabsize])
%    In the current figure, display a set of tabs at the given position.
%    A "set of tabs" is a series of things that look like folders, each
%    being a rectangle with a labeled tab at the top; when the user clicks
%    on a tab, the corresponding rectangle is brought to the front.
%
%    To use this function, first paint everything in the background that
%    you want present for every tab.  This typically includes a title string
%    and buttons like "OK", "Apply", etc. at the bottom of the figure.
%    Then call uiTabs, like this:
%
%	uiTabs([left bottom width height], 'mytab1|mytab2|mytab3', paintfcns)
%
%    The first argument, a position, says where you want the tab object to
%    appear in the figure.  The next gives the names of the tabs.  The third is
%    a set of callback routines for displaying more stuff (text, uicontrols, 
%    etc.) on tabs.  Whenever each tab is first activated, the corresponding
%    paint function is executed; it should create things on the tab like
%    text, buttons, plots, etc.  The paintfcns should be in a string array
%    or a cell array.
%
%    This paintfcn callback happens only ONCE, when there are no objects
%    displayed on the tab.  At later times when the user clicks on a tab,
%    uiTabs displays the contents of that tab automatically.  It does this
%    by figuring out which objects in the figure are displayed by the
%    paintfcn.  Note that ANY objects in the figure -- not just objects on
%    the tab -- are detected this way, so if the paintfcn displays
%    something in the background area outside of a tab, it will appear and
%    disappear when different tabs are activated.  The only things that are
%    permanently in the figure are the ones that already exist when uiTabs
%    is first called.
%
%    If the POSITION argument is [], the tabs are sized to take up basically
%    all of the current figure, with a small margin around the edge.
%
%    If a final argument, tabsize, is included, it specifies the
%    relative size of the tab labels.  This is for handling tabs that
%    have some very long and some very short labels.
%
%    It is not yet possible to do multiple ranks of tabs; all of the tabs
%    are in one horizontal row.
%
%    Note that this function keeps track of what to display by determining
%    the set of visible objects when each tab is activated and deactivated.
%    It's therefore sensitive to the value of HandleVisibility for on-screen
%    objects.
%
%    Example:
%       uiTabs([], 'set parameters|run model|view results', ...
%           {'paintParameterTab', 'paintModelTab', 'paintViewTab'})

if (isnumeric(cmd) | isempty(cmd))
  pos   = cmd;			% [x0 y0 dx dy]; empty means scale to figure
  lab   = x0;			% labels, like 'Foo|Bar|Quux'
  cback = x1;			% callbacks to paint each screen
  % siz is set below, after we know n
  
  div = [0 find(lab=='|') length(lab)+1];	% divisions between labels
  n = length(div) - 1;		% number of tabs
  if (nargin >= 4)
    siz = x2;			% size of each tab
  else
    siz = ones(1,n);		% ... defaults to equal size
  end
  siz = siz / sum(siz);		% normalize to sum to 1
  tabpos = [0 cumsum(siz)];	% tab position, normalized to 1

  set(gcf, 'Units', 'pixels');
  fpos = get(gcf, 'Position');
  if (length(pos) < 4)
    pos = [10 10 fpos(3:4)-[20 20]];
  end
  x0 = pos(1);  dx = pos(3);  x1 = x0+dx;	% x0=left edge, x1=right edge
  y0 = pos(2);  dy = pos(4);  y1 = y0+dy;
  x2 = x0 + tabpos(1:n)*dx;			% left corner of tab
  x3 = x0 + tabpos(2:n+1)*dx;			% right corner of tab
  y2 = y1 - 15;					% height of tabs
  inc = 5;					% determines slant of tab

  ex = findvisible(gcf);			% existing objects to preserve
  ax = axes('Units', 'pixels', 'Pos', [0 0 fpos(3:4)], 'Visible', 'off');
  r = ones(1,n);
  polys = fill([x0*r; x0*r; x2; x2+inc; x3-inc; x3; x1*r; x1*r; x0*r], ...
               [y0*r; y2*r; y2*r; y1*r; y1*r; y2*r; y2*r; y0*r; y0*r], ...
	       [1 1 1] * 0.9, ...			% color
	       'LineWidth', 1);
  set(ax, 'XLim', [0 fpos(3)], 'YLim', [0 fpos(4)], 'Visible', 'off');
  txts = ones(n,1);
  for i = 1:n
    txts(i) = text((x2(i)+x3(i))/2, (y1+y2)/2, lab(div(i)+1 : div(i+1)-1), ...
	'HorizontalAlign', 'center', 'VerticalAlign', 'middle');
  end
  for i = 1:n
    if (iscell(cback)), cb = cback(i); else cb = cback(i,:); end
    % Set correct stacking order for tab i.
    order = [i (1:i-1) (i+1:n)];
    tabs = [txts(order); polys(order)];		% 'tabs' are polys and txts
    set(polys(i), 'UserData', struct('tabs', tabs, 'ex', ex, 'spec', [],...
	'cback', cb))
    set(txts(i),  'UserData', polys(i));

    set(polys(i), 'ButtonDown', 'uiTabs(''cback'');')
    set( txts(i), 'ButtonDown', 'uiTabs(''cback'');')
  end
  ret = [polys; txts].';
  %disp('uiTabs.m: Activating non-standard tab.')
  uiTabs('activate', polys(1), gcf);

elseif (strcmp(cmd, 'cback'))
  
  if (strcmp(get(gcbo, 'type'), 'text'))
    uiTabs('activate', get(gcbo, 'UserData'), gcbf);	% for texts
  else
    uiTabs('activate', gcbo, gcbf);				% for polys
  end
  
elseif (strcmp(cmd, 'activate'))	% activate a given poly in a given fig

  poly = x0;
  fig  = x1;
  s    = get(poly, 'UserData');		% structure for NEW poly
  ch   = get(get(poly, 'Parent'), 'Children');
  vis  = findvisible(fig);		% all visible objs -- the ones to save

  % Which objs, among axes's children, are tabs (polys or associated txts)?
  ixtab = any(ones(length(s.tabs),1) * ch.' == s.tabs * ones(1,length(ch)));

  % Which poly WAS active?  The first 'patch' in the list of tabs.
  ch1 = ch(ixtab);
  x = find(strmtch1('patch', get(ch1, 'Type')));
  oldpoly = ch1(x(1));			% this one!
  oldS = get(oldpoly, 'UserData');	% ...and its structure
  if (oldpoly == poly)			% don't need to activate current one
    return
  end
  
  % which objs from oldS are 'special', and need to be hidden?
  x = [oldS.tabs; oldS.ex];		% the COMPLEMENT of these guys
  spec = vis(~any(ones(length(x),1) * vis.' == x * ones(1,length(vis))));
  oldS.spec = spec(strmtch1('on', get(spec, 'Visible')));
  set(oldS.spec, 'Visible', 'off')
  set(oldpoly, 'UserData', oldS);
  
  ch2 = ch;
  ch2(ixtab) = s.tabs;
  set(gca, 'Children', ch2);
  if (length(s.spec))
    set(s.spec, 'Visible', 'on');
  else
    eval(s.cback);				% user callback: paint screen
  end
  
end
