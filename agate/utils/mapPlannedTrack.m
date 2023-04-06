function output = mapPlannedTrack(targetsFile, latLim, lonLim, bathyOn, figNum)
% MAPPLANNEDTRACK	Create static map of planned survey track
%
%	Syntax:
%		OUTPUT = MAPPLANNEDTRACK(INPUT)
%
%	Description:
%		Create a static map of the planned survey track from an input
%		targets file. Optional argument to plot bathymetry (requires etopo
%		raster from NCEI) and land (requires shape files from Natural Earth
%       Download etopo_2022_v1_60s_N90W180_surface.tif from NCEI:
%           https://www.ncei.noaa.gov/products/etopo-global-relief-model
%       Download Natural Earth Data (naturalearthdata.com), latest release
%       on GitHub: 
%           https://github.com/nvkelso/natural-earth-vector/releases

%           
%	Inputs:
%		targetsFile     fullpath to targets file
%       latLim          latitude limits in decimal degrees e.g., [18 23]
%       lonLim          longitude limits in decimal degrees e.g., [-160 -154]
%       bathyOn         optional arg to plot bathymetry data 1 = plot, 0 = no
%                       requires a `path_shp` in the `PREFS` variable that 
%                       points to a downloaded etopo_2022_v1_60s_N90W180_surface.tif
%                       get from NCEI: 
%       figNum          optional argument defining figure number so it
%                       doesn't keep making new figs but refreshes existing
%
%	Outputs:
%		output 	describe, please
%
%	Examples:
%
%	See also
%
%
% TO DOs:
%       - [ ] make it possible to customize the north arrow and scale info
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	22 March 2023
%	Updated:
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




% testing inputs
latLim = [18 23];
lonLim = [-160 -154];
naLat = 22.3;
naLim = -154.4;
scalePos = [-0.045 0.325]; % ['XLoc' 'YLoc']
scaleMajor = 0:50:100;
scaleMinor = 0:12.5:25;
bathyOn = 1;
path_shp = 'C:\Users\Selene.Fregosi\Documents\GIS\';
PREFS = struct;
PREFS.path_shp = path_shp;

if nargin < 5
    figNum = 210;
end


% set up figure
figure(figNum);
mapFig = gcf;
mapFigPosition = [100   50   900    700];
mapFig.Position = mapFigPosition;

% clear figure (in case previously plotted)
clf
cla reset; clear g

% build axes
ax = axesm('mercator', 'MapLatLim', latLim, 'MapLonLim', lonLim, ...
    'Frame', 'on');

gridm('PLineLocation', 1, 'MLineLocation', 1);
plabel('PLabelLocation', 1, 'PLabelRound', -1, 'FontSize', 14);
mlabel('MLabelLocation', 1, 'MLabelRound', -1, ...
    'MLabelParallel', 'south', 'FontSize', 14);
tightmap

% add north arrow and scale bar
na = northarrow('latitude', naLat, 'longitude', naLim, ...
    'FaceColor', [1 1 1], 'EdgeColor', [1 1 1]);
scaleruler on
% showaxes
setm(handlem('scaleruler1'), 'RulerStyle', 'patches', ...
    'XLoc', scalePos(1), 'YLoc', scalePos(2), 'MajorTick', scaleMajor, ...
    'MinorTick', scaleMinor, 'FontSize', 14);

%  plot bathymetry - slow step - optional
if bathyOn
    % try this default path
    bathyFile = fullfile(PREFS.path_shp, 'etopo2022', 'ETOPO_2022_v1_60s_N90W180_surface.tif');
    % if that's no good, prompt to select correct file
    if ~exist(bathyFile, 'file')
        [fn, path] = uigetfile([PREFS.path_shp '*.tif'], 'Select etop .tif file');
        bathyFile = fullfile(path, fn);
    end
    [Z, refvec] = readgeoraster(bathyFile, 'OutputType', 'double', ...
        'CoordinateSystemType', 'geographic');
    [Z, refvec] = geocrop(Z, refvec, latLim, lonLim);

    % Z(Z >= 10) = NaN;
    Z(Z >= 10) = 100;
    geoshow(Z, refvec, 'DisplayType', 'surface', ...
        'ZData', zeros(size(Z)), 'CData', Z);
    cmap = cmocean('ice');
    cmap = cmap(150:256,:);
    colormap(cmap)
    clim([-6000 100])
    brighten(.4);

    [c,h] = contourm(Z, refvec, [-5000:1000:1000], 'LineColor', [0.6 0.6 0.6]);
    [c,h] = contourm(Z, refvec, [-1000 -1000], 'LineColor', [0.6 0.6 0.6], 'LineWidth', 0.8);
    [c,h] = contourm(Z, refvec, [-900:100:0], 'LineColor', [0.8 0.8 0.8]);
    [c,h] = contourm(Z, refvec, [-500 -500], 'LineColor', [0.6 0.6 0.6]);
end

% plot land
% try this default path
landFile = fullfile(PREFS.path_shp, 'NaturalEarthData', 'ne_10m_land_scale_rank', 'ne_10m_land_scale_rank.shp');
% if that's no good, prompt for new file 
if ~exist(landFile, 'file')
    [fn, path] = uigetfile([PREFS.path_shp '*.shp'], 'Select ne_10m_land_scale_rank.shp');
    landFile = fullfile(path, fn);
end
land = shaperead(landFile, 'BoundingBox', [lonLim' latLim'], ...
    'UseGeoCoords', true);

% and any minor islands if needed (e.g., for SBI)
% try this default path
minIslFile = fullfile(PREFS.path_shp, 'NaturalEarthData', 'ne_10m_minor_islands', 'ne_10m_minor_islands.shp');
% if that's no good, prompt for new file 
if ~exist(minIslFile, 'file')
    [fn, path] = uigetfile([PREFS.path_shp '*.shp'], 'Select ne_10m_minor_islands.shp');
    minIslFile = fullfile(path, fn);
end
landmi = shaperead(minIslFile, 'BoundingBox', [lonLim' latLim'], ...
    'UseGeoCoords', true);

geoshow(land, 'FaceColor', [0 0 0], 'EdgeColor', 'k')
geoshow(landmi, 'FaceColor', [0 0 0], 'EdgeColor', 'k')



