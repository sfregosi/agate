function plotCalculatedTrack_PAM(glider, locCalcT, path_shp, latlim, lonlim, targetsFile)

% plot map of glider track
% plots with dead reckoned/calculated track (from the hydrodynamic model)
% could add ability to toggle to the glide slope model in the future. 


% INPUTS:
%   glider: glider number e.g., 'sg607' for making title
%   locCalcT: load locCalcT matrix (table) with all calculated locations
%   path_shp: path to etopo bathymetry file
%   latlim: latitude limits for plot
%   lonlim: longitude limits for plot
%   targetsFile: specify targetFile if you want to plot waypoints/planned
%               track

% TO DO:
%   build default lat/lon lims from locCalcT if not specified
%   allow for legend, north arrow, labeling bathymetry, to be moved etc.
%   - for now that customization has to be pretty "manual" because it depends
%   on the survey location.
%   - allow for more interactive setting of the bathymetry extent - that
%   might vary largely by deployment area!

% glider = 'sg607';
%

if nargin < 6
    targetsFile = [];
end

%% set up figure
figure(204);
% mapFig = gcf;
% mapFigPosition = [5200   -1350   1200    900];
% mapFig.Position = mapFigPosition;

%% map clean-up
% clear figure (in case previously plotted)
clf
cla reset; clear g
ax = axesm('mercator', 'MapLatLim', latlim, 'MapLonLim', lonlim, ...
    'Frame', 'on');

gridm('PLineLocation', 1, 'MLineLocation', 1);
plabel('PLabelLocation', 1, 'PLabelRound', -1, 'FontSize', 14);
mlabel('MLabelLocation', 1, 'MLabelRound', -1, ...
    'MLabelParallel', 'south', 'FontSize', 14);
tightmap
na = northarrow('latitude', 33.4, 'longitude', -121);
scaleruler on
% showaxes
setm(handlem('scaleruler1'), 'RulerStyle', 'patches', ...
    'XLoc', 0.005, 'YLoc', 0.567, 'MajorTick', [0:50:100], ...
    'MinorTick', [0:12.5:25], 'FontSize', 14);


%%  plot bathymetry - slow step
[Z, refvec] = etopo([path_shp 'etopo1_ice_c_i2\etopo1_ice_c_i2.bin'], 1, latlim, lonlim);

% Z(Z >= 10) = NaN;
Z(Z >= 10) = 100;
geoshow(Z, refvec, 'DisplayType', 'surface', ...
    'ZData', zeros(size(Z)), 'CData', Z);
cmap = cmocean('ice');
cmap = cmap(150:256,:);
colormap(cmap)
caxis([-6000 100])
brighten(.4);

% 
[c,h] = contourm(Z, refvec, [-5000:1000:-1000], 'LineColor', [0.6 0.6 0.6]);
[c,h] = contourm(Z, refvec, [-900:100:100], 'LineColor', [0.8 0.8 0.8]);
[C1,H1] = contourm(Z, refvec, [-1000 -1000], 'LineColor', [0.6 0.6 0.6], 'LineWidth', 0.8);
[C5,H5] = contourm(Z, refvec, [-500 -500], 'LineColor', [0.6 0.6 0.6]);

% "filled" contours with more discrete color bolocks
% levels = [(-5000:1000:-1000)];
% [C, h] = contourfm(Z, refvec, levels,'LineColor', repmat(0.6,1,3), 'LineWidth', 0.2);
% [C1000, h1000] = contourm(Z, refvec, -1000, 'LineColor', repmat(0.4,1,3), ...
%     'LineWidth', 0.5);

% contour labels
cl1 = clabelm(C1, H1, -1000, 'LabelSpacing', 1000);
set(cl1, 'Color', repmat(0.6,1,3), 'BackgroundColor', 'none');
cl5 = clabelm(C5, H5, -500, 'LabelSpacing', 1000);
set(cl5, 'Color', repmat(0.6,1,3), 'BackgroundColor', 'none');



%% plot land

land = shaperead([path_shp 'NaturalEarthData\ne_10m_land_scale_rank\ne_10m_land_scale_rank.shp'], ...
    'BoundingBox', [lonlim' latlim'], 'UseGeoCoords', true);
landmi = shaperead([path_shp 'NaturalEarthData\ne_10m_minor_islands\ne_10m_minor_islands.shp'], ...
    'BoundingBox', [lonlim' latlim'], 'UseGeoCoords', true);
% this includes SBI
% landmi.Z = repmat(100,length(landmi.Lon),1);

geoshow(land, 'FaceColor', [0 0 0], 'EdgeColor', 'k')
geoshow(landmi, 'FaceColor', [0 0 0], 'EdgeColor', 'k')


%% plot waypoints
if ~isempty(targetsFile)
    plotm(targetsFile.lat, targetsFile.lon, 'Marker', '^', 'MarkerSize', 6, ...
        'MarkerEdgeColor', [0.3 0.3 0.3], 'MarkerFaceColor', [0.3 0.3 0.3], ...
        'Color', [0.3 0.3 0.3])
    textm(targetsFile.lat, targetsFile.lon + 0.02, targetsFile.name, 'Color', [0.3 0.3 0.3])
end

%% plot glider track

plotm(locCalcT.latitude, locCalcT.longitude, 'LineWidth', 2, ...
    'Color', [1 0.4 0.2])

% plotm(locCalcT.latitude_gsm, locCalcT.longitude_gsm, 'LineWidth', 2, ...
%     'Color', 'y')
% canc heck GSM model to see if they are vastly different?

% first pt for each dive as a dot
diveNums = unique(locCalcT.dive);
surfPts = [];
for f = 1:length(diveNums)
    surfPts(f) = find(locCalcT.dive == diveNums(f), 1, 'first');
end
scatterm(locCalcT.latitude(surfPts), locCalcT.longitude(surfPts), 4, ...
    'Marker', 'o', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0 0 0])

%% basic title (glider name)
title(glider, 'FontSize', 18)


end
