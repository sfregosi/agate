function plotTrackBathyProfile(CONFIG, varargin)
%PLOTTRACKBATHYPROFILE	Create bathymetric profile for planned targets
%
%   Syntax:
%       PLOTTRACKBATHYPROFILE(CONFIG, VARARGIN)
%
%   Description:
%       Create a plot of the bathymetric profile along a targets file to
%       get an overview of the bathymetry the planned track will cover and
%       identify areas where the bathymetry is less than 1000 m. A targets
%       file and bathymetry raster are loaded and interpolated to pull the
%       seafloor depth along the targets file trackline. Depths along the
%       trackline are plotted as well as actual targets waypoints.
%       Interpolation between the waypoints is done using the great circle
%       distance and the reference ellipsoid specified by the loaded raster
%       (WGS84 if using an NCEI ETOPO tiff)
%
%       Note: The total distance is slightly different than the distance
%       calculated using lldistkm. lldistkm uses the Haversine formula
%       which calculates great circle distance of a sphere with radius 6371
%       km. The mapprofile function calculates great circle distance using
%       a reference ellipsoid (WGS84 for NCEI ETOPO tiffs) so is slightly
%       more accurate but should only be off a few km at the scale of
%       typical glider missions.
%
%       Bathymetry files can be downloaded from NCEI. For more info on
%       selecting a bathymetry file visit:
%       https://sfregosi.github.io/agate/#basemap-rasters
%
%   Inputs:
%       CONFIG      [struct] mission/agate configuration variable.
%                   Required fields: CONFIG.glider, CONFIG.mission, 
%                   CONFIG.path.mission
%
%       all varargins are specified using name-value pairs 
%                 e.g., 'targetsFile', targetsFile, 'yLine', 800
%
%       targetsFile   [char] optional argument to targets file. If no file
%                     specified, will prompt to select one, and if no path
%                     specified, will prompt to select path
%                     [table] alternatively can just reference a targets
%                     table that has already been read in to the workspace
%       bathyFile     [char] optional argument to define or prompt to
%                     select a bathymetry file either because one is not
%                     defined in CONFIG or a different one is desired
%       yLine         [vector] optional argument to set depth to place
%                     horizontal indicator line; default is 990 m
%       figNum        [double] optional argument defining figure number to
%                     avoid making repeated figs
%
%   Outputs:
%       none, creates figure
%
%   Examples:
%       % use already defined targetsFile, bathy defined in CONFIG
%       plotTrackBathyProfile(CONFIG, 'targetsFile', targetsFile);
%       % prompt to select targets, specify bathymetry file outside CONFIG
%       plotTrackBathyProfile(CONFIG, 'bathyFile', 'C:\bathy.tiff')
%       % set depth indicator line at 800 m, use already loaded targets
%       plotTrackBathyProfile(CONFIG, 'yLine', 800, 'targetsFile', targets)
%
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   10 May 2023
%   Updated:        11 September 2024
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% argument checks
narginchk(1, inf)

% set defaults
targetsFile = [];
bathyFile = [];
yLine = -990;
figNum = [];

% parse arguments
n = 1;
while n <= length(varargin)
	switch varargin{n}
		case 'targetsFile'
			targetsFile = varargin{n+1};
			n = n+2;
		case 'bathyFile'
			bathyFile = varargin{n+1};
			n = n+2;
		case 'yLine'
			yLine = varargin{n+1};
			n = n+2;
		case 'figNum'
			figNum = varargin{n+1};
			n = n+2;
	end
end

% select targetsFile if none specified
if isempty(targetsFile)
	[fn, path] = uigetfile([CONFIG.path.mission, '*.*'], ...
		'Select targets file');
	targetsFile = fullfile(path, fn);
	fprintf('targets file selected: %s\n', fn);
end

% check that targetsFile exists if specified, otherwise prompt to select
if ischar(targetsFile)
	if ~exist(targetsFile, 'file')
		fprintf(1, ['Specified targetsFile does not exist. Select' ...
			' targets file to continue.\n']);
		[fn, path] = uigetfile([CONFIG.path.mission, '*.*'], ...
			'Select targets file');
		targetsFile = fullfile(path, fn);
		fprintf('targets file selected: %s\n', fn);
	end
	% read in targets file
	[targets, ~] = readTargetsFile(CONFIG, targetsFile);
elseif istable(targetsFile)
	targets = targetsFile;
end

% check for bathy file if none specified - first check config, then prompt
if isempty(bathyFile)
	if isfield(CONFIG.map, 'bathyFile')
		bathyFile = CONFIG.map.bathyFile;
	elseif ~isfield(CONFIG.map, 'bathyFile') || ~exist(bathyFile, 'file')
		if isfield(CONFIG.path, 'shp')
			shpDir = CONFIG.path.shp;
		else
			shpDir = 'C:\';
		end
		[fn, path] = uigetfile(fullfile(shpDir, '*.tif;*.tiff'), ...
			'Select bathymetry raster file');
		bathyFile = fullfile(path, fn);
	end
end

% check that bathyFile eists if specified, otherwise prompt to select
if ~exist(bathyFile, 'file')
	fprintf(1, ['Specified bathyFile does not exist. Select' ...
		' bathymetry raster file to continue.\n']);
	if isfield(CONFIG.path, 'shp')
		shpDir = CONFIG.path.shp;
	else
		shpDir = 'C:\';
	end
	[fn, path] = uigetfile(fullfile(shpDir, '*.tif;*.tiff'), ...
		'Select bathymetry raster file');
	bathyFile = fullfile(path, fn);
	fprintf('bathymetry raster file selected: %s\n', fn);
end

% read in bathymetry data
[Z, refvec] = readgeoraster(bathyFile, 'OutputType', 'double', ...
	'CoordinateSystemType', 'geographic');

% interpolate locations/depths
[zq, distq, latq, lonq] = mapprofile(Z, refvec, targets.lat, targets.lon);
distq_km = distq/1000;

% find indices of waypoints only
targets.dist_km = zeros(height(targets), 1);
targets.depth_m = nan(height(targets), 1);
for f = 1:height(targets)
	wpIdx = find(latq == targets.lat(f) & lonq == targets.lon(f));
	targets.dist_km(f) = distq_km(wpIdx);
	targets.depth_m(f) = zq(wpIdx);
end

% set up figure
if isempty(figNum)
	figure;
else
	figure(figNum);
end
fig = gcf;
fig.Position = [100   50   900    300];

% clear figure (in case previously plotted)
clf
cla reset;

plot(distq_km, zq, 'k:');
hold on;
scatter(targets.dist_km, targets.depth_m, 10, 'k', 'filled')
% label the waypoints
text(targets.dist_km + max(targets.dist_km)*.006, targets.depth_m - 100, ...
	targets.name, 'FontSize', 10);
yline(yLine, '--', 'Color', '#900C3F');
grid on;
hold off;

xlabel('track length [km]')
ylim([round(min(zq) + min(zq)*.1) 10])
xlim([0 round(targets.dist_km(end) + targets.dist_km(end)*.05)])
ylabel('depth [m]')
set(gca, 'FontSize', 12)
title(sprintf('%s %s %s', CONFIG.glider, CONFIG.mission, ...
	'Targets Bathymetry Profile'), 'Interpreter', 'none')




% OLD MANUAL METHOD
% [Z, refvec] = geocrop(Z, refvec, CONFIG.map.latLim, CONFIG.map.lonLim);

% % Pull out lat/lon vectors from refvec
% % use 0.5*cell extent to get midpoints of each cell
% Zlat = [refvec.LatitudeLimits(1)+0.5*refvec.CellExtentInLatitude: ...
% 	refvec.CellExtentInLatitude:refvec.LatitudeLimits(2)]';
% Zlat = flipud(Zlat); % have to flip bc small latitudes are at poles
% Zlon = [refvec.LongitudeLimits(1)+0.5*refvec.CellExtentInLongitude: ...
% 	refvec.CellExtentInLongitude:refvec.LongitudeLimits(2)]';
%
% % estimate cumulative track length
% targets.cumDist_km = zeros(height(targets), 1);
% for f = 2:height(targets)
% 	targets.cumDist_km(f) = targets.cumDist_km(f-1) + ...
% 		lldistkm([targets.lat(f-1) targets.lon(f-1)], [targets.lat(f) targets.lon(f)]);
% end
%
% % interpolate between targets at 0.1 dec deg resolution
% ti = table;
% ti.lat = interp1(targets.lat, 1:0.1:length(targets.lat))';
% ti.lon = interp1(targets.lon, (1:0.1:length(targets.lon))');
% ti.cumDist_km = interp1(targets.cumDist_km, 1:0.1:length(targets.lat))';
% ti.depth = nan(height(ti), 1);
%
%
% % loop through interpolated lat/lons and pull depth at closest Z cell
% for f = 1:height(ti)
% 	[mLat, idxLat] = min(abs(Zlat-ti.lat(f)));
% 	[mLon, idxLon] = min(abs(Zlon-ti.lon(f)));
% 	% make sure the mins are below the cell extent
% 	if mLat <= refvec.CellExtentInLatitude && mLon <= refvec.CellExtentInLongitude
% 		ti.depth(f) = Z(idxLat, idxLon);
% 	end
% end
%
% % repeat for just the waypoints
% targets.depth = nan(height(targets), 1);
% for f = 1:height(targets)
% 	[mLat, idxLat] = min(abs(Zlat-targets.lat(f)));
% 	[mLon, idxLon] = min(abs(Zlon-targets.lon(f)));
% 	% make sure the mins are below the cell extent
% 	if mLat <= refvec.CellExtentInLatitude && mLon <= refvec.CellExtentInLongitude
% 		targets.depth(f) = Z(idxLat, idxLon);
% 	end
% end



end