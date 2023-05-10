% WORKFLOW_PLOTACOUSTICDETECTIONS
%	One-line description here, please
%
%	Description:
%		Detailed description here, please
%
%	Notes
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	23 April 2023
%	Updated:
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize agate
agate agate_config_sg639_MHI_Apr2022.cnf
global CONFIG

species = 'UO';
% specify an analysis folder for outputs...This needs improvement
path_out = 'C:\Users\Selene.Fregosi\Documents\GitHub\glider-MHI\analysis\';
path_profile = fullfile(CONFIG.path.mission, 'profiles');

% read in the triton log file
% tt = readtable(fullfile(path_out, 'fkw', [CONFIG.glider '_' CONFIG.mission '_log_merged.csv']));
load(fullfile(path_out, 'fkw', [CONFIG.glider '_' CONFIG.mission '_log_merged.mat']))
% read in the glider surface positions
load(fullfile(path_profile, [CONFIG.glider CONFIG.mission '_gpsSurfaceTable.mat']))


%% set up figure
% set fig number so you can place it in one spot on your desktop and not
% have to keep resizing, moving, etc.
mapFigPosition = [100    100    800    600];

states = shaperead('usastatehi', 'UseGeoCoords', true, ...
    'BoundingBox', [CONFIG.map.lonLim' CONFIG.map.latLim']);
% targets = readTargetsFile(targetsFile);


figure(132);
mapFig = gcf;
mapFig.Position = mapFigPosition;
% clear figure
clf
cla reset; clear g
ax = axesm('mercator', 'MapLatLim', CONFIG.map.latLim, ...
    'MapLonLim', CONFIG.map.lonLim, 'Frame', 'on');

%% map clean-up
gridm('PLineLocation', 1, 'MLineLocation', 1);
plabel('PLabelLocation', 1, 'PLabelRound', -1, 'FontSize', 14);
mlabel('MLabelLocation', 1, 'MLabelRound', -1, ...
    'MLabelParallel', 'south', 'FontSize', 14);
tightmap

% add north arrow and scale bar
CONFIG.map.na = northarrow('latitude', CONFIG.map.naLat, 'longitude', ...
    CONFIG.map.naLon, 'FaceColor', [1 1 1], 'EdgeColor', [1 1 1]);
scaleruler on
% showaxes
setm(handlem('scaleruler1'), 'RulerStyle', 'patches', ...
    'XLoc', CONFIG.map.scalePos(1), 'YLoc', CONFIG.map.scalePos(2), ...
    'MajorTick', CONFIG.map.scaleMajor, 'MinorTick', CONFIG.map.scaleMinor, ...
    'FontSize', 14);

%%  plot bathymetry - slow step
%  plot bathymetry - slow step - optional
bathyFile = CONFIG.map.bathyFile;
% if bathyOn
    % try the specified file
%     bathyFile = fullfile(CONFIG.path.shp, 'etopo2022', ...
%         'ETOPO_2022_v1_60s_N90W180_surface.tif');
    % if that's no good, prompt to select correct file
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
% end
geoshow(states, 'FaceColor', [0 0 0], 'EdgeColor', 'k')

%% plot glider track
lat = nan(height(gpsSurfT)*2,1);
lon = nan(height(gpsSurfT)*2,1);
dive = nan(height(gpsSurfT)*2,1);
time = nan(height(gpsSurfT)*2,1);
per = nan(height(gpsSurfT)*2,1);
for d = 1:height(gpsSurfT)
    try
        lat((d*2-1):d*2) = [gpsSurfT.startLatitude(d); gpsSurfT.endLatitude(d)];
        lon((d*2-1):d*2) = [gpsSurfT.startLongitude(d); gpsSurfT.endLongitude(d)];
        dive((d*2-1):d*2) = [d; d];
        time((d*2-1):d*2) = [datenum(gpsSurfT.startDateTime(d)); 
            datenum(gpsSurfT.endDateTime(d))];
        per((d*2-1):d*2) = [1, 2];
    catch
        continue
    end
end
plotm(lat, lon, 'LineWidth', 2, 'Color', [0.2 0.2 0.2])



%% get location of glider for each encounter
for f = 1:height(tlm)
   diveIdx = find(isbetween(tlm.start(f), gpsSurfT.startDateTime, gpsSurfT.endDateTime));
   tlm.diveNum(f) = diveIdx;
   tlm.lat(f) = gpsSurfT.startLatitude(diveIdx);
   tlm.lon(f) = gpsSurfT.startLongitude(diveIdx);
end

scatterm(tlm.lat, tlm.lon, 75, [1 0.4 0.2], 'filled', 'MarkerEdgeColor', [0 0 0])

%% now add in SG680
agate agate_config_sg680_MHI_Apr2022.cnf
global CONFIG

path_profile = fullfile(CONFIG.path.mission, 'profiles');

% read in the triton log file
% tt = readtable(fullfile(path_out, 'fkw', [CONFIG.glider '_' CONFIG.mission '_log_merged.csv']));
load(fullfile(path_out, 'fkw', [CONFIG.glider '_' CONFIG.mission '_log_merged.mat']))
% read in the glider surface positions
load(fullfile(path_profile, [CONFIG.glider CONFIG.mission '_gpsSurfaceTable.mat']))


%% plot glider track
lat = nan(height(gpsSurfT)*2,1);
lon = nan(height(gpsSurfT)*2,1);
dive = nan(height(gpsSurfT)*2,1);
time = nan(height(gpsSurfT)*2,1);
per = nan(height(gpsSurfT)*2,1);
for d = 1:height(gpsSurfT)
    try
        lat((d*2-1):d*2) = [gpsSurfT.startLatitude(d); gpsSurfT.endLatitude(d)];
        lon((d*2-1):d*2) = [gpsSurfT.startLongitude(d); gpsSurfT.endLongitude(d)];
        dive((d*2-1):d*2) = [d; d];
        time((d*2-1):d*2) = [datenum(gpsSurfT.startDateTime(d)); 
            datenum(gpsSurfT.endDateTime(d))];
        per((d*2-1):d*2) = [1, 2];
    catch
        continue
    end
end
plotm(lat, lon, 'LineWidth', 2, 'Color', [0.2 0.2 0.2])



%% get location of glider for each encounter
for f = 1:height(tlm)
   diveIdx = find(isbetween(tlm.start(f), gpsSurfT.startDateTime, gpsSurfT.endDateTime));
   tlm.diveNum(f) = diveIdx;
   tlm.lat(f) = gpsSurfT.startLatitude(diveIdx);
   tlm.lon(f) = gpsSurfT.startLongitude(diveIdx);
end

scatterm(tlm.lat, tlm.lon, 75, [1 1 0.2], 'filled', 'MarkerEdgeColor', [0 0 0])


%% title and save
title('Spring 2022 Odontocete Detections')
