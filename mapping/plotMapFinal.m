function plotMapFinal(glider, gpsSurfT, path_out, path_shp, path_piloting, ...
    latlim, lonlim, targetsFile)

% plot map of glider track, color coded by PAM system on or off
% plots with straightline interpolation between surface positions
% includes current vectors but those can be turned off


% INPUTS:
%   glider: glider number e.g., 'sg607'
%   gpsSurfT: load gpsSurfT matrix (table) with all surface locations
%   path_out: path to save
%   path_shp: path to etopo bathymetry file
%   path_piloting: location of piloting files - need for plotting targets
%   latlim: latitude limits for plot
%   lonlim: longitude limits for plot 
%   targetsFile: specify targetFile if you want to plot waypoints/planned
%               track

% TO DO: 
%   build default lat/lon lims from gpsSurfTable 
%   allow for legend, north arrow, labeling bathymetry, etc.
%   - for now that customization has to be pretty "manual" because it depends
%   on the survey location.
%   - allow for more interactive setting of the bathymetry extent - that
%   might vary largely by deployment area! 

% glider = 'sg607';
% 

%% set up figure
figure(202);
mapFig = gcf;
mapFigPosition = [100   100   1200    1000];
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

[c,h] = contourm(Z, refvec, [-5000:1000:1000], 'LineColor', [0.6 0.6 0.6]);
[c,h] = contourm(Z, refvec, [-1000 -1000], 'LineColor', [0.6 0.6 0.6], 'LineWidth', 0.8);
[c,h] = contourm(Z, refvec, [-900:100:0], 'LineColor', [0.8 0.8 0.8]);
[c,h] = contourm(Z, refvec, [-500 -500], 'LineColor', [0.6 0.6 0.6]);

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
plotm(targetsFile.lat, targetsFile.lon, 'Marker', 'o', 'MarkerSize', 4, 'MarkerEdgeColor', [0 0 0], ...
    'MarkerFaceColor', [0 0 0], 'Color', [0 0 0])
textm(targetsFile.lat, targetsFile.lon, targetsFile.name)

end

%% plot glider track

plotm(gpsSurfT.startLatitude, gpsSurfT.startLongitude, 'LineWidth', 2, ...
    'Color', [1 0.4 0.2])
plotm(gpsSurfT.startLatitude, gpsSurfT.startLongitude, '.y')


end
