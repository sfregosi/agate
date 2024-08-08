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
%       (4) PAM status get more accurate info on recording times and
%       durations from the files themselves, and update positional data
%       tables with a flag for PAM on or off at each sample or dive
%       (5) Extract location data for each individual PAM file
%       (6) Summarize acoustic effort by minutes, hours, and days
%
%	Notes
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	FirstVersion: 	21 April 2023
%	Updated:        08 August 2024
%
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize agate
CONFIG = agate('agate_mission_config.cnf'); % or just agate and select file

%% (1) Extract positional data
% This step can take some time to process through all .nc files

[gpsSurfT, locCalcT] = extractPositionalData(CONFIG, 1);
% 0 in plotOn argument will not plot 'check' figures, but change to 1 to
% plot basic figures for output checking

% save as .mat and .csv
save(fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.glider, '_', CONFIG.mission, '_gpsSurfaceTable.mat']), 'gpsSurfT');
writetable(gpsSurfT,fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.glider, '_', CONFIG.mission, '_gpsSurfaceTable.csv']))

save(fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.glider, '_', CONFIG.mission, '_locCalcT.mat']),'locCalcT');
writetable(locCalcT, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.glider, '_', CONFIG.mission, '_locCalcT.csv']));

%% (2) Simplify positional data for packaging for NCEI

% surface location table
% load gpsSurfT if not already loaded
if ~exist('gpsSurfT', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.glider, '_', CONFIG.mission, '_gpsSurfaceTable.mat']));
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
	[CONFIG.glider, '_', CONFIG.mission, '_GPSSurfaceTableSimple.csv']))

% claculated location table
% load locCalcT if not already loaded
if ~exist('locCalcT', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.glider, '_', CONFIG.mission, '_locCalcT.mat']))
end

% clean up columns/names
keepCols = {'dateTime', 'latitude', 'longitude', 'depth', 'dive'};
locCalcSimp = locCalcT(:,keepCols);
newNames = {'DateTime_UTC', 'Latitude', 'Longitude', 'Depth_m', 'DiveNumber'};
locCalcSimp.Properties.VariableNames = newNames;

% write to csv
writetable(locCalcSimp, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.glider, '_', CONFIG.mission, '_CalculatedLocationTableSimple.csv']))

% environmental data
% load locCalcT if not already loaded
if ~exist('locCalcT', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.glider, '_', CONFIG.mission, '_locCalcT.mat']))
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
	[CONFIG.glider, '_', CONFIG.mission, '_CTD.csv']))

%% (3) Plot sound speed profile

% load locCalcT if not already loaded
if ~exist('locCalcT', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.glider, '_', CONFIG.mission, '_locCalcT.mat']))
end

plotSoundSpeedProfile(CONFIG, locCalcT);

% save as .png and .pdf
exportgraphics(gcf, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.glider, '_', CONFIG.mission, '_SSP.png']))
exportgraphics(gcf, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.glider, '_', CONFIG.mission, '_SSP.pdf']))


%% (4) Extract acoustic system status for each dive and sample time

% load locCalcT and gpsSurfT if not already loaded
if ~exist('locCalcT', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.glider, '_', CONFIG.mission, '_locCalcT.mat']))
end
if ~exist('gpsSurfT', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.glider, '_', CONFIG.mission, '_gpsSurfaceTable.mat']));
end

% loop through sound files to gets 'status' for existing positional tables
[gpsSurfT, locCalcT, pamFiles, pamByDive] = extractPAMStatus(CONFIG, ...
	gpsSurfT, locCalcT);

fprintf('Total PAM duration: %.2f hours\n', hours(sum(pamFiles.dur, 'omitnan')));

% save updated positional tables and pam tables
save(fullfile(CONFIG.path.mission, 'profiles', [CONFIG.glider, '_', ...
	CONFIG.mission, '_pamFiles.mat']), 'pamFiles');
save(fullfile(CONFIG.path.mission, 'profiles', [CONFIG.glider, '_', ...
	CONFIG.mission, '_pamByDive.mat']), 'pamByDive');

save(fullfile(CONFIG.path.mission, 'profiles', [CONFIG.glider '_' ...
	CONFIG.mission '_locCalcT_pam.mat']), 'locCalcT');
writetable(locCalcT, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.glider '_' CONFIG.mission '_locCalcT_pam.csv']));

save(fullfile(CONFIG.path.mission, 'profiles', [CONFIG.glider '_' ...
	CONFIG.mission '_gpsSurfaceTable_pam.mat']), 'gpsSurfT');
writetable(gpsSurfT, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.glider '_' CONFIG.mission '_gpsSurfaceTable_pam.csv']));


%% (5) Extract positional data for each sound file

% load locCalcT and pamFiles if not already loaded
if ~exist('locCalcT', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.glider, '_', CONFIG.mission, '_locCalcT.mat']))
end
if ~exist('pamFiles', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.glider, '_', CONFIG.mission, '_pamFiles.mat']))
end

% set a time buffer around which locations are acceptable
timeBuffer = 180;
% get position at start of each sound file
pamFilePosits = extractPAMFilePosits(pamFiles, locCalcT, timeBuffer);

% save as .mat and .cs 
save(fullfile(CONFIG.path.mission, 'profiles', [CONFIG.glider '_' ...
	CONFIG.mission '_pamFilePosits.mat']), 'pamFilePosits');
writetable(pamFilePosits, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.glider '_' CONFIG.mission '_pamFilePosits.csv']));


%% (6) Summarize acoustic effort

% load gpsSurfT, pamFiles, pamByDive if not already loaded
if ~exist('gpsSurfT', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.glider, '_', CONFIG.mission, '_gpsSurfaceTable.mat']))
end
if ~exist('pamFiles', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.glider, '_', CONFIG.mission, '_pamFiles.mat']))
end
if ~exist('pamByDive', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.glider, '_', CONFIG.mission, '_pamByDive.mat']))
end

% create byMin, minPerHour, minPerDay matrices 
[pamByMin, pamMinPerHour, pamMinPerDay, pamHrPerDay] = calcPAMEffort(...
	CONFIG, gpsSurfT, pamFiles, pamByDive);

% save as .mat
save(fullfile(CONFIG.path.mission, 'profiles', [CONFIG.glider '_' ...
	CONFIG.mission '_pamEffort.mat']), ...
    'pamByMin', 'pamMinPerHour', 'pamMinPerDay', 'pamHrPerDay');

