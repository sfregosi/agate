function z = uiMultiText(x, y, z, q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,q13,q14,q15,q16,q17,q18,q19,q20,q21,q22,q23,q24)

%uiMultiText Add multi-line text to the current plot.
%
% As of MATLAB version 5, this function is almost obsolete.  Just 
% use text(...) with multiple rows in the string.
%
% t = uiMultiText(x, y, 'string')
%    This is just like the call text(x,y,'string'), except that the text
%    string may contain multiple rows, or newlines (character value 10), to 
%    cause multiple text objects to display on successive lines.  The text
%    objects are returned.
%
%    If the string starts with '-', it is displayed with the bottom line
%    (instead of the usual top line) at the location specified.
%
% t = uiMultiText(x, y, z, 'string')
%    Use this form for three-dimensional plots.
%
% t = uiMultiText(x, y, [z,] 'string', spacing)
%    As above, but display successive lines at the given spacing instead
%    of the default, which is calculated from the font size.  This spacing
%    is measured in pixels, not native (axes) units.  As a special case,
%    if  -10 < spacing <= 0,  it is used as an increment added to the default.
%
% t = uiMultiText(...args..., 'FontName', 'Times', 'Units', 'pixels', ...)
%    The arguments described above may be followed by name/value pairs
%    to set FontName, FontSize, Units, VerticalAlignment, and so on
%    for the text string.  Do 'get(text)' to see them all.  Setting the
%    'Position' argument this way does NOT work; you must use x and y.
%
% Dave Mellinger, David.Mellinger@oregonstate.edu.  This version 12/31/97.

sep = 10;			% separator charater for successive lines
if (isstr(z)),
  dims = 2;
  str = z;
else
  dims = 3;
  str = q1;
end

arg = dims - 1;			% number of first q arg to use
spacing = 0;
if (nargin-dims > 1), if (~isstr(eval(['q',num2str(arg)]))), 
  spacing = eval(['q',num2str(arg)]); 
  arg = arg + 1;
end; end

sgn = -1;
if (length(str) > 0)
  if (str(1) == '-')
    sgn = 1;
    % strip the '-' character
    if (nRows(str) > 1)
      str(1,:) = [str(1,2:nCols(str)) ' '];
    else
      str = str(2:length(str));
    end
  end
end

z = [];
offset = 0;
r1 = 1:nRows(str);
if (sgn > 0), r1 = fliplr(r1); end
for r = r1
  st = str(r,:);
  if (nRows(str) > 1), st = deblank(st); end
  div = [0, find([st,sep] == sep)];
  idx = 1 : length(div)-1;
  if (sgn > 0), idx = fliplr(idx); end

  for i = idx
    s = st(div(i)+1 : div(i+1)-1);		% needed for MATLAB crash bug
    if (length(s))
      t = text('String', s);
    else 
      t = text('String',''); 
    end
    z = [z, t];
    for j = arg:2:nargin-4	% do before getting extent or setting position
      eval(sprintf('set(t, q%d, q%d);', j, j+1));
    end
    if (dims == 2), set(t, 'Position', [x y]);
    else set(t, 'Position', [x y z]);
    end
    unitsSave = get(t, 'Units'); set(t, 'Units', 'pixels')
    if (i == idx(1) & spacing <= 0 & spacing > -10)
      ext = get(z(1),'Extent');
      spacing = spacing + ext(4);
    end
    pos = get(t, 'position');
    set(t, 'Position', [pos(1) pos(2)+offset pos(3:length(pos))]);
    set(t,'Units',unitsSave);
    offset = offset + spacing * sgn;
  end
end

if (sgn > 0), z = fliplr(z); end
