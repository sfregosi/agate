function mapMissionPath(CONFIG, pp, varargin)
%MAPMISSIONPATH	Plot glider path on bathymetric map
%
%   Syntax:
%       MAPMISSIONPATH(CONFIG, PP, VARARGIN)
%
%   Description:
%       Map of glider's path to date during a mission overlayed on the
%       planned track (from the targets file). Shows surface locations for
%       each dive, a line connecting these surface locations (not
%       dead-reckoned positions between surfacings) and vectors showing the
%       depth averaged current for each dive. The next waypoint is
%       highlighted with a green circle. 
%
%   Inputs:
%       CONFIG      [struct] mission/agate configuration variable.
%                   Required fields: CONFIG.map entries
%       pp          [table] piloting parameters table created with
%                   extractPilotingParams
%
%       all varargins are specified using name-value pairs
%                 e.g., 'targetsFile', 'C:\target', 'bathy', 1
%
%       targetsFile [char] optional argument to targets file. If no file
%                   specified, will prompt to select one, and if no path
%                   specified, will prompt to select path
%                   [table] alternatively can just reference a targets
%                   table that has already been read in to the workspace
%       bathy       optional argument for bathymetry plotting
%	                [double] Set to 1 to plot bathymetry or 0 to only plot
%                   land. Default is 1. Will look for bathy file in
%                   CONFIG.map.bathyFile or prompt if none found
%                   [char] Path to the bathymetry file (if you want to use
%                   a different one than specified in CONFIG or it is not
%                   specified in CONFIG)
%
%   Outputs:
%       no output, creates figure
%
%   Examples:
%       tf = 'C:\targets'; % path to targets file
%       mapMissionPath(CONFIG, pp6, 'targetsFile', tf, 'bathyOn', 1)
%
%   See also EXTRACTPILOTINGPARAMS, MAPPLANNEDTRACK
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   17 January 2025
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% argument checks
narginchk(2, inf)

% set defaults
targetsFile = [];
bathyOn = 1;
bathyFile = [];

% parse arguments
vIdx = 1;
while vIdx <= length(varargin)
    switch varargin{vIdx}
        case 'targetsFile'
            targetsFile = varargin{vIdx+1};
            vIdx = vIdx+2;
        case 'bathy'
            if ischar(varargin{vIdx+1}) || isstring(varargin{vIdx+1})
                bathyOn = 1;
                bathyFile = varargin{vIdx+1};
            elseif isnumeric(varargin{vIdx+1})
                bathyOn = varargin{vIdx+1};
                bathyFile = [];
            end
            vIdx = vIdx+2;
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
if isstring(targetsFile)
    targetsFile = convertStringsToChars(targetsFile);
end

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


% set figNum
figNum = []; % leave blank if not specified
% or pull from config if it is
if isfield(CONFIG, 'plots')
    if isfield(CONFIG.plots, 'figNumList')
        figNum = CONFIG.plots.figNumList(1);
    end
end

% set position
mapFigPosition = [100    100    800    600];
% overwrite if in config
if isfield(CONFIG, 'plots') && ...
        isfield(CONFIG.plots, 'positions') && isfield(CONFIG.plots, 'figNumList')
    % is a position defined for this figure
    fnIdx = find(figNum == CONFIG.plots.figNumList);
    if length(CONFIG.plots.positions) >= fnIdx && ~isempty(CONFIG.plots.positions{fnIdx})
        mapFigPosition = CONFIG.plots.positions{fnIdx};
    end
end

states = shaperead('usastatehi', 'UseGeoCoords', true, ...
    'BoundingBox', [CONFIG.map.lonLim' CONFIG.map.latLim']);

currColor = '#29c481'; % color for current vectors

%% set up figure
if isempty(figNum)
    figure;
else
    figure(figNum);
end

mapFig = gcf;
mapFig.Name = 'Map';
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

% add north arrow - if location specified
if isfield(CONFIG.map, 'naLat') && isfield(CONFIG.map, 'naLon')
    CONFIG.map.na = northarrow('latitude', CONFIG.map.naLat, 'longitude', ...
        CONFIG.map.naLon, 'FaceColor', [1 1 1], 'EdgeColor', [1 1 1]);
end

% add scale bar - if location and scale are specified
if isfield(CONFIG.map, 'scalePos') && isfield(CONFIG.map, 'scaleMajor') && ...
        isfield(CONFIG.map, 'scaleMinor')
    scaleruler on
    % showaxes
    setm(handlem('scaleruler1'), 'RulerStyle', 'patches', ...
        'XLoc', CONFIG.map.scalePos(1), 'YLoc', CONFIG.map.scalePos(2), ...
        'MajorTick', CONFIG.map.scaleMajor, 'MinorTick', CONFIG.map.scaleMinor, ...
        'FontSize', 14);
end

%%  plot bathymetry - slow step


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



%  plot bathymetry - slow step - optional
if bathyOn

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

    [Z, refvec] = readgeoraster(bathyFile, 'OutputType', 'double', ...
        'CoordinateSystemType', 'geographic');
    [Z, refvec] = geocrop(Z, refvec, CONFIG.map.latLim, CONFIG.map.lonLim);

    Z(Z >= 10) = 100;
    geoshow(Z, refvec, 'DisplayType', 'surface', ...
        'ZData', zeros(size(Z)), 'CData', Z);

    cmap = cmocean('ice');
    cmap = cmap(120:210,:);
    colormap(cmap)
    % matlab renamed caxis to clim in R2022a...so try both
    try clim([-6000 0]); catch caxis([-6000 0]); end %#ok<SEPEX>
    brighten(.4);

    [~,~] = contourm(Z, refvec, [-5000:1000:1000], 'LineColor', [0.6 0.6 0.6]); %#ok<NBRAK>
    [~,~] = contourm(Z, refvec, [-1000 -1000], 'LineColor', [0.3 0.3 0.3], ...
        'LineWidth', 0.8);
    [~,~] = contourm(Z, refvec, [-900:100:0], 'LineColor', [0.8 0.8 0.8]); %#ok<NBRAK>
    [~,~] = contourm(Z, refvec, [-500 -500], 'LineColor', [0.6 0.6 0.6]);
end

geoshow(states, 'FaceColor', [0 0 0], 'EdgeColor', 'k')


%% plot waypoints
plotm(targets.lat, targets.lon, 'Marker', 'o', 'MarkerSize', 4, ...
    'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0 0 0], 'Color', [0 0 0])
textm(targets.lat, targets.lon, targets.name, 'FontSize', 8)

% highlight current waypoint
plotm(pp.tgtLoc{end}, 'Marker', 'o', 'MarkerSize', 10, ...
    'MarkerEdgeColor', currColor, 'LineWidth', 2)

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
        time((d*2-1):d*2) = [datenum(pp.diveStartTime(d));
            datenum(pp.diveEndTime(d))];
        per((d*2-1):d*2) = [1, 2];
    catch
        continue
    end
end
plotm(lat, lon, 'LineWidth', 2, 'Color', [1 0.4 0.2])
plotm(lat, lon, '.y')
plotm(lat(end), lon(end), '+', 'Color', currColor, 'MarkerSize', 10, ...
    'LineWidth', 2)

title(sprintf('%s - %i dives completed', CONFIG.glider, height(pp)))
textm(lat(end), lon(end), num2str(height(pp)), 'Color', currColor);

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
quiverm(endLat(logical(~isnan(pp.dac_east_cm_s))), ...
    endLon(logical(~isnan(pp.dac_east_cm_s))),...
    pp.dac_north_cm_s(logical(~isnan(pp.dac_east_cm_s))), ...
    pp.dac_east_cm_s(logical(~isnan(pp.dac_east_cm_s))), 'b')


end
