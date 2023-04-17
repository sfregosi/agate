function plotGliderPathZoomed(CONFIG, pp, targetsFile, bathyFile)
% PLOTGLIDERPATHZOOMED	Plot zoomed in view of glider path on bathymetry 
%
%	Syntax:
%		PLOTGLIDERPATHZOOMED(CONFIG, PP, TARGETSFILE, BATHYFILE)
%
%	Description:
%		Zoomed in map view of the glider's most recent dive, with the most
%		recent dive in the center of the plot and the lat/lon lims based on
%		it's last surface location, showing about 20 km in all directions. 
%
%	Inputs:
%		CONFIG      Mission/agate global configuration variable
%       pp          Piloting parameters table created with
%                   extractPilotingParams.m
%       targetsFile Fullfile reference to the text file targetsFile
%       bathyFile   Optional argument to plot bathymetry (slow step),
%                   either specify the fullfile (CONFIG.map.bathyFile) or 
%                   set to 0 to not plot bathymetry
%
%	Outputs:
%		no output, creates figure
%
%	Examples:
%       plotGliderPathZoomed(CONFIG, pp639, targetsFile, CONFIG.map.bathyFile)
%	See also
%       extractPilotingParams
%   TO DO
%       - for now, this does not show patches for land/states because that
%       does not allow to reproject (not sure why but I think because there
%       isn't anything to show?
%       - does not show full extent of targets and path bc removes anything
%       that now would have data points outside the lims. Not sure I can do
%       anything about this but would like to try to fix. 
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	16 April 2023
%	Updated:        
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 4
    bathyOn = 0; % if no file specified, don't plot bathymetry
elseif ~isempty(bathyFile)
    bathyOn = 1;
end

% set fig number so you can place it in one spot on your desktop and not
% have to keep resizing, moving, etc.
figNum = CONFIG.figNumList(5);
mapFigPosition = [100    100    800    600];

% get relative map extent based on last glider surface position
% last surface position
lastLat = pp.endGPS{end}(1);
lastLon = pp.endGPS{end}(2);
newLatLim = [lastLat - 0.2 lastLat + 0.2];
newLonLim = [lastLon - 0.2 lastLon + 0.2];

states = shaperead('usastatehi', 'UseGeoCoords', true, ...
    'BoundingBox', [newLonLim' newLatLim']);

targets = readTargetsFile(targetsFile);

%% set up figure
figure(figNum);
mapFig = gcf;
mapFig.Position = mapFigPosition;
% clear figure
clf
cla reset; clear g
ax = axesm('mercator', 'MapLatLim', CONFIG.map.latLim, ...
    'MapLonLim', CONFIG.map.lonLim, 'Frame', 'on');
% ax = axesm('mercator', 'MapLatLim', newLatLim, ...
%     'MapLonLim', newLonLim, 'Frame', 'on');

%% map clean-up
gridm('PLineLocation', 1, 'MLineLocation', 1);
plabel('PLabelLocation', 1, 'PLabelRound', -1, 'FontSize', 14);
mlabel('MLabelLocation', 1, 'MLabelRound', -1, ...
    'MLabelParallel', 'south', 'FontSize', 14);
tightmap

% % add north arrow and scale bar
% CONFIG.map.na = northarrow('latitude', CONFIG.map.naLat, 'longitude', ...
%     CONFIG.map.naLon, 'FaceColor', [1 1 1], 'EdgeColor', [1 1 1]);
% scaleruler on
% % showaxes
% setm(handlem('scaleruler1'), 'RulerStyle', 'patches', ...
%     'XLoc', CONFIG.map.scalePos(1), 'YLoc', CONFIG.map.scalePos(2), ...
%     'MajorTick', CONFIG.map.scaleMajor, 'MinorTick', CONFIG.map.scaleMinor, ...
%     'FontSize', 14);

%%  plot bathymetry - slow step
%  plot bathymetry - slow step - optional
if bathyOn
    if ~exist(bathyFile, 'file')
        [fn, path] = uigetfile(fullfile(CONFIG.path.shp, '*.tif;*.tiff'), ...
            'Select etopo raster file');
        bathyFile = fullfile(path, fn);
    end
    [Z, refvec] = readgeoraster(bathyFile, 'OutputType', 'double', ...
        'CoordinateSystemType', 'geographic');
    [Z, refvec] = geocrop(Z, refvec, CONFIG.map.latLim, CONFIG.map.lonLim);

    Z(Z >= 10) = 100;
    geoshow(Z, refvec, 'DisplayType', 'surface', ...
        'ZData', zeros(size(Z)), 'CData', Z);

    cmap = cmocean('ice');
    cmap = cmap(150:256,:);
    colormap(cmap)
    clim([-6000 0])
    brighten(.4);

    [c,h] = contourm(Z, refvec, [-5000:1000:1000], 'LineColor', [0.6 0.6 0.6]);
    [c,h] = contourm(Z, refvec, [-1000 -1000], 'LineColor', [0.3 0.3 0.3], ...
        'LineWidth', 0.8);
    [c,h] = contourm(Z, refvec, [-900:100:0], 'LineColor', [0.8 0.8 0.8]);
    [c,h] = contourm(Z, refvec, [-500 -500], 'LineColor', [0.6 0.6 0.6]);
end
% geoshow(states, 'FaceColor', [0 0 0], 'EdgeColor', 'k')


%% plot waypoints
plotm(targets.lat, targets.lon, 'Marker', 'o', 'MarkerSize', 4, ...
    'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0 0 0], 'Color', [0 0 0])
textm(targets.lat, targets.lon, targets.name, 'FontSize', 10)

%% plot glider track

lat = nan(height(pp)*2,1);
lon = nan(height(pp)*2,1);
dive = nan(height(pp)*2,1);
time = nan(height(pp)*2,1);
per = nan(height(pp)*2,1);
for d = 1:height(pp)
    try
        lat((d*2-1):d*2) = [pp.startGPS{d}(1); pp.endGPS{d}(1)];
        lon((d*2-1):d*2) = [pp.startGPS{d}(2); pp.endGPS{d}(2)];
        dive((d*2-1):d*2) = [d; d];
        time((d*2-1):d*2) = [datenum(pp.diveStartTime(d)); 
            datenum(pp.diveEndTime(d))];
        per((d*2-1):d*2) = [1, 2];
    catch
        continue
    end
end
plotm(lat, lon, 'LineWidth', 2, 'Color', [1 0.4 0.2])
plotm(lat, lon, '.y')
plotm(lat(end), lon(end), '+g', 'MarkerSize', 10, 'LineWidth', 2)

title(sprintf('%s - %i dives completed', CONFIG.glider, height(pp)))
textm(lat(end), lon(end), num2str(height(pp)));

%% Plot depth-averaged velocity vectors for each dive

endLat = NaN(height(pp),1);
endLon = NaN(height(pp),1);
for d = 1:height(pp)
    try
        endLat(d) = pp.endGPS{d}(1);
        endLon(d) = pp.endGPS{d}(2);
    catch
        continue
    end
end
quiverm(endLat(logical(~isnan(pp.dac_east_cm_s))), ...
    endLon(logical(~isnan(pp.dac_east_cm_s))),...
    pp.dac_north_cm_s(logical(~isnan(pp.dac_east_cm_s))), ...
    pp.dac_east_cm_s(logical(~isnan(pp.dac_east_cm_s))), 'b')


%% zoom in

setm(ax, 'MapLatLim', newLatLim)
setm(ax, 'MapLonLim', newLonLim)
tightmap
end
