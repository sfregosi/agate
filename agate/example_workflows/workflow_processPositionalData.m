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
%	Notes
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	FirstVersion: 	21 April 2023
%	Updated:        11 April 2024
%
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize agate
agate agate_mission_config.cnf
global CONFIG

%% extract positional data
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

%% save positional data for packaging for NCEI

% gps surface table
load(fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.glider, '_', CONFIG.mission, '_gpsSurfaceTable.mat']));
keepCols = {'dive', 'startDateTime', 'startLatitude', 'startLongitude', ...
	'endDateTime', 'endLatitude', 'endLongitude'};
gpsSurfSimp = gpsSurfT(:,keepCols);
newNames = {'DiveNumber', 'StartDateTime_UTC', 'StartLatitude', 'StartLongitude', ...
	'EndDateTime_UTC', 'EndLatitude', 'EndLongitude'};
gpsSurfSimp.Properties.VariableNames = newNames;
writetable(gpsSurfSimp, fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.glider, '_', CONFIG.mission, '_GPSSurfaceTableSimple.csv']))

% location table
load(fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.glider, '_', CONFIG.mission, '_locCalcT.mat']))
keepCols = {'dateTime', 'latitude', 'longitude', 'depth', 'dive'};
locCalcSimp = locCalcT(:,keepCols);
newNames = {'DateTime_UTC', 'Latitude', 'Longitude', 'Depth_m', 'DiveNumber'};
locCalcSimp.Properties.VariableNames = newNames;
writetable(locCalcSimp, fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.glider, '_', CONFIG.mission, '_CalculatedLocationTableSimple.csv']))

% environmental data
load(fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.glider, '_', CONFIG.mission, '_locCalcT.mat']))
keepCols = {'dive', 'dateTime', 'latitude', 'longitude', 'depth', ...
	'temperature', 'salinity', 'soundVelocity', 'density'};
locCalcEnv = locCalcT(:,keepCols);
newNames = {'DiveNumber', 'DateTime_UTC', 'Latitude', 'Longitude', 'Depth_m', ...
	'Temperature_C', 'Salinity_PSU', 'SoundSpeed_m_s', 'Density_kg_m3', };
locCalcEnv.Properties.VariableNames = newNames;
writetable(locCalcEnv, fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.glider, '_', CONFIG.mission, '_CTD.csv']))

%% plot sound speed profile
% load locCalcT if not already loaded
if ~exist('locCalcT', 'var')
    load(fullfile(CONFIG.path.mission, 'profiles', ...
        [CONFIG.glider, '_', CONFIG.mission, '_locCalcT.mat']))
end

plotSoundSpeedProfile(CONFIG, locCalcT);
exportgraphics(gcf, fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.glider, '_', CONFIG.mission, '_SSP.png']))
exportgraphics(gcf, fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.glider, '_', CONFIG.mission, '_SSP.pdf']))

%% BELOW SECTIONS ARE NOT YET OPERATIONAL
% Below called functions are in the 'drafts' folder and need to be adapted
% for WISPR2 and also updated to new CONFIG system of agate

%% extract acoustic system status for each dive and sample time

% *** NEEDS WORK! *** to be updated to deal with WISPR2 and speed up with
% PMARXL using .eng files rather than having to read in list of sound files

% % this looks at each recorded file timestamp to populate a 'pam' column
% % that is added to locCalcT and gpsSurfT that specifies the status of the
% % pam system for each entry. 
% 
% fileLength = 600; % in seconds
% dateFormat = 'yyMMdd-HHmmss';
% dateStart = 1; % what part of file name starts the date format
% 
% [gpsSurfT, locCalcT, pam] = extractPAMStatusByFile(gldr, lctn, dplymnt, ...
%     fileLength, dateFormat, dateStart, gpsSurfT, locCalcT);
% % saved automatically gpsSurfTable_pam.mat and locCalcT_pam.mat and
% % _pamByFile.mat


%% extract positional data for each sound file
% 
% secs = 180;
% 
% filePosits = extractPositsPerPAMFile(gldr, lctn, dplymnt, ...
%     pam, locCalcT,secs, path_profiles);
% 
% % this saves _pamFilePosits.mat and .csv

%% extract positional data and acoustic effort by minute

% % create byMin, minPerHour, minPerDay matrices for full experiment extent
% % will need this for comparison down the line
% [pamByMin, pamMinPerHour, pamMinPerDay] = ...
%     calcPAMEffort(gldr, lctn, dplymnt, expLimits, gpsSurfT, path_profiles);
% % this saves _pamByMin.mat
% 
% 

