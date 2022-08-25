function plot_gliderPath_etopo(dPARAMS, ws, pp, targetsFile)


% Inputs:
% dPARAMS       deployment parameters - glider serial, deployment string, pmcard
% pp            piloting parameters table created w extractPilotingParams.m
% PATHS         path to shape files on workstation set in setWorkstation.m
% path_bsLocal  location of locally saved basetation files
% path_status   output directory to save status plots and tables

% set fig number so you can place it in one spot on your desktop and not
% have to keep resizing, moving, etc. 
figNum = dPARAMS.figNumList(4);
mapFigPosition = [100    100    800    600];

states = shaperead('usastatehi', 'UseGeoCoords', true, ...
    'BoundingBox', [dPARAMS.lonLim' dPARAMS.latLim']);

targets = readTargetsFile(targetsFile);

%% set up figure
figure(figNum);
mapFig = gcf;
mapFig.Position = mapFigPosition;
% clear figure
clf
cla reset; clear g
ax = axesm('mercator', 'MapLatLim', dPARAMS.latLim, 'MapLonLim', dPARAMS.lonLim, ...
    'Frame', 'on');

%% map clean-up
gridm('PLineLocation', 1, 'MLineLocation', 1);
plabel('PLabelLocation', 1, 'PLabelRound', -1, 'FontSize', 14);
mlabel('MLabelLocation', 1, 'MLabelRound', -1, ...
    'MLabelParallel', 'south', 'FontSize', 14);
tightmap

% ***NEED TO MANUALLY PLACE NORTH ARROW AND SCALE BAR***
% na = northarrow('latitude', 32.9, 'longitude', -121);
% scaleruler on
% % showaxes
% setm(handlem('scaleruler1'), 'RulerStyle', 'patches', ...
%     'XLoc', 0.005, 'YLoc', 0.567, 'MajorTick', [0:50:100], ...
%     'MinorTick', [0:12.5:25], 'FontSize', 14);

% geoshow(states, 'FaceColor', [0 0 0], 'EdgeColor', 'k')

%%  plot bathymetry - slow step
[Z, refvec] = etopo([ws.path_shp 'etopo1\etopo1_ice_c_i2.bin'], 1, dPARAMS.latLim, dPARAMS.lonLim);

Z(Z >= 1) = NaN;
geoshow(Z, refvec, 'DisplayType', 'surface', ...
    'ZData', zeros(size(Z)), 'CData', Z);
cmap = cmocean('ice');
cmap = cmap(150:256,:);
colormap(cmap)
caxis([-6000 0])
brighten(.4);

[c,h] = contourm(Z, refvec, [-5000:1000:1000], 'LineColor', [0.6 0.6 0.6]);
[c,h] = contourm(Z, refvec, [-1000 -1000], 'LineColor', [0.3 0.3 0.3], 'LineWidth', 0.8);
[c,h] = contourm(Z, refvec, [-900:100:0], 'LineColor', [0.8 0.8 0.8]);
[c,h] = contourm(Z, refvec, [-500 -500], 'LineColor', [0.6 0.6 0.6]);

geoshow(states, 'FaceColor', [0 0 0], 'EdgeColor', 'k')


%% plot waypoints
plotm(targets.lat, targets.lon, 'Marker', 'o', 'MarkerSize', 4, 'MarkerEdgeColor', [0 0 0], ...
    'MarkerFaceColor', [0 0 0], 'Color', [0 0 0])
textm(targets.lat, targets.lon, targets.name, 'FontSize', 10)

%% plot any landmarks

% % plot rPo4
% plotm(33.228783, -118.251487, 'Marker', 'o', 'MarkerSize', 4, 'MarkerEdgeColor', [0 0 0], ...
%     'MarkerFaceColor', [0 0 0], 'Color', [0 0 0]) 
% textm(33.228783, -118.251487,'RPo4')
% 
% % % plot HARP N from Simone
% % plotm(32.3696, -118.5653, 'Marker', 'o', 'MarkerSize', 4, 'MarkerEdgeColor', [0 0 0], ...
% %     'MarkerFaceColor', [0 0 0], 'Color', [0 0 0]) 
% % textm(32.3696, -118.5653,'HARP-N')
% 
% 
% % plot san pedro
% plotm(33.74, -118.29, 'Marker', 'p', 'MarkerSize', 4, 'MarkerEdgeColor', [1 1 1], ...
%     'MarkerFaceColor', [1 1 1], 'Color', [1 1 1])

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
    time((d*2-1):d*2) = [datenum(pp.diveStartTime(d)); datenum(pp.diveEndTime(d))];
    per((d*2-1):d*2) = [1, 2]; 
    catch
        continue
    end
end
plotm(lat, lon, 'LineWidth', 2, 'Color', [1 0.4 0.2])
plotm(lat, lon, '.y')
plotm(lat(end), lon(end), '+g', 'MarkerSize', 10, 'LineWidth', 2)

title(sprintf('%s - %i dives completed', dPARAMS.glider, height(pp)))
textm(lat(end), lon(end), num2str(height(pp)));

%% Plot depth-averaged velocity vectors for each dive
scale = 5;

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
quiverm(endLat(logical(~isnan(pp.dac_east_cm_s))), endLon(logical(~isnan(pp.dac_east_cm_s))),...
    pp.dac_north_cm_s(logical(~isnan(pp.dac_east_cm_s))), pp.dac_east_cm_s(logical(~isnan(pp.dac_east_cm_s))), ...
    'b')


end
