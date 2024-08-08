% WORKFLOW_CONVERTPMAR
%	Convert PMAR acoustic data from .dat to .wav files
%
%	Description:
%       This script converts raw PMAR .dat files to .wav files for further
%       acoustic analysis. It relies on the convertPMAR process written
%       by Dave Mellinger (Oregon State University) 
% 
%       A modified (functionized) version of these scripts are included 
%       with agate, or the standalone functions can be downloaded from the 
%       Mathworks File Exchange: 
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
%	FirstVersion: 	08 June 2023
%	Updated:        04 March 2024
%
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% update/prepare mission configuration file:
% - set CONFIG.pm.convert = 1 to trigger conversion
% - specify path to PMAR convert configuration file with CONFIG.pm.cnfFile

% initialize agate - either specify the mission .cnf or leave blank to browse/select
CONFIG = agate('agate_mission_config.cnf');

% convert!
convertPmarFun(CONFIG)

