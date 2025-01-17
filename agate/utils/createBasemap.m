function [baseFig] = createBasemap(CONFIG, varargin)
% CREATEBASEMAP	Create a basemap of the bathymetry for the mission area
%
%   Syntax:
%       BASEFIG = CREATEBASEMAP(CONFIG, VARARGIN)
%
%   Description:
%       Function to create a basemap for a glider mission, using the lat
%       and lon limits outline in the CONFIG file. If specified, will
%       include a north arrow and scale bar. Optional to plot bathymetry
%       data (if available) otherwise will just plot land (specific to US
%       states at this time). It can be saved as a .fig file that can be
%       added to (add glider path, labels, and acoustic encounters).
%
%       Bathymetry files can be downloaded from NCEI. For more info on
%       selecting a bathymetry file visit:
%       https://sfregosi.github.io/agate/#basemap-rasters
%
%   Inputs:
%       CONFIG      [struct] mission/agate configuration variable.
%                   Required fields: CONFIG.map entries
%
%       all varargins are specified using name-value pairs
%                 e.g., 'bathy', 1, 'figNum', 12
%
%       bathy       optional argument for bathymetry plotting
%	                [double] Set to 1 to plot bathymetry or 0 to only plot
%                   land. Default is 1. Will look for bathy file in 
%                   CONFIG.map.bathyFile
%                   [char] Path to the bathymetry file (if you want to use
%                   a different one than specified in CONFIG or it is not
%                   specified in CONFIG
%       contourOn   [double] optional argument. Set to 1 to plot bathymetry
%                   contours or 0 for no contour lines. Default is on (1)
%       figNum      [double] optional to specify figure number so won't
%                   create repeated versions when updated
%
%   Outputs:
%       baseFig     [handle] figure handle
%
%   Examples:
%       % Create a basemap that includes bathymetry but no contour lines
%       baseFig = createBasemap(CONFIG, 'contourOn', 0);
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   17 January 2025
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% argument checks
narginchk(1, inf)

% set defaults/empties
bathyOn = 1;
bathyFile = [];
contourOn = 1;
figNum = [];

% parse arguments
vIdx = 1;
while vIdx <= length(varargin)
	switch varargin{vIdx}
		case 'bathy'
			if ischar(varargin{vIdx+1}) || isstring(varargin{vIdx+1})
				bathyOn = 1;
				bathyFile = varargin{vIdx+1};
			elseif isnumeric(varargin{vIdx+1})
				bathyOn = varargin{vIdx+1};
				bathyFile = [];
			end
			vIdx = vIdx+2;
		case 'contourOn'
			contourOn = varargin{vIdx+1};
			vIdx = vIdx+2;
		case 'figNum'
			figNum = varargin{vIdx+1};
			vIdx = vIdx+2;
		otherwise
			error('Incorrect argument. Check inputs.');
	end
end


%% set up the figure

if isempty(figNum)
	baseFig = figure;
else
	baseFig = figure(figNum);
end

% mapFigPosition = [100    50    800    600];
% baseFig.Position = mapFigPosition;
baseFig.Name = 'Base map';

% clear figure
clf
cla reset;
ax = axesm('mercator', 'MapLatLim', CONFIG.map.latLim, ...
	'MapLonLim', CONFIG.map.lonLim, 'Frame', 'on');

%% map clean-up
gridm('PLineLocation', 1, 'MLineLocation', 1);
plabel('PLabelLocation', 1, 'PLabelRound', -1, 'FontSize', 14);
mlabel('MLabelLocation', 1, 'MLabelRound', -1, ...
	'MLabelParallel', 'south', 'FontSize', 14);
tightmap

% add north arrow - if location specified
if isfield(CONFIG.map, 'naLat') && isfield(CONFIG.map, 'naLon')
	CONFIG.map.na = northarrow('latitude', CONFIG.map.naLat, 'longitude', ...
		CONFIG.map.naLon, 'FaceColor', [1 1 1], 'EdgeColor', [0 0 0]);
end
% add scale bar - if location and scale are specified
if isfield(CONFIG.map, 'scalePos') && isfield(CONFIG.map, 'scaleMajor') && ...
        isfield(CONFIG.map, 'scaleMinor')
    scaleruler on
    % showaxes
    setm(handlem('scaleruler1'), 'RulerStyle', 'patches', ...
        'XLoc', CONFIG.map.scalePos(1), 'YLoc', CONFIG.map.scalePos(2), ...
        'MajorTick', CONFIG.map.scaleMajor, 'MinorTick', CONFIG.map.scaleMinor, ...
        'FontSize', 14);
end

%%  plot bathymetry and/or contours - slow step

if contourOn == 1 || bathyOn == 1 % if either, load raster data

	% if not file specified, try to use CONFIG, otherwise prompt
	if isempty(bathyFile)
		if isfield(CONFIG.map, 'bathyFile')
			bathyFile = CONFIG.map.bathyFile;
		else % prompt to choose file
			[fn, path] = uigetfile(fullfile(CONFIG.path.shp, '*.tif;*.tiff'), ...
				'Select etopo raster file');
			bathyFile = fullfile(path, fn);
		end
	end
	% check that the specified one exists, otherwise prompt
	if ~exist(bathyFile, 'file')
		[fn, path] = uigetfile(fullfile(CONFIG.path.shp, '*.tif;*.tiff'), ...
			'Select etopo raster file');
		bathyFile = fullfile(path, fn);
	end

	[Z, refvec] = readgeoraster(bathyFile, 'OutputType', 'double', ...
		'CoordinateSystemType', 'geographic');
	[Z, refvec] = geocrop(Z, refvec, CONFIG.map.latLim, CONFIG.map.lonLim);

	Z(Z >= 10) = 100;

	if bathyOn == 1 % plot it

		geoshow(Z, refvec, 'DisplayType', 'surface', ...
			'ZData', zeros(size(Z)), 'CData', Z);

		cmap = cmocean('ice');
		cmap = cmap(120:210,:);
		colormap(cmap)
		% matlab renamed caxis to clim in R2022a...so try both
		try clim([-6000 0]); catch caxis([-6000 0]); end %#ok<CAXIS,SEPEX>
		brighten(.4);

		% colorbar for bathymetry is too unreliable
		% 		cb = colorbar;
		% 		cb.Location = 'eastoutside';
		% 		cb.Label.String = 'depth [m]';
		% 		cbPosit = cb.Position;
	end

	if contourOn == 1 % plot it
		[~,~] = contourm(Z, refvec, [-5000:1000:1000], 'LineColor', [0.6 0.6 0.6]); %#ok<NBRAK>
		[~,~] = contourm(Z, refvec, [-1000 -1000], 'LineColor', [0.3 0.3 0.3], ...
			'LineWidth', 0.8);
		[~,~] = contourm(Z, refvec, [-900:100:0], 'LineColor', [0.8 0.8 0.8]); %#ok<NBRAK>
		[~,~] = contourm(Z, refvec, [-500 -500], 'LineColor', [0.6 0.6 0.6]);
	end
end

%% plot land
states = shaperead('usastatehi', 'UseGeoCoords', true, ...
	'BoundingBox', [CONFIG.map.lonLim' CONFIG.map.latLim']);
geoshow(states, 'FaceColor', [0 0 0], 'EdgeColor', 'k');


% NATURAL EARTH DATA - MINOR ISLANDS PLOTTING %
% % plot land
% % try this default path
% landFile = fullfile(CONFIG.path.shp, 'NaturalEarthData', 'ne_10m_land_scale_rank.shp');
% % if that's no good, prompt for new file
% if ~exist(landFile, 'file')
%     [fn, path] = uigetfile([CONFIG.path.shp '*.shp'], 'Select ne_10m_land_scale_rank.shp');
%     landFile = fullfile(path, fn);
% end
% land = shaperead(landFile, 'BoundingBox', [CONFIG.map.lonLim' CONFIG.map.latLim'], ...
%     'UseGeoCoords', true);

% % and any minor islands if needed (e.g., for SBI)
% % try this default path
% minIslFile = fullfile(CONFIG.path.shp, 'NaturalEarthData', 'ne_10m_minor_islands.shp');
% % if that's no good, prompt for new file
% if ~exist(minIslFile, 'file')
%     [fn, path] = uigetfile([CONFIG.path_shp '*.shp'], 'Select ne_10m_minor_islands.shp');
%     minIslFile = fullfile(path, fn);
% end
% landmi = shaperead(minIslFile, 'BoundingBox', [CONFIG.map.lonLim' CONFIG.map.latLim'], ...
%     'UseGeoCoords', true);
%
% geoshow(land, 'FaceColor', [0 0 0], 'EdgeColor', 'k')
% geoshow(landmi, 'FaceColor', [0 0 0], 'EdgeColor', 'k')
%


end

