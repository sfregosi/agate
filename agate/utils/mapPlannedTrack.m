function mapPlannedTrack(CONFIG, targetsFile, trackName, bathyOn, col_track, figNum)
%MAPPLANNEDTRACK Create static map of planned mission track
%
%   Syntax:
%       MAPPLANNEDTRACK(CONFIG, targetsFile, trackName, bathyOn, figNum)
%
%   Description:
%       Create a static map of the planned mission track from an input
%       targets file. Optional argument to plot bathymetry (requires etopo
%       raster from NCEI) and land (requires shape files from Natural Earth
%
%       Download etopo_2022_v1_60s_N90W180_surface.tif from NCEI:
%           https://www.ncei.noaa.gov/products/etopo-global-relief-model
%
%       Download Natural Earth Data (naturalearthdata.com), latest release
%       on GitHub: 
%           https://github.com/nvkelso/natural-earth-vector/releases
% 
%   Inputs:
%       CONFIG        [struct] mission/agate configuration variable.
%                     Required fields: CONFIG.glider, CONFIG.mission, 
%                     CONFIG.path.mission, CONFIG.map plotting section 
%       targetsFile   [char] fullpath to targets file
%       trackName     [char] optional argument for the legend entry. If 
%                     empty will just say 'glider', e.g., 'sg639'
%       bathyOn       [double] optional arg to plot bathymetry. Default
%                     is 0 (off), set to 1 to plot. Bathymetry file can
%                     be defined as CONFIG.map.bathyFile or will be
%                     prompted to select a file 
%       col_track	  [char or RGB mat] color for the track e.g.,
%                     [1 0.4 0] for orange or 'black'. Default is orange
%       figNum        [double] optional argument defining figure number 
%                     so it doesn't keep making new figs but refreshes 
%                     existing figure
%
%   Outputs:
%       none          creates figure
%
%   Examples:
%       # use specified targets file, plot bathymetry
%       mapPlannedTrack(CONFIG, targetsFile, 'sg679', 1, 'black')
%       % to be prompted to select the targets file, plot bathymetry
%       mapPlannedTrack(CONFIG, [], 'sg679', 1, 'black')
%       % to use default track name 'glider', and do not plot bathymetry,
%       use default color orange
%       mapPlannedTrack(CONFIG, targetsFile, [], 0, []) 
%
%   See also   MAKETARGETSFILE
% 
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   22 March 2023
%   Updated:        10 September 2024
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% argument checks
if nargin < 6
    figNum = 210;
end

if isempty(targetsFile)
    [fn, path] = uigetfile(fullfile(CONFIG.path.mission, '*.*'), ...
        'Select targets file');
    targetsFile = fullfile(path, fn);
end

if isempty(trackName)
    trackName = 'glider';
end

if isempty(bathyOn)
    bathyOn = 0;
end

if isempty(col_track)
	col_track = [1 0.4 0];
end

% create basemap
% by default, don't include contours. Include bathymetry if specified.
[baseFig] = createBasemap(CONFIG, bathyOn, 0, figNum);

% plot glider track from targets file
[targets, ~] = readTargetsFile(CONFIG, targetsFile); 

plotm(targets.lat, targets.lon, 'Marker', 'o', 'MarkerSize', 4, 'MarkerEdgeColor', [0 0 0], ...
    'MarkerFaceColor', [0 0 0], 'Color', [0 0 0], 'HandleVisibility', 'off')
textm(targets.lat, targets.lon, targets.name, 'FontSize', 10)

h(1) = linem(targets.lat, targets.lon, 'LineWidth', 2, 'Color', col_track,...
    'DisplayName', trackName);

legend(h, {trackName}, 'Location', 'southeast', 'FontSize', 14)

% add title
title(sprintf('%s %s', CONFIG.glider, CONFIG.mission), 'Interpreter', 'none')

end

