% WORKFLOW_SURVEYTRACKPLANNING
%	Planned mission path kmls to targets file and pretty map
%
%	Description:
%       This script takes a survey track created in Google Earth and saved
%       as a .kml file and prepares it for the survey
%       (1) creates a properly formatted 'targets' file to be loaded onto
%       the glider
%       (2) creates a high quality planned survey map figure
%       (3) creates a plot of the bathymetry profile along the targets
%       track 
%       (4) calculates full planned track distance and distance to end from
%       each waypoint for mission duration estimation
%       
%       This requires access to bathymetric basemaps for plotting and
%       requires manual creation of the track in Google Earth. Track must
%       be saved as a kml containing just a single track/path. To properly 
%       save: within Google Earth, right click on track name in left panel, 
%       select save place as, change file type from .kmz to .kml, save
%
%	See also
%
%   TO DO:
%       [ ] link to documentation on kml track creation
%       [ ] simplify how header information is input/updated (have it all
%           be changed in one place in the script instead of several lines
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	FirstVersion: 	05 April 2023
%	Updated:        10 May 2023
%
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize agate - either specify a .cnf or leave blank to browse/select
agate agate_mission_config.cnf

global CONFIG


%% (1) Generate targets file from Google Earth path saved as .kmml

% specify file name to .kml path
kmlFile = fullfile(CONFIG.path.mission, 'exampleTrack.kml');
% OR
% leave empty and will prompt to select .kml path
kmlFile = []; 

% specify radius
radius = 2000;

% create targets file, 3 options to name waypoints
% (1) prefix-based automated naming
prefix = 'WP'; % Any two letters make easy to reference and read options
targetsOut = makeTargetsFile(CONFIG, kmlFile, prefix, radius);
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

% create plot
mapPlannedTrack(CONFIG, targetsFile, CONFIG.glider, bathyOn, figNum)


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
bathyFile = 'C:\GIS\etopo\ETOPO2022_bedrock_30arcsec_MHI.tiff';
plotTrackBathyProfile(CONFIG, targetsFile, bathyFile, figNum)
% OR leave empty to prompt to select file
plotTrackBathyProfile(CONFIG, targetsFile, [], figNum)

% save as .png
exportgraphics(gcf, fullfile(CONFIG.path.mission, [CONFIG.glider '_' ...
	CONFIG.mission, '_targetsBathymetryProfile_' targetsName, '.png']), ...
    'Resolution', 300)

%% (4) Calculate track distance and mission duration

% if no targetsFile specified, will prompt to select
[targets, targetsFile] = readTargetsFile(CONFIG);
% OR specify targetsFile variable from above
[targets, targetsFile] = readTargetsFile(CONFIG, targetsFile);

% loop through all targets (expect RECV), calc distance between waypoints
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
