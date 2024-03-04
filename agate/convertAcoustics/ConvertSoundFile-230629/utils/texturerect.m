function h = texturerect(rr, typ, ss, varargin)
%TEXTURERECT	Draw a striped, cross-hatched, or dotted rectangle.
%
% h = texturerect(RECT [,TYPE [,SPACING]])
%   Draw a rectangular area filled with striped lines, cross-hatches, or dots.
%   RECT specifies the boundaries of the box as [left right bottom top].
%   TYPE says what kind of texture to draw, one of
%
%        '/'	diagonal lines
%        '\'	diagonal lines leaning the other way
%        '|'	vertical lines
%        '-'	horizontal lines
%        'x'	cross-hatches (diagonal lines both ways)
%        '+'	cross-hatches (vertical and horizontal lines)
%        '.'	dots
%
%   If TYPE is missing or [], it defaults to 'x'.
%        
%   SPACING is a scalar specifying how far apart to space the elements
%   of the texture. It is in centimeters (!), and if it's missing or
%   empty, it defaults to 0.15 cm.
%   
%   The edges of the rectangle are not drawn.
%
%   Note: If the figure is resized, which can happen during printing, 
%   the x- and y-scaling will change, and the stripes/dots may no longer`
%   be perfectly diagonal.  To prevent this, first resize your figure
%   on the screen, using either the mouse or set(gcf, 'Position', ...),
%   until it's the desired size.  Then draw your figure, including any
%   texturerects.  Then do  set(gcf, 'PaperPositionMode', 'auto') to 
%   prevent further resizing.
%
%   The return value h is a vector of handles for the lines drawn.
%   You can do things like set(h, 'Color', 'b') to change the appear-
%   ance of the texture.  See below about additional arguments too.
%
%   RECT may have N rows, in which case N textured rectangles are
%   drawn.  In this case TYPE may be either a single character or 
%   a length-N string, and SPACING should have either 1 or N rows,
%   and (as always) 1 or 2 columns.
%
% h = texturerect(RECT, TYPE, SPACING, ...)
%   Additional arguments after SPACING may be used for arguments
%   that are passed to line() for controlling the appearance of the
%   texture.  Type 'set(line)' for a list of possible options.
%
%
% Examples:
%   r = [0 1 0 1];
%   r1 = [0.2 0.5 0.2 0.5];
%   texturerect(r)                         draws a cross-hatched rectangle
%   texturerect(r, '/')                    draws a diagonal-lined rectangle
%   texturerect(r, 'x', 0.1, 'Color', 'b') draws a blue cross-hatched rectangle
%   texturerect([r;r1], '+x', [0.5; 0.15]) draws two rectangles, each with
%                                          its own texture
%
% See also rectangle, patch, line.  Also, on the MathWorks website there
% is a similar function called applyhatch that makes a bitmap image of the 
% current figure and changes specified colors in the image to textures.  
% This allows you to make textures for non-rectangular areas, though the
% resulting image is at screen resolution.

% Handle missing/empty args.
if (nargin < 2),   typ = [];   end
if (nargin < 3),   ss  = [];   end
if (isempty(typ)), typ = 'x';  end
if (isempty(ss)),  ss  = 0.15; end

% Number of rectangles to draw.
N = size(rr, 1);

% Handle smaller-than-needed args.
ss  = repmat(ss(:),  ceil(N / length(ss )), 1);
typ = repmat(typ(:), ceil(N / length(typ)), 1);

unitssave = get(gca, 'Units'); 
u = [xlims ylims];
uPos = [u(1) u(3) diff(u(1:2)) diff(u(3:4))];
uSize = uPos(3:4);
set(gca, 'Units', 'centimeters'); 
cmPos = get(gca, 'Pos'); 
cmSize = cmPos(3:4);
set(gca, 'Units', unitssave);

h = {};
for i = 1 : N
  r = rr(i,:);
  s = ss(i);
  t = typ(i);
  
  % Do everything in centimeter units, then convert back to data units later.
  % Set up r with the relevant transform info, s1 with the scaling factor.
  r = [((r(1:2) - uPos(1)) ./ uSize(1) .* cmSize(1)) ...
       ((r(3:4) - uPos(2)) ./ uSize(2) .* cmSize(2))];
  xsize = abs(r(2) - r(1));
  ysize = abs(r(4) - r(3));

  % s1 is bigger by sqrt(2) for diagonal patterns.
  if (t == '/' | t == '\' | t == 'x') s1 = s * sqrt(2);
  else s1 = s;
  end
  d = s1/2 : s1 : xsize+ysize;		% distance along perimeter of line-ends
  d1x = d(d <  xsize);
  d2x = d(d >= xsize) - xsize;
  d1y = d(d <  ysize);
  d2y = d(d >= ysize) - ysize;
  lnX = [];  lnY = [];			% line endpoints, accumulated
  
  % First the diagonals.
  if (t == '\' | t == 'x')
    lnX = [lnX [r(1)+d1x repmat(r(2),1,length(d2x));    % right then up
	        repmat(r(1),1,length(d1y)) r(1)+d2y]];  % up then right
    lnY = [lnY [repmat(r(3),1,length(d1x)) r(3)+d2x;    % right then up
	        r(3)+d1y repmat(r(4),1,length(d2y))]];  % up then right
  end
  if (t == '/' | t == 'x' | t == 'X')
    lnX = [lnX [r(1)+d1x repmat(r(2),1,length(d2x));    % right then down
	        repmat(r(1),1,length(d1y)) r(1)+d2y]];  % down then right
    lnY = [lnY [repmat(r(4),1,length(d1x)) r(4)-d2x;    % right then down
	        r(4)-d1y repmat(r(3),1,length(d2y))]];  % down then right
  end
  
  % Next the horizontals and verticals.
  if (t == '-' | t == '+')
    lnX = [lnX repmat(r(1:2).', 1, length(d1y))];
    lnY = [lnY [r(3)+d1y; r(3)+d1y]];
  end
  if (t == '|' | t == '+')
    lnX = [lnX [r(1)+d1x; r(1)+d1x]];
    lnY = [lnY repmat(r(3:4).', 1, length(d1x))];
  end
  
  % Finally dots.  Make two grids of them, offset by s1/2 in x and y.
  if (t == '.')
    ix = r(1)+s1/4 : s1 : r(2);        ix1 = r(1)+s1*3/4 : s1 : r(2);
    iy = r(3)+s1/4 : s1 : r(4);        iy1 = r(3)+s1*3/4 : s1 : r(4);
    [ptsX,ptsY] = meshgrid(ix, iy.');  [ptsX1,ptsY1] = meshgrid(ix1, iy1.');  
    lnX = [lnX; ptsX(:); ptsX1(:)];
    lnY = [lnY; ptsY(:); ptsY1(:)];
  end
  
  % Convert back to data units.
  lnX = lnX / cmSize(1) * uSize(1) + uPos(1);
  lnY = lnY / cmSize(2) * uSize(2) + uPos(2);

  % Draw it!
  if (t == '.')
    hNew = line(lnX, lnY, 'Color', 'k', 'Marker', '.', 'MarkerSize', 1, ...
	'LineStyle', 'none', varargin{:});
  else
    hNew = line(lnX, lnY, 'Color', 'k', varargin{:});
  end

  if (N > 1), h = {h{:}; hNew};
  else        h = hNew;
  end
end
