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

agate agate_config_sg639_MHI_Apr2023.cnf

global CONFIG

%% %%%%% SET UP %%%%%%

glider = CONFIG.glider; %'sg639';
mission = CONFIG.mission; %'MHI_Apr2023';

% Select .kml file
[kmlFileName, kmlPath] = uigetfile([CONFIG.path.mission '\*.kml'], 'Select .kml track');
kmlFile = fullfile(kmlPath, kmlFileName);
[~, kmlName, kmlExt] = fileparts(kmlFileName);

% kml saves the vertices of lines as decimal degrees in a code snippet like
% % this: 
% 		<Placemark>
% 			<name>Leeward Glider</name>
% 			<styleUrl>#inline13</styleUrl>
% 			<LineString>
% 				<tessellate>1</tessellate>
% 				<coordinates>
% 					-159.3180977061045,21.93379120241162,0 -159.3915294840902,21.50741673680377,0 -158.8809373915385,21.73528994893612,0 -158.9763412128043,21.27910694076397,0 -158.4324636016379,21.47030430788609,0 -158.5300178504395,20.97351624005566,0 -158.0118868380484,21.04165660408255,0 -157.9015894020643,20.52832280966129,0 -157.3568488495222,20.82859768139042,0 -157.5622783640389,20.30084306318159,0 -157.0340176577208,20.63583528150905,0 -157.2485263069477,20.08415381579547,0 -156.5958158941286,20.38616727824648,0 -156.9019851472443,19.83461456110239,0 -156.1842310583716,20.20053668786948,0 -156.557056073062,19.59525648291685,0 -156.1124900576321,19.74835140750147,0 
% 				</coordinates>
% 			</LineString>
% 		</Placemark>
% FOR NOW
% search for the name of the path you want and find the coordinates line.
% then just copy and paste the coordinates into a text file alone. 
% Select .txt coordinates file
[txtCoordFileName, txtCoordPath] = uigetfile([kmlPath '\*.txt'], 'Select .txt coordinate file');
txtCoordFile = fullfile(txtCoordPath, txtCoordFileName);

% read in the coords and rearrange in a readable way
fid = fopen(txtCoordFile, 'r');
decDegCoords = textscan(fid, '%f%f%f', 'delimiter', ',', 'CollectOutput',1);
fclose(fid);
decDegCoords = decDegCoords{1,1}; % convert to array
decDegCoords = decDegCoords(:,1:2); % get rid of the "z" coord which should be 0s

% convert to deg decmins
degMinLons = decdeg2degmin(decDegCoords(:,1));
degMinLats = decdeg2degmin(decDegCoords(:,2)); 

% define waypoint names
% wpNames = {'WW01', 'WW02', 'WW03', 'WW04', 'WW05', 'WW06', 'WW07', 'WW08', ...
%     'WW09', 'WW10', 'WW11', 'WW12', 'WW13', 'WW14', 'WW15', 'WW16', ...
%     'WW17', 'RECV'}';

wpNames = {'WW01', 'WWaa', 'WW02', 'WWab', 'WW03', 'WW04', 'WW05', 'WWac', ... 
    'WW06', 'WWad', 'WW07', 'WWae', 'WW08', 'WWaf', 'WW09', 'WWag', 'WW10', ... 
    'WWah', 'WW11', 'WWai', 'WW12', 'WWaj', 'WW13', 'WWak', 'WW14', 'WWal', ...
    'WW15', 'WWam', 'WWan', 'WW16', 'WWao', 'WWap', 'WW17', 'WWaq', 'WWar', ...
    'RECV'}';

%% %%%%% WRITE TARGETS FILE %%%%%
% now write it into a targets file
% example header text
% / Glider survey plan for UxS MHI April 2023
% / Deployment will take place at WW01
% / template WW01 lat= lon= radius=2000 goto=WW02
% / radius set to 2000 m

targetsOut = fullfile(kmlPath, ['targets_' kmlName]);
fid = fopen(targetsOut, 'w');

fprintf(fid, '%s\n', '/ Glider survey plan for UxS MHI April 2023 - SG639 - Windward Glider');
fprintf(fid, '%s\n', '/ Deployment will take place at WW01, recovery at RECV');

fprintf(fid, '%s\n', '/ template WPxx lat=DDMM.MMMM lon=DDDMM.MMMM radius=2000 goto=WPo');
fprintf(fid, '%s\n', '/ radius set to 2000 m');

for f = 1:length(wpNames)-1
fprintf(fid, '%s lat=%d%07.4f lon=%d%07.4f radius=2000 goto=%s\n', ...
    wpNames{f}, degMinLats(f,1), degMinLats(f,2), degMinLons(f,1), degMinLons(f,2), wpNames{f+1});
end
f = length(wpNames);
fprintf(fid, '%s lat=%d%07.4f lon=%d%07.4f radius=2000 goto=%s', ...
    wpNames{f}, degMinLats(f,1), degMinLats(f,2), degMinLons(f,1), degMinLons(f,2), wpNames{f});
fclose(fid);


%% %%%%%% CREATE PLOT %%%%%%

% Set up map configuration
bathyOn = 1;
figNum = 26;

targetsFile = targetsOut;
mapPlannedTrack(CONFIG, targetsFile, CONFIG.glider, bathyOn, figNum)


%% 2 - print/save interpolated track map
set(gcf, 'Position', [80 50 1600 1200]) % make it big to save it
set(gcf, 'InvertHardCopy', 'off', 'color', 'w');

print(fullfile(CONFIG.path.mission, [CONFIG.glider '_' CONFIG.mission, ...
    '_plannedTrack_' kmlName, '.png']), '-dpng')
savefig(fullfile(CONFIG.path.mission, [CONFIG.glider '_' CONFIG.mission, ...
    '_plannedTrack_' kmlName, '.fig']))

% exporting to EPS or PDF requires the export_fig toolbox available at 
%  https://github.com/altmany/export_fig
export_fig(fullfile(CONFIG.path.mission, [CONFIG.glider '_' CONFIG.mission, ...
    '_plannedTrack_' kmlName, '.eps']), '-eps', '-painters');
export_fig(fullfile(CONFIG.path.mission, [CONFIG.glider '_' CONFIG.mission, ...
    '_plannedTrack_' kmlName, '.pdf']), '-pdf', '-painters');

% shrink back down
set(gcf, 'Position', [100 100 800 600]); % make it reasonable again. 

