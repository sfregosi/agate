% WORKFLOW_ACOUSTICEFFORT.M
%	Calculate acoustic effort in space/time after a mission
%
%	Description:
%		This script provides a workflow for processing Seaglider positional
%		data and Seaglider-collected acoustic data to assess acoustic
%		effort in space and time after the end of a mission. 
% 
%       It requires previously processed positional data as gpsSurfT and 
%       locCalcT .mat files (see workflow_processPositionalData.m), sound 
%       files in .wav or .flac format, and an agate mission configuration
%       file.
%
%   Sections
%       (0) Initialization - initializes agate with proper config file
%       (1) PAM status get more accurate info on recording times and
%       durations from the files themselves, and update positional data
%       tables with a flag for PAM on or off at each sample or dive
%       (2) Extract location data for each individual PAM file
%       (3) Summarize acoustic effort by minutes, hours, and days
%
%	Notes
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	Updated:   2 January 2025
%
%	Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize agate

% make sure agate is on the path!
addpath(genpath('C:\Users\User.Name\Documents\MATLAB\agate'))

% initialize with specified configuration file, 'agate_config.cnf'
CONFIG = agate('agate_config.cnf');

% OR

% initialize with prompt to select configuration file
CONFIG = agate;

%% (1) Extract acoustic system status for each dive and sample time

% load locCalcT and gpsSurfT if not already loaded
if ~exist('locCalcT', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.gmStr, '_locCalcT.mat']))
end
if ~exist('gpsSurfT', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.gmStr, '_gpsSurfaceTable.mat']));
end

% loop through sound files to gets 'status' for existing positional tables
[gpsSurfT, locCalcT, pamFiles, pamByDive] = extractPAMStatus(CONFIG, ...
	gpsSurfT, locCalcT);

fprintf('Total PAM duration: %.2f hours\n', hours(sum(pamFiles.dur, 'omitnan')));

% save updated positional tables and pam tables
save(fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.gmStr, '_pamFiles.mat']), 'pamFiles');
save(fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.gmStr, '_pamByDive.mat']), 'pamByDive');

save(fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.gmStr '_locCalcT_pam.mat']), 'locCalcT');
writetable(locCalcT, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.gmStr '_locCalcT_pam.csv']));

save(fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.gmStr '_gpsSurfaceTable_pam.mat']), 'gpsSurfT');
writetable(gpsSurfT, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.gmStr '_gpsSurfaceTable_pam.csv']));


%% (2) Extract positional data for each sound file

% load locCalcT and pamFiles if not already loaded
if ~exist('locCalcT', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.gmStr, '_locCalcT.mat']))
end
if ~exist('pamFiles', 'var')
	load(fullfile(CONFIG.path.mission, 'profiles', ...
		[CONFIG.gmStr, '_pamFiles.mat']))
end

% set a time buffer around which locations are acceptable
timeBuffer = 180;
% get position at start of each sound file
pamFilePosits = extractPAMFilePosits(pamFiles, locCalcT, timeBuffer);

% save as .mat and .cs 
save(fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.gmStr '_pamFilePosits.mat']), 'pamFilePosits');
writetable(pamFilePosits, fullfile(CONFIG.path.mission, 'profiles', ...
	[CONFIG.gmStr '_pamFilePosits.csv']));


%% (3) Summarize acoustic effort

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

