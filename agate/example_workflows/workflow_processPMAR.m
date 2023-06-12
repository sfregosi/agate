% WORKFLOW_PROCESSPMAR
%	Process PMAR acoustic data from .dat to .wav files
%
%	Description:
%       This script converts raw PMAR .dat files to .wav files for further
%       acoustic analysis. It relies on the convertPMAR functions written
%       by Dave Mellinger (Oregon State University) 
% 
%       A modified version of these functions are included with agate, or 
%       the standalone functions can be downloaded from the Mathworks File
%       Exchange: 
%           https://www.mathworks.com/matlabcentral/fileexchange/107245-
%              convert-seaglider-pmar-xl-sound-files-to-wav-format
%
%	See also
%
%   TO DO:
% 
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	FirstVersion: 	8 June 2023
%	Updated:        
%
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize agate - either specify a .cnf or leave blank to browse/select
agate agate_mission_config.cnf

global CONFIG

% map path to setup folder in agate 
addpath 'C:\Users\Selene.Fregosi\Documents\MATLAB\agate\setup'

% run the configuration file 
pmarConvertConfig_sg639_HI_Apr22
% pmarConvertConfig_sg680_HI_Apr22

% convert!
convertPmarFun(CONFIG)