% WORKFLOW_PROCESSPOSITIONALDATA.M
%	Process glider positional data at the end of a mission
%
%	Description:
%		This script provides a workflow for processing Seaglider positional
%		data after the end of a mission. It reads in basestation-generated
%		.nc files and reorganizes the data into two output tables:
%
%       gpsSurfT - gps surface table
%       locCalcT - calculated location table (dead reckoned track)
%       Both tables are saved as .mat and .csv
%
%       It requires an agate configuration file during agate initialization
%
%   Sections
%       (0) Initialization - initializes agate with proper config file
%       (1) Extract positional data - create `locCalcT` and `gpsSurfT` 
%       tables with glider timing, positions, speed, etc
%       (2) Simplify positional data into smaller .csvs for to include with
%       as metadata when sending sound files to NCEI
%       (3) Plot sound speed profiles
%
%	Notes
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	Updated:      23 January 2025
%
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize agate

% make sure agate is on the path!
addpath(genpath('C:\Users\User.Name\Documents\MATLAB\agate'))

% initialize with specified configuration file, 'agate_config.cnf'
CONFIG = agate('agate_config.cnf');

% OR

% initialize with prompt to select configuration file
CONFIG = agate;

%% (1) Extract positional data
% This step can take some time to process through all .nc files

[gpsSurfT, locCalcT] = extractPositionalData(CONFIG, 1);
% 0 in plotOn argument will not plot 'check' figures, but change to 1 to
% plot basic figures for output checking

% save as .mat and .csv
save(fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.gmStr, '_gpsSurfaceTable.mat']), 'gpsSurfT');
writetable(gpsSurfT,fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.gmStr, '_gpsSurfaceTable.csv']))

save(fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.gmStr, '_locCalcT.mat']),'locCalcT');
writetable(locCalcT, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.gmStr, '_locCalcT.csv']));

%% (2) Simplify positional data for packaging for NCEI

% surface location table
% load gpsSurfT if not already loaded
if ~exist('gpsSurfT', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.gmStr, '_gpsSurfaceTable.mat']));
end

% clean up columns/names
keepCols = {'dive', 'startDateTime', 'startLatitude', 'startLongitude', ...
	'endDateTime', 'endLatitude', 'endLongitude'};
gpsSurfSimp = gpsSurfT(:,keepCols);
newNames = {'DiveNumber', 'StartDateTime_UTC', 'StartLatitude', 'StartLongitude', ...
	'EndDateTime_UTC', 'EndLatitude', 'EndLongitude'};
gpsSurfSimp.Properties.VariableNames = newNames;

% write to csv
writetable(gpsSurfSimp, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.gmStr, '_GPSSurfaceTableSimple.csv']))

% claculated location table
% load locCalcT if not already loaded
if ~exist('locCalcT', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.gmStr, '_locCalcT.mat']))
end

% clean up columns/names
keepCols = {'dateTime', 'latitude', 'longitude', 'depth', 'dive'};
locCalcSimp = locCalcT(:,keepCols);
newNames = {'DateTime_UTC', 'Latitude', 'Longitude', 'Depth_m', 'DiveNumber'};
locCalcSimp.Properties.VariableNames = newNames;

% write to csv
writetable(locCalcSimp, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.gmStr, '_CalculatedLocationTableSimple.csv']))

% environmental data
% load locCalcT if not already loaded
if ~exist('locCalcT', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.gmStr, '_locCalcT.mat']))
end

% clean up columns/names
keepCols = {'dive', 'dateTime', 'latitude', 'longitude', 'depth', ...
	'temperature', 'salinity', 'soundVelocity', 'density'};
locCalcEnv = locCalcT(:,keepCols);
newNames = {'DiveNumber', 'DateTime_UTC', 'Latitude', 'Longitude', 'Depth_m', ...
	'Temperature_C', 'Salinity_PSU', 'SoundSpeed_m_s', 'Density_kg_m3', };
locCalcEnv.Properties.VariableNames = newNames;

% write to csv
writetable(locCalcEnv, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.gmStr, '_CTD.csv']))

%% (3) Plot sound speed profile

% load locCalcT if not already loaded
if ~exist('locCalcT', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.glider, '_', CONFIG.mission, '_locCalcT.mat']))
end

plotSoundSpeedProfile(CONFIG, locCalcT);

% save as .png and .pdf
exportgraphics(gcf, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.gmStr, '_SSP.png']))
exportgraphics(gcf, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.gmStr, '_SSP.pdf']))
