% WORKFLOW_CONVERTWISPR.M
%	Workflow for converting raw WISPR data into .flac or .wav files
%
%	Description:
%		This script provides the some example steps to convert a directory
%		(or directories) of raw WISPR .dat files into a more readable
%		format, either .flac or .wav. Regardless of which example is used,
%		the user will need to update the path to agate in the first line.
% 
%       The first section provides three example uses where no agate
%       mission configuration file is needed. This is useful for
%       non-Seaglider based missions (Hefring Oceanscout or TWR Slocum) or
%       for quick conversions of small test datasets. As few or as many 
%       input arguments can be specified. 
% 
%       The first section provides examples if the user has a mission
%       configuration file and is useful for batch processing after a full
%       mission to avoid manual selection of directories and settings. 
%       First, agate is initialized using this mission configuration file 
%       that contains CONIFG.ws.inDir, CONFIG.ws.outDir, and/or 
%       CONFIG.ws.outExt to define the paths to the input directory of raw 
%       files, the target output directory, and the desired output format 
%       ('.flac' or '.wav') respectively. If a configuration file is not 
%       specified, a blank config file is provided, or either of those
%       configuration settings are not specified in the file, the
%       convertWispr function will prompt the user to select the desired
%       folders and will default to .flac output format. 
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

%% 1 - No mission configuration file needed

% 1a - No input arguments will prompt for directories, write to .flac
convertWispr;

% 1b - Write to .wav and do not print progress, will prompt for directories
convertWispr('outExt', '.wav', 'showProgress', false)

% 1c - Specify paths without CONFIG file, will write to .flac (default)
convertWispr('inDir', 'C:\raw_files', 'outDir', 'C:\flac_files')

%% 1 - Using a configuration file and all defaults

% initialize agate with a configuration file
% this can be empty but setting CONFIG.ws.inDir and CONFIG.ws.outDir
% streamlines processing so directories do not need to be manually selected
% in the event of a restart
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