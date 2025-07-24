% WORKFLOW_CONVERTWISPR.M
%	Workflow for converting raw WISPR data into .flac or .wav files
%
%	Description:
%		This script provides the some example steps to convert a directory
%		(or directories) of raw WISPR .dat files into a more readable
%		format, either .flac or .wav. Each section of the script is an
%		alternative approach with different input arguments. 
%
%       The user will need to update the path to agate. Optionallly, the
%       user can specify the name/location of a mission configuration file
%       that contains CONIFG.ws.inDir and CONFIG.ws.outDir to define the
%       paths to the input directory of raw files and the target output
%       directory, respectively. If a configuration file is not specified
%       (or a blank one is used), the convertWispr function will prompt the
%       user to select the desired folders. 
%
%       Currently, the input directory must either be a directory named
%       with the date or a directory full of subdirectories where each
%       subdirectory is named with the date using the format 'YYMMDD',
%       (e.g., 230504 for 4 May 2023). 
%
%	Notes
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	Updated:      2025 July 23
%
%	Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% add agate to the path
addpath(genpath('C:\Users\User.Name\Documents\MATLAB\agate'))

%% Using a configuration file and all defaults

% initialize agate
% this can be empty but setting CONFIG.ws.inDir and CONFIG.ws.outDir will
% streamline processing so the directories do not need to be manually
% selected
CONFIG = agate('agate_mission_config.cnf');

% process all the files!
convertWispr(CONFIG);
% By default this will write to .flac files and will print progress to the
% Command Window. If the CONFIG file is empty it will prompt for
% input/output directories. 

% If the process is interrupted at any point, it is possible to restart at
% a specified subdirectory. WISPR typically saves raw .dat files in folders
% by date with the format 'YYMMDD', so enter the name of the dated 
% subdirectory as a 6 digit string to restart there
convertWispr(CONFIG, 'restartDir', '240919');

%% No configuration file will prompt for directories, write to .flac

% write to default .flac
convertWispr;

%% Write to .wav and do not print progress

% will prompt to select directories
convertWispr('outExt', '.wav', 'showProgress', false)

%% Specify paths without CONFIG file

% will write default .flac and show progress
convertWispr('inDir', 'C:\raw_files', 'outDir', 'C:\flac_files')
