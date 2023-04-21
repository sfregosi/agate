% Workflow script for processing PMAR acoustic data 
% *** Example Script ***

% map path to setup folder in agate 
addpath 'C:\Users\Selene.Fregosi\Documents\MATLAB\agate\setup'

% run the configuration file 
pmarConvertConfig_sg639_HI_Apr22
% pmarConvertConfig_sg680_HI_Apr22

% convert!
convertPmarFun(CONFIG)