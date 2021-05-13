% SoCal Deployment 2020 - Map Planned Tracks

% revision to planned tracks map from Workplan to switch from Arc to Matlab
% mapping

    
%% SET PATHS
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\gliderTools\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\myFunctions\'));

% glider = 'sg607';
% deploymentStr = 'SOCAL_Feb20';
% path_out = ['C:\Users\selene\Box\HDR-SOCAL-2020\maps\'];
% path_profile = ['E:\SoCal2020\profiles\' glider '\'];
path_shp = 'C:\Users\selene\OneDrive\GIS\';
path_oldMaps = 'C:\Users\selene\Box\HDR-SOCAL-2020\maps\';
path_navy = 'C:\Users\selene\Box\HDR-SOCAL-2020\maps\Exports_from_CPF_COP_SOCAL\';

% path_shp = 'C:\Users\selene\OneDrive\projects\AFFOGATO\CatalinaComparison\profiles\matlabMapping\';
% path_piloting = ['C:\Users\selene\Box\HDR-SOCAL-2020\piloting\' glider '\'];

%% SET PLOT LIMITS
latlim = [30.6 34.8];
lonlim = [-122 -116.8];


%%
figure(210);
mapFig = gcf;
mapFigPosition = [5200   -1350   900    900];
mapFig.Position = mapFigPosition;

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
na = northarrow('latitude', 34.3, 'longitude', -117, ...
    'FaceColor', [1 1 1], 'EdgeColor', [1 1 1]);
scaleruler on
% showaxes
setm(handlem('scaleruler1'), 'RulerStyle', 'patches', ...
    'XLoc', 0.02, 'YLoc', 0.563, 'MajorTick', [0:50:100], ...
    'MinorTick', [0:12.5:25], 'FontSize', 14);


%%  plot bathymetry - slow step
[Z, refvec] = etopo([path_shp 'etopo1\etopo1_ice_c_i2.bin'], 1, latlim, lonlim);

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
[CD, HD] = contourm(Z, refvec, [-6000:1000:-1000], 'LineColor', [0.6 0.6 0.6]);
% [c,h] = contourm(Z, refvec, [-900:100:100], 'LineColor', [0.8 0.8 0.8]);
% [C1,H1] = contourm(Z, refvec, [-1000 -1000], 'LineColor', [0.6 0.6 0.6], 'LineWidth', 0.8);
% [C5,H5] = contourm(Z, refvec, [-500 -500], 'LineColor', [0.6 0.6 0.6]);
% 
% "filled" contours with more discrete color bolocks
% levels = [(-5000:1000:-1000)];
% [C, h] = contourfm(Z, refvec, levels,'LineColor', repmat(0.6,1,3), 'LineWidth', 0.2);
% [C1000, h1000] = contourm(Z, refvec, -1000, 'LineColor', repmat(0.4,1,3), ...
%     'LineWidth', 0.5);

% % contour labels
% cl1 = clabelm(C1, H1, -1000, 'LabelSpacing', 1000);
% set(cl1, 'Color', repmat(0.6,1,3), 'BackgroundColor', 'none');
% cl5 = clabelm(C5, H5, -500, 'LabelSpacing', 1000);
% set(cl5, 'Color', repmat(0.6,1,3), 'BackgroundColor', 'none');
clD = clabelm(CD, HD, 'LabelSpacing', 2000);
set(clD, 'Color', repmat(0.6,1,3), 'BackgroundColor', 'none');

%% plot navy training areas
% N = shaperead([path_navy 'maritime_jurisdiction_area.shp']);


ta = shaperead([path_navy 'training_area.shp'], ...
    'BoundingBox', [lonlim' latlim'], 'UseGeoCoords', true);
h(6) = geoshow([ta.Lat],[ta.Lon], 'Color', [0.5 0.5 0.5]);

score = shaperead([path_navy 'Military_Range_Area.shp'], ...
    'BoundingBox', [lonlim' latlim'], 'UseGeoCoords', true);
h(5) = geoshow([score.Lat], [score.Lon], 'Color', 'k', 'LineWidth', 1.5);


%% plot land

land = shaperead([path_shp 'NaturalEarthData\ne_10m_land_scale_rank\ne_10m_land_scale_rank.shp'], ...
    'BoundingBox', [lonlim' latlim'], 'UseGeoCoords', true);
landmi = shaperead([path_shp 'NaturalEarthData\ne_10m_minor_islands\ne_10m_minor_islands.shp'], ...
    'BoundingBox', [lonlim' latlim'], 'UseGeoCoords', true);
% this includes SBI
% landmi.Z = repmat(100,length(landmi.Lon),1);

geoshow(land, 'FaceColor', [0 0 0], 'EdgeColor', 'k')
geoshow(landmi, 'FaceColor', [0 0 0], 'EdgeColor', 'k')



%% Plot tracks

It = shaperead([path_oldMaps 'proposedTrack_inshore.shp'], 'UseGeoCoords', true);
Ip = shaperead([path_oldMaps 'proposedPoints_inshore.shp'],  'UseGeoCoords', true);
h(1) = geoshow(It, 'DisplayType', 'line', 'Color', [1 0 0], 'LineWidth', 2 , ...
    'DisplayName', 'shelf glider');
geoshow(Ip, 'DisplayType', 'point', 'Marker', 'o', 'MarkerSize', 1, ...
    'MarkerFaceColor', [0 0 0], 'MarkerEdgeColor', [0 0 0])

Ot = shaperead([path_oldMaps 'proposedTrack_offshore.shp'], 'UseGeoCoords', true);
Op = shaperead([path_oldMaps 'proposedPoints_offshore.shp'],  'UseGeoCoords', true);
h(2) = geoshow(Ot, 'DisplayType', 'line', 'Color', [1 1 0], 'LineWidth', 2, ...
    'DisplayName', 'abyssal glider');
geoshow(Op, 'DisplayType', 'point', 'Marker', 'o', 'MarkerSize', 1, ...
    'MarkerFaceColor', [0 0 0], 'MarkerEdgeColor', [0 0 0])


%% Plot Harps
H = shaperead([path_oldMaps 'approxHARPs.shp'], 'UseGeoCoords', true);

h(3) = geoshow(H, 'DisplayType', 'point', 'Marker', 's', 'MarkerSize', 6, ...
    'MarkerFaceColor', [0 0 0], 'MarkerEdgeColor', [0 0 0], ...
    'DisplayName', 'HARP');

%% US/Mexico

% bp = inputm(5);
h(4) = plotm(bp, 'k--', 'LineWidth', 1.5); 


%% labels
legend(h, {'shelf glider', 'abyssal glider', 'HARP', 'US/Mexican waters' ...
     'SOAR', 'training area'}, ...
    'Location', 'northwest', 'FontSize', 14)

textm(H(1).Lat+0.08, H(1).Lon-0.1, 'E', 'FontSize', 14)
textm(H(2).Lat-0.08, H(2).Lon, 'U', 'FontSize', 14)
textm(H(3).Lat-0.08, H(3).Lon+0.02, 'N', 'FontSize', 14)
textm(H(4).Lat, H(4).Lon+0.04, 'H', 'FontSize', 14)

textm(30.82, -120.5, '\it{US waters}', 'Rotation', 13.5);
textm(30.89, -119.5, '\it{Mexican waters}', 'Rotation', 13.5);

%% 2 - print/save interpolated track map
set(gcf, 'InvertHardCopy', 'off', 'color', 'w');

print('C:\Users\selene\Box\HDR-SOCAL-2020\report\figures\seleneWorking\proposedTracks.png', '-dpng')
% print([path_profile 'map_' glider '_surfaceTrack.eps'], '-depsc') (not
% editable in AI...bathy is too big imports as image
export_fig('C:\Users\selene\Box\HDR-SOCAL-2020\report\figures\seleneWorking\proposedTracks.eps', '-eps', '-painters');
savefig('C:\Users\selene\Box\HDR-SOCAL-2020\report\figures\seleneWorking\proposedTracks.fig')

