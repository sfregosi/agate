function plotGliderPath_etopo_recovery(glider, pp, path_out, path_shp, figNum)

% glider = 'sg607';
% path_shp = 'C:\Users\selene\OneDrive\projects\AFFOGATO\CatalinaComparison\profiles\matlabMapping\';
% 
latlim = [30.8 33.8];
lonlim = [-121.2 -118];

if strcmp(glider, 'sg607')
    mapFigPosition = [100    100    1200    1000];
elseif strcmp(glider, 'sg639')
    mapFigPosition = [100    700    950.5    600];
end

states = shaperead('usastatehi', 'UseGeoCoords', true, ...
    'BoundingBox', [lonlim' latlim']);

targets = readTargetsFile(glider, path_out);

%% set up figure
figure(figNum);
mapFig = gcf;
mapFig.Position = mapFigPosition;
% clear figure
clf
cla reset; clear g
ax = axesm('mercator', 'MapLatLim', latlim, 'MapLonLim', lonlim, ...
    'Frame', 'on');

%% map clean-up
gridm('PLineLocation', 1, 'MLineLocation', 1);
plabel('PLabelLocation', 1, 'PLabelRound', -1, 'FontSize', 14);
mlabel('MLabelLocation', 1, 'MLabelRound', -1, ...
    'MLabelParallel', 'south', 'FontSize', 14);
tightmap
na = northarrow('latitude', 32.9, 'longitude', -121);
scaleruler on
% showaxes
setm(handlem('scaleruler1'), 'RulerStyle', 'patches', ...
    'XLoc', 0.005, 'YLoc', 0.567, 'MajorTick', [0:50:100], ...
    'MinorTick', [0:12.5:25], 'FontSize', 14);

% geoshow(states, 'FaceColor', [0 0 0], 'EdgeColor', 'k')

%%  plot bathymetry - slow step
% [Z, refvec] = etopo('C:\Users\selene\Downloads\etopo1_bed_c_f4\etopo1_bed_c_f4.flt', 1, latlim, lonlim);
% [Z, refvec] = etopo('C:\Users\selene\Downloads\etopo1_bed_c_i2\etopo1_bed_c_i2.bin', 1, latlim, lonlim);
[Z, refvec] = etopo('C:\Users\selene\Box\HDR-SOCAL-2018\piloting\etopo1_ice_c_i2\etopo1_ice_c_i2.bin', 1, latlim, lonlim);
% all etopos are identical?

Z(Z >= 1) = NaN;
geoshow(Z, refvec, 'DisplayType', 'surface', ...
    'ZData', zeros(size(Z)), 'CData', Z);
cmap = cmocean('ice');
cmap = cmap(150:256,:);
colormap(cmap)
caxis([-6000 0])
brighten(.4);

[c,h] = contourm(Z, refvec, [-5000:1000:1000], 'LineColor', [0.6 0.6 0.6]);
[c,h] = contourm(Z, refvec, [-1000 -1000], 'LineColor', [0.6 0.6 0.6], 'LineWidth', 0.8);
[c,h] = contourm(Z, refvec, [-900:100:0], 'LineColor', [0.8 0.8 0.8]);
[c,h] = contourm(Z, refvec, [-500 -500], 'LineColor', [0.6 0.6 0.6]);

geoshow(states, 'FaceColor', [0 0 0], 'EdgeColor', 'k')


%% plot waypoints
plotm(targets.lat, targets.lon, 'Marker', 'o', 'MarkerSize', 4, 'MarkerEdgeColor', [0 0 0], ...
    'MarkerFaceColor', [0 0 0], 'Color', [0 0 0])
textm(targets.lat, targets.lon, targets.name)

% plot rPo4
plotm(33.228783, -118.251487, 'Marker', 'o', 'MarkerSize', 4, 'MarkerEdgeColor', [0 0 0], ...
    'MarkerFaceColor', [0 0 0], 'Color', [0 0 0]) 
textm(33.228783, -118.251487,'RPo4')

% % plot HARP N from Simone
% plotm(32.3696, -118.5653, 'Marker', 'o', 'MarkerSize', 4, 'MarkerEdgeColor', [0 0 0], ...
%     'MarkerFaceColor', [0 0 0], 'Color', [0 0 0]) 
% textm(32.3696, -118.5653,'HARP-N')


% plot san pedro
plotm(33.74, -118.29, 'Marker', 'p', 'MarkerSize', 4, 'MarkerEdgeColor', [1 1 1], ...
    'MarkerFaceColor', [1 1 1], 'Color', [1 1 1])

%% plot glider track

lat = [];
lon = [];
dive = [];
time = [];
per = [];
for d = 1:height(pp)
    lat = [lat; pp.startGPS{d}(1); pp.endGPS{d}(1)];
    lon = [lon; pp.startGPS{d}(2); pp.endGPS{d}(2)];
    dive = [dive; d; d;];
    time = [time; datenum(pp.diveStartTime(d)); datenum(pp.diveEndTime(d))];
    per = [per; 1, 2];  
end
plotm(lat, lon, 'LineWidth', 2, 'Color', [1 0.4 0.2])
plotm(lat, lon, '.y')
plotm(lat(end), lon(end), '+g', 'MarkerSize', 10, 'LineWidth', 2)

title(sprintf('%s - %i dives completed', glider, height(pp)))


%% Plot depth-averaged velocity vectors for each dive
scale = 5;

endLat = []; endLon = [];
for d = 1:height(pp)
    endLat = [endLat; pp.endGPS{d}(1)];
    endLon = [endLon; pp.endGPS{d}(2)];
end
quiverm(endLat(logical(~isnan(pp.dac_east))), endLon(logical(~isnan(pp.dac_east))),...
    pp.dac_north(logical(~isnan(pp.dac_east))), pp.dac_east(logical(~isnan(pp.dac_east))), ...
    'b')


end
