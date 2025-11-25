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


%% measure preamp gain curve
% IF NECESSARY see workflow_generatePreampGainCurve to measure a WISPR3
% gain curve from a known voltage sweep

% [preamp_freq, preamp_gain]= measureWisprSensitivity(sn, sweep_file, ...
%     hydro_sens, amp, attenuator, path_out);


%% Define some settings

% set to empty to prompt/use defaults
metadata = [];
path_out = [];
outType = 'both';   % 'netcdf' or 'csv' or 'both'
fRange = [1 70000]; % this is the frequency that is actually usable



sr = generateWisprSystemSensitivity(metadata, path_out, outType, fRange);

%% Test with WISPR2

metadata = [];
metadata = 'C:\Users\selene.fregosi\Documents\GitHub\glider-lab\calibration\mission_metadata\sg679_CalCurCEAS_Aug2024_WISPR2_HTI653007_wHydrophoneCalCurve.txt';
path_out = [];
path_out = 'C:\Users\selene.fregosi\Documents\GitHub\glider-lab\calibration';
outType = 'both';
fRange = [1 70000];



sr = generateWisprSystemSensitivity(metadata, path_out, outType, fRange);

%% Test with WISPR3

metadata = [];
metadata = 'C:\Users\selene.fregosi\Documents\GitHub\glider-lab\calibration\mission_metadata\sg680_CalCurCEAS_Sep2024_WISPR3_no2_HTI1211001.txt';
path_out = [];
path_out = 'C:\Users\selene.fregosi\Documents\GitHub\glider-lab\calibration';
outType = 'both';
fRange = [1 70000];



sr = generateWisprSystemSensitivity(metadata, path_out, outType, fRange);