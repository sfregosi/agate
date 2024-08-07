function plotTrackBathyProfile(CONFIG, targetsFile, yLine, figNum)
% PLOTTRACKBATHYPROFILE	Create bathymetric profile for planned targets
%
%   Syntax:
%       OUTPUT = PLOTTRACKBATHYPROFILE(CONFIG, TARGETSFILE, YLINE, FIGNUM)
%
%   Description:
%       Create a plot of the bathymetric profile along a targets file to
%       get an overview of the bathymetry the planned track will cover and
%       identify areas where the bathymetry is less than 1000 m. A targets
%       file is read in, interpolated at 0.1 decimal degree resolution, and
%       bathymetric depths are extracted from an etopo raster (or other
%       specified bathymetric raster). Interpolated points as well as
%       depths at actual targets waypoints are plotted.
%
%   Inputs:
%       CONFIG        [struct] agate configuration settings from .cnf
%       targetsFile   [string] optional argument to targets file. If no file
%                     specified, will prompt to select one, and if no path
%                     specified, will prompt to select path
%                     [table] alternatively can just reference a targets
%                     table that has already been read in to the workspace
%       yLine         [vector] optional argument to set depth to place
%                     horizontal indicator line; default is 990 m
%       figNum        optional argument defining figure number so it
%                     doesn't keep making new figs but refreshes existing
%
%   Outputs:
%       none, creates figure
%
%   Examples:
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   10 May 2023
%   Updated:        06 August 2024
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% argument checks
if nargin < 4
	figNum = 211;
end

if nargin < 3
	figNum = 211;
	yLine = -990;
end

% select targetsFile if none specified
if nargin < 2
	figNum = 211;
	[fileName, filePath] = uigetfile([CONFIG.path.mission, '*.*'], ...
		'Select targets file');
	targetsFile = fullfile(filePath, fileName);
	fprintf('targets file selected: %s\n', fileName);
end

% check that targetsFile exists if specified, otherwise prompt to select
if ischar(targetsFile)
	if ~exist(targetsFile, 'file')
		fprintf(1, 'Specified targetsFile does not exist. Select targets file to continue.\n');
		[fileName, filePath] = uigetfile([CONFIG.path.mission, '*.*'], ...
			'Select targets file');
		targetsFile = fullfile(filePath, fileName);
		fprintf('targets file selected: %s\n', fileName);
	end
	% read in targets file
	[targets, ~] = readTargetsFile(CONFIG, targetsFile);
elseif istable(targetsFile)
	targets = targetsFile;
end

% estimate cumulative track length
targets.cumDist_km = zeros(height(targets), 1);
for f = 2:height(targets)
	targets.cumDist_km(f) = targets.cumDist_km(f-1) + ...
		lldistkm([targets.lat(f-1) targets.lon(f-1)], [targets.lat(f) targets.lon(f)]);
end

% interpolate between targets at 0.1 dec deg resolution
ti = table;
ti.lat = interp1(targets.lat, 1:0.1:length(targets.lat))';
ti.lon = interp1(targets.lon, (1:0.1:length(targets.lon))');
ti.cumDist_km = interp1(targets.cumDist_km, 1:0.1:length(targets.lat))';
ti.depth = nan(height(ti), 1);


% check for bathy file or select if not specified/doesn't exist
if isfield(CONFIG.map, 'bathyFile')
	bathyFile = CONFIG.map.bathyFile;
elseif ~isfield(CONFIG.map, 'bathyFile') || ~exist(bathyFile, 'file') % prompt to choose file
	if isfield(CONFIG.path, 'shp')
		shpDir = CONFIG.path.shp;
	else
		shpDir = 'C:\';
	end
	[fn, path] = uigetfile(fullfile(shpDir, '*.tif;*.tiff'), ...
		'Select bathymetry raster file');
	bathyFile = fullfile(path, fn);
end

% read in and crop bathymetry data
[Z, refvec] = readgeoraster(bathyFile, 'OutputType', 'double', ...
	'CoordinateSystemType', 'geographic');
[Z, refvec] = geocrop(Z, refvec, CONFIG.map.latLim, CONFIG.map.lonLim);

% Pull out lat/lon vectors from refvec
% use 0.5*cell extent to get midpoints of each cell
Zlat = [refvec.LatitudeLimits(1)+0.5*refvec.CellExtentInLatitude: ...
	refvec.CellExtentInLatitude:refvec.LatitudeLimits(2)]';
Zlat = flipud(Zlat); % have to flip bc small latitudes are at poles
Zlon = [refvec.LongitudeLimits(1)+0.5*refvec.CellExtentInLongitude: ...
	refvec.CellExtentInLongitude:refvec.LongitudeLimits(2)]';

% loop through interpolated lat/lons and pull depth at closest Z cell
for f = 1:height(ti)
	[mLat, idxLat] = min(abs(Zlat-ti.lat(f)));
	[mLon, idxLon] = min(abs(Zlon-ti.lon(f)));
	% make sure the mins are below the cell extent
	if mLat <= refvec.CellExtentInLatitude && mLon <= refvec.CellExtentInLongitude
		ti.depth(f) = Z(idxLat, idxLon);
	end
end

% repeat for just the waypoints
targets.depth = nan(height(targets), 1);
for f = 1:height(targets)
	[mLat, idxLat] = min(abs(Zlat-targets.lat(f)));
	[mLon, idxLon] = min(abs(Zlon-targets.lon(f)));
	% make sure the mins are below the cell extent
	if mLat <= refvec.CellExtentInLatitude && mLon <= refvec.CellExtentInLongitude
		targets.depth(f) = Z(idxLat, idxLon);
	end
end

% set up figure
figure(figNum);
fig = gcf;
fig.Position = [100   50   900    300];

% clear figure (in case previously plotted)
clf
cla reset;

plot(ti.cumDist_km, ti.depth, 'k:');
hold on;
scatter(targets.cumDist_km, targets.depth, 10, 'k', 'filled')
% label the waypoints
text(targets.cumDist_km + max(targets.cumDist_km)*.006, targets.depth - 100, ...
	targets.name, 'FontSize', 10);
yline(yLine, '--', 'Color', '#900C3F');
grid on;
hold off;

xlabel('track length [km]')
ylim([round(min(ti.depth) + min(ti.depth)*.1) 10])
xlim([0 round(targets.cumDist_km(end) + targets.cumDist_km(end)*.05)])
ylabel('depth [m]')
set(gca, 'FontSize', 12)
title(sprintf('%s %s %s', CONFIG.glider, CONFIG.mission, ...
	'Targets Bathymetry Profile'), 'Interpreter', 'none')

end