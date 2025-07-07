% WORKFLOW_DOWNLOADSCRIPT.M
%	Download basestation files and generate piloting/monitoring plots
%
%	Description:
%		This script provides a workflow that may be useful during an active
%		mission to assist with piloting. The idea is that the entire script
%		can be run after a glider surfacing to automate the process of
%		checking on the glider status
%
%       It has the following sections:
%       (1) any new basestation files to the local computer. This currently
%       includes .nc, .log, .dat, .eng files and WISPR (ws*) files. PMAR
%       files (pm*) are untested and cmdfiles/pdoscmds.bat files are not
%       updated since the switch to basestation3.
%       (2) extracts useful data from local basestation .nc and .log files
%       and compiles into a summary table, variable 'pp', and saves to a
%       .xlsx and .mat
%       (3) generates several piloting monitoring plots and saves as .pngs
%       (4) prints out calculated mission speeds and estimates of total
%       duration
%
%       It requires an agate configuration file during agate initialization
%       that includes the basestation configuration section, the acoustic
%       configuration section (if running an acoustic system), and the
%       plotting configuration section.
%
%	Notes
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	01 June 2023
%	Updated:        10 September 2024

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize agate
CONFIG = agate('agate_mission_config.cnf');

% specify the local piloting folder for this trip in CONFIG.path.mission
% set up nested folders for basestation files and piloting outputs
path_status = fullfile(CONFIG.path.mission, 'flightStatus'); % where to store output plots/tables
path_bsLocal = fullfile(CONFIG.path.mission, 'basestationFiles'); % local copy of basestation files
% this also can be set as CONFIG.path.bsLocal in the mission cnf file

% make the dirs if they don't exist
mkdir(path_status);
mkdir(path_bsLocal);

%% (1) download files from the basestation
downloadBasestationFiles(CONFIG)

% In MATLAB 2024b onward/with seaglider.pub (not sure which change is
% responsible) the SFTP connection can timeout or be throttled resulting in
% an FTP error 0 that interupts a download. This error will print but the
% loop will continue. If those errors are present, just re-run
% downloadBasestationFiles until no more files/errors occur. 

% To plot Seaglider Piloting Tools plots at this point, run DiveData below
% DiveData

%% (2) extract piloting parameters

% create piloting parameters (pp) table from downloaded basestation files
pp = extractPilotingParams(CONFIG, CONFIG.path.bsLocal, path_status, 0);
% change last argument from 0 to 1 to load existing data and append new dives/rows

% save it to the default location as .mat and .xlsx
save(fullfile(CONFIG.path.mission, 'flightStatus', ['diveTracking_' ...
	CONFIG.glider '.mat']), 'pp');
writetable(pp, fullfile(path_status, ['diveTracking_' CONFIG.glider '.xlsx']));

%% (3) generate and save plots

% print map **SLOWISH** - figNumList(1)
targetsFile = fullfile(CONFIG.path.mission, 'targets'); 
mapMissionPath(CONFIG, pp, 'targetsFile', targetsFile);

% save it as a .fig (for zooming)
savefig(fullfile(path_status, [CONFIG.glider '_map.fig']))
% and as a .png (for quick/easy view)
exportgraphics(gca, fullfile(path_status, [CONFIG.glider '_map.png']), ...
    'Resolution', 300)

% humidity and pressure - figNumList(2)
plotHumidityPressure(CONFIG, pp)
print(fullfile(path_status, [CONFIG.glider  '_humidityPressure.png']), '-dpng')

% battery usage/free space - figNumList(3)
plotBattUseFreeSpace(CONFIG, pp, 310)
print(fullfile(path_status, [CONFIG.glider '_battUseFreeSpace.png']), '-dpng')

% voltage pack use (power draw by device) - figNumList(4)
plotVoltagePackUse(CONFIG, pp)
print(fullfile(path_status, [CONFIG.glider '_usageByDevice.png']), '-dpng')

% voltage pack use (power draw by device, normalized by dive duration) - figNumList(5)
plotVoltagePackUse_norm(CONFIG, pp)
print(fullfile(path_status, [CONFIG.glider '_usageByDevice_normalized.png']), '-dpng')

% minimum reported voltages - figNumList(6)
plotMinVolt(CONFIG, pp)
print(fullfile(path_status, [CONFIG.glider '_minimumVoltage.png']), '-dpng')
% close

% PMAR space used per minute and over time (IF PMAR IS ACTIVE)
plotPmUsed(CONFIG, pp) 

% ERMA detection events from the most recent dive (IF WISPR/ERMA IS ACTIVE)
plotErmaDetections(CONFIG, path_bsLocal, pp.diveNum(end))

%% (4) print mission summary

% print errors reported on most recent dive
printErrors(CONFIG, size(pp,1), pp)

% print avg speed and rough estimate of total mission duration
tm = printTravelMetrics(CONFIG, pp, fullfile(CONFIG.path.mission, ...
	'targets'), 1);

% specify planned recovery date and time
recovery = '2023-00-00 00:00:00';
recTZ = 'America/Los_Angeles';
tm = printRecoveryMetrics(CONFIG, pp, fullfile(CONFIG.path.mission, ...
	'targets'), recovery, recTZ, 1);

