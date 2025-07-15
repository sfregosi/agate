% WORKFLOW_EXPORTWISPRSENSITIVITY.M
%	One-line description here, please
%
%	Description:
%		Detailed description here, please
%
%	Notes
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	Updated:   2025 July 07
%
%	Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% make sure agate is on the path!
% addpath(genpath('C:\Users\User.Name\Documents\MATLAB\agate'))
addpath(genpath('C:\Users\selene.fregosi\Documents\MATLAB\agate'))


%% convert to .wav or .flac if needed
% this can be useful to browse through several files recorded to find one
% with a complete calibration signal

convertWispr;
% this will prompt to select the raw file location and the output file 
% location and will default to writing to flac. Alternatively, specify more
% input arguments to avoid promts and choose wave output
% convertWispr('inDir', 'E:/wisprFiles', 'outDir', 'E:/wav', 'outExt', '.wav')

% identify a good candidate file
% 134457

%% Define some settings

% set to empty to prompt/use defaults
metadata = [];
path_out = [];
outType = 'both';   % 'netcdf' or 'csv' or 'both'
fRange = [1 70000]; % this is the frequency that is actually usable



sr = generateWisprSystemSensitivity(metadata, path_out, outType, fRange);

%% Test with WISPR2

metadata = [];
path_out = [];
outType = 'both';
fRange = [1 70000];



sr = generateWisprSystemSensitivity(metadata, path_out, outType, fRange);

%% Test with WISPR3

metadata = [];
path_out = [];
outType = 'both';
fRange = [1 70000];



sr = generateWisprSystemSensitivity(metadata, path_out, outType, fRange);