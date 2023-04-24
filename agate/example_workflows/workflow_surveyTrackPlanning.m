% WORKFLOW_SURVEYTRACKPLANNING
%	Planned mission path kmls to targets file and pretty map
%
%	Description:
%		This script takes a survey track created in Google Earth and saved
%		as a .kml file and prepares it for the survey
%       (1) creates a properly formatted 'targets' file to be loaded onto
%       the glider
%       (2) creates a high quality planned survey map
%
%	Notes
%       This requires access to bathymetric basemaps for plotting and
%       requires manual creation of the track in Google Earth
%
%	See also
%
%   TO DO:
%       [ ] automate the text coordinates extraction step from the kml
%           being read in
%       [ ] link to documentation on kml track creation
%       [ ] automate waypoint name generation, or allow to be imported from
%           a text file or excel sheet?
%       [ ] simplify how header information is input/updated (have it all
%           be changed in one place in the script instead of several lines
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	05 April 2023
%	Updated:        20 April 2023
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

agate agate_config_sg679_MHI_Apr2023.cnf

global CONFIG


% generate targets file from trackline created in Google Earth and exported
% as .kml
kmlFile = fullfile(CONFIG.path.mission, 'sg679_draft_2023-04-20.kml');
targetsOut = makeTargetsFile(CONFIG, kmlFile, 'LW');
[targetsPath, targetsName, ~] = fileparts(targetsOut);

% create targets plot 
% Set up map configuration
bathyOn = 1;
figNum = 26;

targetsFile = targetsOut;
mapPlannedTrack(CONFIG, targetsFile, CONFIG.glider, bathyOn, figNum)


%% 2 - print/save interpolated track map
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

