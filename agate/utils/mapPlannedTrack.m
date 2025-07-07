function targetsName = mapPlannedTrack(CONFIG, targetsFile, varargin)
%MAPPLANNEDTRACK Create static map of planned mission track
%
%   Syntax:
%      TARGETSNAME = MAPPLANNEDTRACK(CONFIG, TARGETSFILE, VARARGIN)
%
%   Description:
%       Create a static map of the planned mission track from an input
%       targets file. Optional argument to plot bathymetry (if available)
%       and set legend name and track color.
%
%       Bathymetry files can be downloaded from NCEI. For more info on
%       selecting a bathymetry file visit:
%       https://sfregosi.github.io/agate/#basemap-rasters
%
%   Inputs:
%       CONFIG        [struct] mission/agate configuration variable.
%                     Required fields: CONFIG.glider, CONFIG.mission,
%                     CONFIG.path.mission, CONFIG.map plotting section
%       targetsFile   [char] fullpath to targets file
%
%       all varargins are specified using name-value pairs
%                 e.g., 'bathy', 1, 'figNum', 12
%
%       trackName     [char] optional argument for the legend entry. If
%                     empty will just say 'glider', e.g., 'sg639'
%       bathy         optional argument for bathymetry plotting
%                     [double] Set to 1 to plot bathymetry or 0 to only
%                     plot land. Default is 0. Will look for bathy file in
%                     CONFIG.map.bathyFile.
%                     [char] Path to the bathymetry file (if you want to
%                     use a different one than specified in CONFIG or it is
%                     not specified in CONFIG
%       contourOn     [double] optional argument. Set to 1 to plot 
%                     contours or 0 for no contour lines. Default is off 0                   
%       col_track     [char or RGB mat] optional color for the track e.g.,
%                     [1 0.4 0] for orange or 'black'. Default is orange
%       figNum        [double] optional argument defining figure number
%                     so it doesn't keep making new figs but refreshes
%                     existing figure
%
%   Outputs:
%       targetsName   [char] filename of the input or selected targets
%                     file; optional output can be useful for saving/titles
%       -----         creates figure
%
%   Examples:
%       % use specified targets file, plot bathymetry, specify name/color
%       mapPlannedTrack(CONFIG, targetsFile, 'trackName', 'sg679', ...
%            'bathy', 1, 'col_track', 'black')
%       % to be prompted to select the targets file, plot bathy, output
%       % targetsName for the targets file selected
%       targetsName = mapPlannedTrack(CONFIG, [], 'bathy', 1)
%       % to use default track name 'glider', and default no bathymetry,
%       use default color orange
%       mapPlannedTrack(CONFIG, targetsFile)
%
%   See also   MAKETARGETSFILE
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:      26 May 2025
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% argument checks
narginchk(2, inf)

% check for nargout is below after checks for targetsFile

% set defaults/empties
trackName = 'glider';
bathy = 0;
contourOn = 0;
col_track = [1 0.4 0];
figNum = [];

% parse arguments
vIdx = 1;
while vIdx <= length(varargin)
    switch varargin{vIdx}
        case 'trackName'
            trackName = varargin{vIdx+1};
            vIdx = vIdx+2;
        case 'bathy'
            % just carry the arg through to createBasemap
            bathy = varargin{vIdx+1};
            vIdx = vIdx+2;
        case 'contourOn'
            % just carry the arg through to createBasemap
            contourOn = varargin{vIdx+1};
            vIdx = vIdx+2;
        case 'col_track'
            col_track = varargin{vIdx+1};
            vIdx = vIdx+2;
        case 'figNum'
            figNum = varargin{vIdx+1};
            vIdx = vIdx+2;
        otherwise
            error('Incorrect argument. Check inputs.');
    end
end

if isempty(targetsFile) || ~exist(targetsFile, 'file')
    [fn, path] = uigetfile(fullfile(CONFIG.path.mission, '*.*'), ...
        'Select targets file');
    targetsFile = fullfile(path, fn);
    fprintf('targets file selected: %s\n', fn);
end

% get file name for output argument for titling/saving
if nargout > 0
    [~, targetsName, ~] = fileparts(targetsFile);
end

% create basemap
% by default, don't include contours. Include bathymetry if specified.
[baseFig] = createBasemap(CONFIG, 'bathy', bathy, 'contourOn', contourOn, ...
    'figNum', figNum);

% plot glider track from targets file
[targets, ~] = readTargetsFile(CONFIG, targetsFile);

plotm(targets.lat, targets.lon, 'Marker', 'o', 'MarkerSize', 4, 'MarkerEdgeColor', [0 0 0], ...
    'MarkerFaceColor', [0 0 0], 'Color', [0 0 0], 'HandleVisibility', 'off')
textm(targets.lat, targets.lon, targets.name, 'FontSize', 10)

h(1) = linem(targets.lat, targets.lon, 'LineWidth', 2, 'Color', col_track,...
    'DisplayName', trackName);

legend(h, {trackName}, 'Location', 'southeast', 'FontSize', 14)

% add title
title(sprintf('%s %s: %s', CONFIG.glider, CONFIG.mission, targetsName), ...
    'Interpreter', 'none')

end

