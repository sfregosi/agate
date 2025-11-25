% WORKFLOW_PLOTMULTIPLEGLIDERS.M
%	Plot multiple glider paths and/or cetacean encounters on a single map
%
%	Description:
%		Example script for creating a single map with multiple glider
%		tracks. Glider labels and plotting colors are defined at the top
%		and then a basemap is made where glider tracks or cetacean events
%		can be added on top. A title and legend are added last. 
%
%	Notes
%
%	See also CREATEBASEMAP
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	FirstVersion: 	14 March 2024
%	Updated:        08 August 2024
%
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% (1) Define glider labels and colors

% set some colors
col_sg = [1 1 0; % yellow
	1 0.4 0];    % orange  
col_tgt = [0 0 0]; % black

% what should each glider be called?
gliders = {'sg001', 'sg002'};


%% (2) Create the basemap

% configure agate with one of the gliders to get map settings
CONFIG = agate('agate_mission_config_sg001.cnf');

% set bathymetry or contours on or off
bathyOn = 1; contourOn = 0;
% north arrow, scale bar or map limits can be defined in the CONFIG file
% specified above or manually set here
% e.g., to set north arrow location
CONFIG.map.naLat = 19.4;
CONFIG.map.naLon = -159.6;

% create basemap figure
[baseFig] = createBasemap(CONFIG, bathyOn, contourOn);
baseFig.Position = [20    80    1200    700]; % set position on screen


%% (3) Plot first glider's surface positions

% optionally plot the targets in the background
[targets, ~] = readTargetsFile(CONFIG, fullfile(CONFIG.path.mission, 'targets'));
plotm(targets.lat, targets.lon, 'Marker', 'o', 'MarkerSize', 2, ...
    'MarkerEdgeColor', col_tgt, 'MarkerFaceColor', col_tgt, 'Color', col_tgt, ...
    'HandleVisibility', 'off');
% may need to adjust offset of target labels depending on zoom level
text(targets.lon-0.1, targets.lat+0.1, targets.name, 'FontSize', 6)

% load gpsSurf table created with extractPositionalData
load(fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.gmStr '_gpsSurfaceTable.mat']));
% plot
plotm(gpsSurfT.startLatitude, gpsSurfT.startLongitude, ...
	'Color', col_sg(1,:), 'LineWidth', 1.5, 'DisplayName', gliders{1});


%% (4) Plot second glider's surface positions

% reinitilize agate with correct config file to get correct paths/strings
CONFIG = agate('agate_mission_config_sg002.cnf');

% load gpsSurf table created with extractPositionalData
load(fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.gmStr '_gpsSurfaceTable.mat']));
% plot
plotm(gpsSurfT.startLatitude, gpsSurfT.startLongitude, ...
	'Color', col_sg(2,:), 'LineWidth', 1.5, 'DisplayName', gliders{2});

% this could be repeated for as many gliders as exist

%% (5) Add legend, title and save

% add legend
legend(h,  'Location', 'northeast', 'FontSize', 14)

% add title
title('Glider mission', 'Interpreter', 'none')

% save it
exportgraphics(gca, 'combined_map.png', 'Resolution', 600);

