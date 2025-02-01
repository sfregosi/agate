function hpol = polar(theta,rho,line_style,compass)
%POLAR	Polar coordinate plot.
%	H = POLAR(THETA, RHO) makes a plot using polar coordinates of
%	the angle THETA, in radians, versus the radius RHO.
%	If THETA and RHO are matrices, the columns are plotted.
%	The return value H has the plotted line handle(s).
%
%	H = POLAR(THETA,RHO,S) uses the linestyle specified in string S.
%	See PLOT for a description of legal linestyles.  The linestyle
%	'auto' produces the default linestyle.
%
%	H = POLAR(THETA,RHO,S,COMPASS) with a non-zero value for compass
%	produces a plot like a compass rose, with the zero angle oriented
%	upward on the page and positive THETA angles increasing clockwise.
%
%	See also PLOT, LOGLOG, SEMILOGX, SEMILOGY.

%	Copyright (c) 1984-94 by The MathWorks, Inc.

if nargin < 1
	error('Requires 2 to 4 input arguments.')
end

% This function also works if theta is omitted; it defaults to 1:length(rho).
omitted = 0;
if (nargin < 2) omitted = 1;		% was theta omitted?
elseif (isstr(rho)) omitted = 1;
end
if omitted
	% If theta is omitted, have to shift all other arguments over.
	if (nargin > 2) compass = line_style;
	else compass = 0;
	end
	if (nargin > 1) line_style = rho;
	else line_style = 'auto';
	end

	rho = theta;
	[mr,nr] = size(rho);
	if mr == 1
		theta = 1:nr;
	else
		rho = theta;
		theta = (1:mr)' * ones(1,nr);
	end
else
	if (nargin < 3) line_style = 'auto'; end
	if (nargin < 4) compass = 0; end
end
	
if compass
	theta = pi/2 - theta;
end

if isstr(theta) | isstr(rho)
	error('Input arguments must be numeric.');
end
if any(size(theta) ~= size(rho))
	error('THETA and RHO must be the same size.');
end

% get hold state
cax = newplot;
next = lower(get(cax,'NextPlot'));
hold_state = ishold;

% get x-axis text color so grid is in same color
tc = get(cax,'xcolor');

% Hold on to current Text defaults, reset them to the
% Axes' font attributes so tick marks use them.
fAngle  = get(cax, 'DefaultTextFontAngle');
fName   = get(cax, 'DefaultTextFontName');
fSize   = get(cax, 'DefaultTextFontSize');
fWeight = get(cax, 'DefaultTextFontWeight');
set(cax, 'DefaultTextFontAngle',  get(cax, 'FontAngle'), ...
	'DefaultTextFontName',   get(cax, 'FontName'), ...
	'DefaultTextFontSize',   get(cax, 'FontSize'), ...
	'DefaultTextFontWeight', get(cax, 'FontWeight') )

% only do grids if hold is off
if ~hold_state

% Make a radial grid.  First find good plot limits and tick marks.
	hold on;
	hhh=plot([0 max(theta(:))],[min(rho(:)) max(rho(:))]);
	ylims = get(cax, 'ylim');
	rmin = ylims(1);
	rmax = ylims(2);
	rticks = length(get(cax,'ytick')) - 1;
	delete(hhh);
% check radial limits and ticks -- see if we can reduce the number
	if rticks > 5
		if rem(rticks,2) == 0
			rticks = rticks/2;
		elseif rem(rticks,3) == 0
			rticks = rticks/3;
		end
	      end
	plotrmin = 0;
	plotrmax = rmax - rmin;

% define a circle
	th = 0:pi/50:2*pi;
	xunit = cos(th);
	yunit = sin(th);

% plot circles and label them
	rinc = (rmax-rmin) / rticks;
	for i= plotrmin:rinc:plotrmax
		plot(xunit*i, yunit*i, '-', 'color', tc, 'linewidth', 1);
		text(0, i+rinc/20, ['  ' num2str(i-plotrmin+rmin)], ...
		    'VerticalAlign','bottom');
	end

% plot spokes
	th = (1:6)*2*pi/12;
	if ~compass
	  cst = cos(th); snt = sin(th);
	else
	  cst = sin(th); snt = cos(th);
	end
	cs = [-cst; cst];
	sn = [-snt; snt];
	plot(plotrmax*cs, plotrmax*sn, '-', 'color', tc, 'linewidth', 1);

% annotate spokes in degrees
	rt = 1.1*plotrmax;
	for i = 1:max(size(th))
		text(rt*cst(i),rt*snt(i),int2str(i*30),'horizontalalignment','center' );
		if i == max(size(th))
			loc = int2str(0);
		else
			loc = int2str(180+i*30);
		end
		text(-rt*cst(i),-rt*snt(i),loc,'horizontalalignment','center' );
	end

% set viewto 2-D
	view(0,90);
% set axis limits
	axis(plotrmin*[-1 1 -1 1] + plotrmax*[-1 1 -1.15 1.15]);
end

% Reset defaults.
set(cax, 'DefaultTextFontAngle', fAngle , ...
	'DefaultTextFontName',   fName , ...
	'DefaultTextFontSize',   fSize, ...
	'DefaultTextFontWeight', fWeight );

% transform data to Cartesian coordinates.
xx = (rho - rmin) .* cos(theta);
yy = (rho - rmin) .* sin(theta);

% plot data on top of grid
if strcmp(line_style,'auto')
	q = plot(xx,yy);
else
	q = plot(xx,yy,line_style);
end
if nargout > 0
	hpol = q;
end
if ~hold_state
	axis('equal');axis('off');
end

% reset hold state
if ~hold_state, set(cax,'NextPlot',next); end
