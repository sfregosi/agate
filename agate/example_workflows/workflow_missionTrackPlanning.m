% WORKFLOW_MISSIONTRACKPLANNING
%	Planned mission path kmls to targets file and pretty map
%
%	Description:
%       This script takes a planned track created in Google Earth and saved
%       as a .kml file and prepares it for the mission
%       (1) creates a properly formatted 'targets' file to be loaded onto
%       the glider
%       (2) creates a high quality planned mission map
%       (3) creates a plot of the bathymetry profile along the targets
%       track 
%       (4) exports a .csv of approx 5-km spaced trackpoints for estimating
%       arrival dates/times
%       (5) calculates full planned track distance and distance to end from
%       each waypoint for mission duration estimation
%       
%       This requires access to bathymetric basemaps for plotting and
%       requires manual creation of the track in Google Earth. Track must
%       be saved as a kml containing just a single track/path. More
%       information on creating a path in Google Earth can be found at 
%       https://sfregosi.github.io/agate-public/mission-planning.html#create-planned-track-using-google-earth-pro
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	FirstVersion: 	05 April 2023
%	Updated:        11 September 2024
%
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize agate - either specify a .cnf or leave blank to browse/select
CONFIG = agate('agate_mission_config.cnf');

%% (1) Generate targets file from Google Earth path saved as .kmml

% specify file name to .kml path
kmlFile = fullfile(CONFIG.path.mission, 'exampleTrack.kml');
% OR
% leave empty and will prompt to select .kml path
kmlFile = []; 

% specify radius
radius = 2000;

% create targets file, 3 options to name waypoints
% (1) alphanumeric/prefix-based automated naming
alphaNum = 'WP'; % Any two letters make easy to reference and read options
targetsOut = makeTargetsFile(CONFIG, kmlFile, alphaNum, radius);
% OR
% (2) use a text file with list of waypoint names; will prompt to select .txt
targetsOut = makeTargetsFile(CONFIG, kmlFile, 'file', radius);
% OR
% (3) manually enter in command window when prompted
targetsOut = makeTargetsFile(CONFIG, kmlFile, 'manual', radius);

%% (2) Plot and print/save proposed track map

% set up map configuration
bathyOn = 1;
figNum = 26;

% use targetsOut file from above as input targets file
targetsFile = targetsOut;

% create plot - single track only
mapPlannedTrack(CONFIG, targetsFile, CONFIG.glider, bathyOn, [], figNum)
% 5th argument blank uses default color (orange)

% get file name only for plot saving
[~, targetsName, ~] = fileparts(targetsFile);

% save as .png
exportgraphics(gcf, fullfile(CONFIG.path.mission, [CONFIG.glider '_' ...
	CONFIG.mission, '_plannedTrack_' targetsName, '.png']), ...
    'Resolution', 300)
% as .fig
savefig(fullfile(CONFIG.path.mission, [CONFIG.glider '_' CONFIG.mission, ...
    '_plannedTrack_' targetsName, '.fig']))

% save as .pdf or .eps - requires the export_fig toolbox available at
%  https://github.com/altmany/export_fig
export_fig(fullfile(CONFIG.path.mission, [CONFIG.glider '_' CONFIG.mission, ...
    '_plannedTrack_' targetsName, '.eps']), '-eps', '-painters');
export_fig(fullfile(CONFIG.path.mission, [CONFIG.glider '_' CONFIG.mission, ...
    '_plannedTrack_' targetsName, '.pdf']), '-pdf', '-painters');

%% (3) Plot bathymetry profile of targets file

% can specify bathymetry file
bathyFile = 'C:\GIS\etopo\ETOPO2022_bedrock_30arcsec.tiff';
plotTrackBathyProfile(CONFIG, 'targetsFile', targetsFile, ...
	'bathyFile', bathyFile)
% OR leave that argument out to default to CONFIG.map.bathyFile if
% available or prompt if not available
plotTrackBathyProfile(CONFIG, 'targetsFile', targetsFile)

% save as .png
exportgraphics(gcf, fullfile(CONFIG.path.mission, [CONFIG.glider '_' ...
	CONFIG.mission, '_targetsBathymetryProfile_' targetsName, '.png']), ...
    'Resolution', 300)

%% (4) Export interpolated track points

% create interpolated trackpoints every approx 5 km
interpTrack = interpolatePlannedTrack(CONFIG, targetsFile, 5);
% the spacing will not be perfectly at 5 km, but will break each track
% segment up into the number of points to be near 5 km betwee each
% If spacing is required to be more exact, it needs to be done in a
% GIS program (QGIS or ArcGIS) using the line splitting tools

% write to csv
writetable(interpTrack, fullfile(CONFIG.path.mission, ...
	['trackPoints_', targetsName, '.csv']));
% timing information can now be manually added in Exxcel based on planned
% deployment date/time and estimated speed


%% (5) Calculate track distance and mission duration

% if no targetsFile specified, will prompt to select
[targets, targetsFile] = readTargetsFile(CONFIG);
% OR specify targetsFile variable from above
[targets, targetsFile] = readTargetsFile(CONFIG, targetsFile);

% loop through all targets (except RECV), calc distance between waypoints
for f = 1:height(targets) - 1
    [targets.distToNext_km(f), ~] = lldistkm([targets.lat(f+1) targets.lon(f+1)], ...
        [targets.lat(f) targets.lon(f)]);
end

% specify expected avg glider speed in km/day
avgSpd = 15; % km/day

% print out summary
[targetsPath, targetsName, ~] = fileparts(targetsFile);
fprintf(1, 'Total tracklength for %s: %.0f km\n', targetsName, ...
	sum(targets.distToNext_km));
fprintf(1, 'Estimated mission duration, at %i km/day: %.1f days\n', avgSpd, ...
	sum(targets.distToNext_km)/avgSpd);
