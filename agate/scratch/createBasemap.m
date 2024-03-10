function output = createBasemap(CONFIG, figNum, outFig)
% CREATEBASEMAP	Create a basemap of the bathymetry for the mission area
%
%   Syntax:
%       OUTPUT = CREATEBASEMAP(CONFIG, OUTFIG)
%
%   Description:
%       Detailed description here, please
%   Inputs:
%       input   describe, please
%
%	Outputs:
%       CONFIG      [struct] mission/agate global configuration variable.
%                   Required fields: CONFIG.map entries
%       figNum      [double] optional to specify figure number so won't
%                   create repeated versions when updated
%       outFig      [string] optional argument to save the .fig
%
%   Examples:
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   09 March 2024
%   Updated:
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%
% for testing
figNum = 82;
outFig = [];
%%%%%%%%%%%%%%

if nargin < 3
	outFig = [];
end

if nargin < 2
	figNum = [];
end

if isempty(figNum)
	baseFig = figure;
else
	baseFig = figure(figNum);
end

mapFigPosition = [100    100    800    600];
baseFig.Position = mapFigPosition;

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

% if specified in CONFIG, place north arrow and scale bar
if isfield(CONFIG.map, 'naLat') && isfield(CONFIG.map, 'naLon')
	na = northarrow('latitude', CONFIG.map.naLat, 'longitude', CONFIG.map.naLon);
end
if isfield(CONFIG.map, 'scalePos')
	scaleruler on
	setm(handlem('scaleruler1'), 'RulerStyle', 'patches', 'FontSize', 14, ...
		'XLoc', CONFIG.map.scalePos(1), 'YLoc', CONFIG.map.scalePos(2))

	if isfield(CONFIG.map, 'scaleMajor') && isfield(CONFIG.map, 'scaleMinor')
		setm(hamdlem('scaleruler1'), 'MajorTick', [0:50:100], 'MinorTick', [0:12.5:25]);
	end
	% setm(handlem('scaleruler1'), 'RulerStyle', 'patches', ...
	%     'XLoc', 0.005, 'YLoc', 0.567, 'MajorTick', [0:50:100], ...
	%     'MinorTick', [0:12.5:25], 'FontSize', 14);
end
% ***NEED TO MANUALLY PLACE NORTH ARROW AND SCALE BAR***
% na = northarrow('latitude', 32.9, 'longitude', -121);
% scaleruler on
% % showaxes
% setm(handlem('scaleruler1'), 'RulerStyle', 'patches', ...
%     'XLoc', 0.005, 'YLoc', 0.567, 'MajorTick', [0:50:100], ...
%     'MinorTick', [0:12.5:25], 'FontSize', 14);

%%  plot bathymetry - slow step
% read in raster data

% if no bathyFile specified, used etopo
if isempty(bathyFile)
	% [Z, refvec] = etopo([ws.path_shp 'etopo1\etopo1_ice_c_i2.bin'], 1, dPARAMS.latLim, dPARAMS.lonLim);
else
	[Z, refvec] = readgeoraster(bathyFile);
	Z = double(Z); % make sure its double type for later
end

% try making smaller to speed up plotting later.
[resizedZ, resizedRefvec] = georesize(Z, refvec, 0.5);
Z = resizedZ; refvec = resizedRefvec;

% display raster data
Z(Z >= 10) = NaN; % "flatten" away the land for the color scaling
geoshow(Z, refvec, 'DisplayType', 'surface', 'ZData', zeros(size(Z)), ...
	'CData', Z);
cmap = cmocean('ice');
cmap = cmap(150:256,:);
colormap(cmap)
caxis([-6000 0])
brighten(.4);

states = shaperead('usastatehi', 'UseGeoCoords', true, ...
	'BoundingBox', [dPARAMS.lonLim' dPARAMS.latLim']);
geoshow(states, 'FaceColor', [0 0 0], 'EdgeColor', 'k');


% load and display contours
c_gt_1000 = shaperead(fullfile(shpFolder, 'contour_gt_1000m'), 'UseGeoCoords', true);
geoshow(c_gt_1000, 'Color', repmat(0.6, 3, 1));
c_lt_900 =  shaperead(fullfile(shpFolder, 'contour_lt_900m'), 'UseGeoCoords', true);
geoshow(c_lt_900, 'Color', repmat(0.8, 3, 1));
c_500 =     shaperead(fullfile(shpFolder, 'contour_500m'), 'UseGeoCoords', true);
geoshow(c_500, 'Color', repmat(0.6, 3, 1));
c_1000 =    shaperead(fullfile(shpFolder, 'contour_1000m'), 'UseGeoCoords', true);
geoshow(c_1000, 'Color', repmat(0.3, 3, 1), 'LineWidth', 0.8);

contours = struct('c_gt_1000', c_gt_1000, 'c_lt_900', c_lt_900, ...
	'c_500', c_500, 'c_1000', c_1000);

%% to create the contour lines and save as shapefiles WITHIN matlab
% [c,h] = contourm(Z, refvec, [-5000:1000:1000], 'LineColor', [0.6 0.6 0.6]);
% [c,h] = contourm(Z, refvec, [-1000 -1000], 'LineColor', [0.3 0.3 0.3], 'LineWidth', 0.8);
% [c,h] = contourm(Z, refvec, [-900:100:0], 'LineColor', [0.8 0.8 0.8]);
% [c,h] = contourm(Z, refvec, [-500 -500], 'LineColor', [0.6 0.6 0.6]);
%
% % from file exchange - reshape contours into different pieces
% [x,y,z] = C2xyz(c);
% % save as shp structure
% shp = struct('Geometry', 'Line', 'Lon', x, 'Lat', y, 'Z', num2cell(z));
% % then plot with geoshow


%% save as .fig
savefig(outFig);

end

