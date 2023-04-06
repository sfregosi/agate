function CONFIG = setCONFIG
% SETCONFIG	Set up global CONFIG structure for agate
%
%	Syntax:
%		CONFIG = SETCONFIG
%
%	Description:
%       Called from the agate initialization. Sets the default
%       configuration parameters and updates according to any .cnf files
%       present in the settings folder
%
%	Inputs:
%		input 	none
%
%	Outputs:
%		CONFIG  global structure containing all the user-set configurations
%       such as paths, basestation login info, etc
%
%	Examples:
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%		This function is based off the 'initparams' function from Triton,
%		created by S. Wiggins and available at
%           https://github.com/MarineBioAcousticsRC/Triton/
%
%	FirstVersion: 	06 April 2023
%	Updated:
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


global CONFIG

% set defaults in case no config file
% paths
CONFIG.path.shp = 'C:\Users\User.Name\Documents\GIS\';
CONFIG.path.survey = 'C:\Desktop\glider_survey\';
% basestation configuration
CONFIG.bs.host = 'url.com';
CONFIG.bs.username = 'pilot';
CONFIG.bs.password = 'PsWrD';

% update based on user files if they exist
if ~isempty(CONFIG.surveyCnf)
    % default location is within agate\settings folder
    surveyCnf = fullfile(CONFIG.path.settings, CONFIG.surveyCnf);
    % otherwise prompt to select one
    if ~exist(surveyCnf, 'file')
        [name, path] = uigetfile([CONFIG.path.agate, '\*.cnf'], 'Select survey configuration file');
        surveyCnf = fullfile(path, name);
    end
    CONFIG.path.cnfFid = fopen(surveyCnf,'r');
    parseCnf(surveyCnf)
else
    fprintf(1, 'No survey configuration file selected. Using defaults.\n')
end

userBSCnf = fullfile(CONFIG.path.settings, 'basestation.cnf');
if exist(userBSCnf, 'file')
    CONFIG.bs.cnfFid = fopen(userBSCnf,'r');
    parseCnf(userBSCnf)
end

end


function parseCnf(userCnf)
% parse info from .cnf text files

global CONFIG

fid = fopen(userCnf,'r');
if fid == -1
    disp_msg('Error: no such file')
    return
end
al = textscan(fid,'%s','delimiter','\n');
nl = length(al{1});
if nl < 1
    disp_msg('Error: no data in configuration file')
else
    frewind(fid);
    for i = 1:nl
        line = fgets(fid);
        if ~strcmp(line(1), '#')
            eval(line);
        end
    end
end
fclose(fid);

end

