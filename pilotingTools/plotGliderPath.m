function plotGliderPath(glider, pp, path_out, path_shp)

% glider = 'sg607';
% path_shp = 'C:\Users\selene\OneDrive\projects\AFFOGATO\CatalinaComparison\profiles\matlabMapping\';
% 
latlim = [30.8 33.2];
lonlim = [-121.2 -118];

mapFigPosition = [100    100    950.5    600];
states = shaperead('usastatehi', 'UseGeoCoords', true, ...
    'BoundingBox', [lonlim' latlim']);

targets = readTargetsFile(glider, path_out);

%% set up figure
figure(202);
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


%% load existing shape files
[B,R] = geotiffread([path_shp 'Clip_crm_socal_3as_v22_bathy001.tif']);
B = double(B);
B(B >= 0) = 10;
B(B < 0 & B >= -100 )      = -100;
B(B < -100 & B >= -200)    = -200;
B(B < -200 & B >= -500)    = -500;
B(B < -500 & B >= -1000)   = -1000;
B(B < -1000 & B >= -1500)  = -1500;
B(B < -1500 & B >= -2000)  = -2000;
B(B < -2000 & B >= -3000)  = -3000;
B(B < -3000 & B >= -4000)  = -4000;
B(B < -4000 & B >= -5000)  = -5000;
B(B < -5000)                = -6000;



%%  plot bathymetry - slow step
% [c,h] = contourm(B,R,-5000:500:100, 'LineColor', [0.8 0.8 0.8]);
% t = clabelm(c,h);
% % set(t,'Fontsize',14)
% set(t,'Color',[0.8 0.8 0.8])
% set(t,'BackgroundColor','none')
% % set(t,'FontWeight','bold')

geoshow(B, R, 'DisplayType', 'contour', ...
     'Fill', 'on')

cmap = cmocean('ice');
cmap = cmap(150:256,:);
colormap(cmap)
cmap = [cmap; 0.2 0.2 0.2];
colormap(cmap)
caxis([-6000 10])
brighten(.4);

% geoshow(states, 'FaceColor', [0 0 0], 'EdgeColor', 'k')

%% plot waypoints
plotm(targets.lat, targets.lon, 'Marker', 'o', 'MarkerSize', 4, 'MarkerEdgeColor', [0 0 0], ...
    'MarkerFaceColor', [0 0 0], 'Color', [0 0 0])
textm(targets.lat, targets.lon, targets.name)

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

% % turn points into shapefile
% shpBaseName = [path_out 'diveSurfaceLocations'];
% [sgPoints(1:height(pp)*2).Geometry] = deal('Point');
% 
% latCell = num2cell(lat);
% lonCell = num2cell(lon);
% diveCell = num2cell(dive);
% timeCell = num2cell(time); 
% perCell = num2cell(per);
% 
% [sgPoints(:).Lat] = latCell{:};
% [sgPoints(:).Lon] = lonCell{:};
% [sgPoints(:).Dive] = diveCell{:};
% [sgPoints(:).Time] = timeCell{:};
% [sgPoints(:).Per] = perCell{:};
% 
% shapewrite(sgPoints, shpBaseName);
% 
% geoshow(sgPoints, 'Color', 'black')

% % now make SG tracklines shape file (plot faster, get lengths, durations,
% % etc)
% % first split the bits up
% [ty, tx] = polysplit(t.latitude, t.longitude);
% t.min(isnan(t.dive)) = NaT;
% t.dn = datenum(t.min);
% [~, tm] = polysplit(t.dive, t.dn);
% 
% % specify as line, length of split bits
% [SGTrks(1:length(ty)).Geometry] = deal('Line');
% [SGTrks(:).Lat] = ty{:};
% [SGTrks(:).Lon] = tx{:};
% tmpDive = num2cell([1:76]');
% [SGTrks(:).Name] = tmpDive{:};
% [SGTrks(:).Dive] = tmpDive{:};
% 
% for f = 1:length(ty)
%     len_km = deg2km(distance(SGTrks(f).Lat(1), SGTrks(f).Lon(1), ...
%         SGTrks(f).Lat(end), SGTrks(f).Lon(end)));
%     SGTrks(f).Length_km = len_km;
%     dur_min = ((tm{f}(end) - tm{f}(1))*86400 + 60)/(60); % in MINUTES
%     SGTrks(f).Dur_min = dur_min;
%     SGTrks(f).StartTime = datestr(tm{f}(1));
%     SGTrks(f).EndTime = datestr(tm{f}(end));
% end
% shpBaseName = [path_profiles 'matlabMapping\SG607Tracks'];
% shapewrite(SGTrks, shpBaseName);

title(sprintf('%s - %i dives completed', glider, height(pp)))

end
