% SoCal Deployment 2020 - SG639

% ********** SG639 **************

% interactive script to generate various maps for reporting
% Options:
    % 1 - Map with surface positions, colored by PAM on/off, waypoints on 
    % and labeled with a few dates. [plotSurfaceTrack]
    % 2 - Map with interpolated positions every minute, colored by PAM
    % status, can choose waypoints on or off, but thinking off here for
    % simplicity - this is where we should add the animal locations!
    % [plotInterpolatedTrack_PAM]
    % 3 - plot calculated/dead reckoned track
    % 4 - Export shape files for glider points at bottom for use in GIS
    
%% SET PATHS
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\gliderTools\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\myFunctions\'));

glider = 'sg639';
deploymentStr = 'SOCAL_Feb20';
% path_out = ['C:\Users\selene\Box\HDR-SOCAL-2020\maps\'];
path_profile = ['E:\SoCal2020\profiles\' glider '\'];
path_shp = 'C:\Users\selene\OneDrive\GIS\';
% path_shp = 'C:\Users\selene\OneDrive\projects\AFFOGATO\CatalinaComparison\profiles\matlabMapping\';
path_piloting = ['C:\Users\selene\Box\HDR-SOCAL-2020\piloting\' glider '\'];

%% SET PLOT LIMITS
latlim = [30.8 33.8];
lonlim = [-121.2 -118];

%% LOAD FILES
load([path_profile glider '_' deploymentStr '_gpsSurfaceTable_pam.mat']);
load([path_profile glider '_' deploymentStr '_locCalcT_pam.mat']);
load([path_profile glider '_' deploymentStr '_interpolatedTrack.mat']);

targetsFile = readTargetsFile(glider, path_piloting);
% plot rPo4
% plotm(33.228783, -118.251487, 'Marker', 'o', 'MarkerSize', 4, 'MarkerEdgeColor', [0 0 0], ...
%     'MarkerFaceColor', [0 0 0], 'Color', [0 0 0]) 
% textm(33.228783, -118.251487,'RPo4')

harps_shp = shaperead([path_maps 'HARPS_updated.shp'], 'UseGeoCoords', true);


%% 1 - PLOT BASIC MAP with track between surface positions
% plotSurfaceTrack(glider, gpsSurfT, path_shp, latlim, lonlim, targetsFile)
plotSurfaceTrack_withHarps(glider, gpsSurfT, path_shp, latlim, lonlim, harps_shp, targetsFile)

mapFig = gcf;
mapFigPosition = [50 50   900    900];
mapFig.Position = mapFigPosition;

% add labels
title('Shelf glider (SG639) SOCAL Feb 2020', 'FontSize', 18)

plotLandmarks

% label dates at several waypoints
wpColor = [0.3 0.3 0.3];
labelDatesWaypoints(glider)

%% 1 - print/save surface track map
set(gcf, 'InvertHardCopy', 'off', 'color', 'w');

print([path_profile 'map_' glider '_surfaceTrack_withHarps.png'], '-dpng')
% print([path_profile 'map_' glider '_surfaceTrack.eps'], '-depsc') (not
% editable in AI...bathy is too big imports as image
export_fig([path_profile 'map_' glider '_surfaceTrack_withHarps.eps'], '-eps', '-painters');
savefig([path_profile 'map_' glider '_surfaceTrack_withHarps.fig'])


%% 2 - PLOT BASIC MAP with interpolated positions
plotInterpolatedTrack_PAM(glider, sgInterp, path_shp, latlim, lonlim, [], 0)

mapFig = gcf;
mapFigPosition = [5200   -1350   900    900];
mapFig.Position = mapFigPosition;

% add labels
title('SG639 SOCAL Feb 2020', 'FontSize', 18)

plotLandmarks

% label dates at several waypoints
wpColor = [0.3 0.3 0.3];
textm(targetsFile.lat(1)-0.065, targetsFile.lon(1)+0.06, ...
    '07 Feb 16:55', 'Color', wpColor, 'FontSize', 10)
textm(targetsFile.lat(2)-0.065, targetsFile.lon(2)+0.06, ...
    '09 Feb 01:39', 'Color', wpColor, 'FontSize', 10)
textm(targetsFile.lat(3)-0.065, targetsFile.lon(3)+0.06, ...
    '10 Feb 22:34', 'Color', wpColor, 'FontSize', 10)
textm(32.6250, -119.93, ...
    '12 Feb 21:02', 'Color', wpColor, 'FontSize', 10)


%% 2 - print/save interpolated track map
print([path_profile 'map_' glider '_interpolatedTrack.png'], '-dpng')
% print([path_profile 'map_' glider '_surfaceTrack.eps'], '-depsc') (not
% editable in AI...bathy is too big imports as image
export_fig([path_profile 'map_' glider '_interpolatedTrack.eps'], '-eps', '-painters');
savefig([path_profile 'map_' glider '_interpolatedTrack.fig'])



%% 3 - plot calculated/dead reckoned track
plotCalculatedTrack(glider, locCalcT, path_shp, latlim, lonlim, targetsFile)

mapFig = gcf;
mapFigPosition = [5200   -1350   900    900];
mapFig.Position = mapFigPosition;

% add labels
title('SG639 SOCAL Feb 2020', 'FontSize', 18)

plotLandmarks

% label dates at several waypoints
wpColor = [0.3 0.3 0.3];
textm(targetsFile.lat(1)-0.065, targetsFile.lon(1)+0.06, ...
    '07 Feb 16:55', 'Color', wpColor, 'FontSize', 10)
textm(targetsFile.lat(2)-0.065, targetsFile.lon(2)+0.06, ...
    '09 Feb 01:39', 'Color', wpColor, 'FontSize', 10)
textm(targetsFile.lat(3)-0.065, targetsFile.lon(3)+0.06, ...
    '10 Feb 22:34', 'Color', wpColor, 'FontSize', 10)
textm(32.6250, -119.93, ...
    '12 Feb 21:02', 'Color', wpColor, 'FontSize', 10)

%% 3 - print/save calculated track
print([path_profile 'map_' glider '_calculatedTrack.png'], '-dpng')
% print([path_profile 'map_' glider '_calculatedTrack.eps'], '-depsc')
export_fig([path_profile 'map_' glider '_calculatedTrack.eps'], '-eps', '-painters');
savefig([path_profile 'map_' glider '_calculatedTrack.fig'])


%% 4 - export glider track shape files

load([path_profile glider '_' deploymentStr '_interpolatedTrack.mat']);

interpTrackToShapefile(glider, deploymentStr, path_profile)

gpsSurfToShapefile(glider, deploymentStr, path_profile)


% check
T = shaperead([path_profile glider '_' deploymentStr '_gpsSurfacePoints.shp']);
T = shaperead([path_profile glider '_' deploymentStr '_interpTracks.shp']);
sum([T. Length_km])

