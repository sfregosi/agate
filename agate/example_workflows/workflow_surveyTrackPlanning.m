% WORKFLOW_SURVEYTRACKPLANNING
%	Planned mission path kmls to targets file and pretty map
%
%	Description:
%		This script takes a survey track created in Google Earth and saved
%		as a .kml file and prepares it for the survey
%       (1) creates a properly formatted 'targets' file to be loaded onto
%       the glider
%       (2) creates a high quality planned survey map
%       (3) calculates full planned track distance and distance to end from
%       each waypoint
%
%       This requires access to bathymetric basemaps for plotting and
%       requires manual creation of the track in Google Earth. Track must
%       be saved (right click on track name in left panel, save as) as a
%       .kml, containing just a single track path. 
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
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	05 April 2023
%	Updated:        25 April 2023
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

agate agate_mission_config.cnf

global CONFIG


%% (1) Generate targets file from trackline created in Google Earth and export
% as .kml
kmlFile = fullfile(CONFIG.path.mission, 'sg679_draft_2023-04-20.kml');
targetsOut = makeTargetsFile(CONFIG, kmlFile, 'LW');
[targetsPath, targetsName, ~] = fileparts(targetsOut);

% create targets plot 
% Set up map configuration
bathyOn = 1;
figNum = 26;


%% (2) Plot and print/save proposed track map

targetsFile = targetsOut;
mapPlannedTrack(CONFIG, targetsFile, CONFIG.glider, bathyOn, figNum)

set(gcf, 'Position', [80 50 1600 1200]) % make it big to save it
set(gcf, 'InvertHardCopy', 'off', 'color', 'w');

print(fullfile(CONFIG.path.mission, [CONFIG.glider '_' CONFIG.mission, ...
    '_plannedTrack_' targetsName, '.png']), '-dpng')
savefig(fullfile(CONFIG.path.mission, [CONFIG.glider '_' CONFIG.mission, ...
    '_plannedTrack_' targetsName, '.fig']))

% exporting to EPS or PDF requires the export_fig toolbox available at
%  https://github.com/altmany/export_fig
export_fig(fullfile(CONFIG.path.mission, [CONFIG.glider '_' CONFIG.mission, ...
    '_plannedTrack_' targetsName, '.eps']), '-eps', '-painters');
export_fig(fullfile(CONFIG.path.mission, [CONFIG.glider '_' CONFIG.mission, ...
    '_plannedTrack_' targetsName, '.pdf']), '-pdf', '-painters');

% shrink back down
set(gcf, 'Position', [100 100 800 600]); % make it reasonable again.

%% (3) Calculate full distance of track
% As well as distance to the end from each waypoint, which is useful in
% within-mission planning and adjustments

[targets, targetsFile] = readTargetsFile(CONFIG);

% loop through all targets (expect RECV)
for f = 1:height(targets) - 1
    [targets.distToNext_km(f), ~] = lldistkm([targets.lat(f+1) targets.lon(f+1)], ...
        [targets.lat(f) targets.lon(f)]);
end

[targetsPath, targetsName, ~] = fileparts(targetsFile);
fprintf(1, 'Total tracklength for %s: %.0f km\n', targetsName, sum(targets.distToNext_km));

