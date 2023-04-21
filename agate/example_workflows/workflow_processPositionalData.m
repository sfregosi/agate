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
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	21 April 2023
%	Updated:
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

agate agate_config_sg639_MHI_Apr2022.cnf

global CONFIG


[gpsSurfT, locCalcT] = extractPositionalData(CONFIG, 0);


% save in default location yes (1) or no (0)

save(fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.glider, CONFIG.mission, '_gpsSurfaceTable.mat']), 'gpsSurfT');
writetable(gpsSurfT,fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.glider, CONFIG.mission, '_gpsSurfaceTable.csv']))

save(fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.glider, CONFIG.mission, '_locCalcT.mat']),'locCalcT');
writetable(locCalcT, fullfile(CONFIG.path.mission, 'profiles', ...
    [CONFIG.glider, CONFIG.mission, '_locCalcT.csv']));



