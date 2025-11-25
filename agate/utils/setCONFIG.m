function CONFIG = setCONFIG(CONFIG)
%SETCONFIG Set up CONFIG structure for agate
%
%   Syntax:
%      CONFIG = SETCONFIG(CONFIG)
%
%   Description:
%       Called from the agate initialization. Sets the default
%       configuration parameters and updates according to any .cnf files
%       present in the settings folder
%
%   Inputs:
%       CONFIG  [struct] containing all the user-set configurations such as
%               paths, basestation login info, etc
%   Outputs:
%       CONFIG  [struct] containing all the user-set configurations such as
%               paths, basestation login info, etc
%
%   Examples:
%
%   See also AGATE
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%       This function is based off the 'initparams' function from Triton,
%       created by S. Wiggins and available at
%           https://github.com/MarineBioAcousticsRC/Triton/
%
%   Updated:      06 February 2025
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% update based on user-defined configuration file if it exists

% if none specified, prompt to locate one
if isempty(CONFIG.missionCnf)
	[name, path] = uigetfile([CONFIG.path.settings, '\*.cnf'], ...
		'Select configuration file');
	CONFIG.missionCnf = fullfile(path, name);
	fprintf(1, 'Mission configuration file:\n      %s\n', CONFIG.missionCnf);
else
	% check if full file or just parts
	[path, ~, ~] = fileparts(CONFIG.missionCnf);
	if isempty(path) % no path specified
		% default location is within agate\settings folder, so try that
		CONFIG.missionCnf = fullfile(CONFIG.path.settings, CONFIG.missionCnf);
	end
	% and check that exists - if not, prompt to select
	if ~exist(CONFIG.missionCnf, 'file')
		[name, path] = uigetfile([CONFIG.path.agate, '\*.cnf'], ...
			'Select mission configuration file');
		CONFIG.missionCnf = fullfile(path, name);
	end

end
% CONFIG.path.cnfFid = fopen(CONFIG.missionCnf, 'r');
CONFIG = parseCnf(CONFIG.missionCnf, CONFIG);
if isfield(CONFIG, 'glider') && isfield(CONFIG, 'mission')
    CONFIG.gmStr = [CONFIG.glider '_' CONFIG.mission];
end

% if basestation 'bs' configurations exist
if isfield(CONFIG, 'bs')
	% parse the basestation configuration file
	% prompt to select if none specified in mission configuration file
	if ~exist(CONFIG.bs.cnfFile, 'file')
		[name, path] = uigetfile([CONFIG.path.settings, '\*.cnf'], ...
			'Select basestation configuration file');
		CONFIG.bs.cnfFile = fullfile(path, name);
	end
	CONFIG = parseCnf(CONFIG.bs.cnfFile, CONFIG);
end

% if pm configurations exist
% parse PMAR conversion configuration file
if isfield(CONFIG, 'pm') && (CONFIG.pm.loggers == 1) && (CONFIG.pm.convert == 1)
	if ~exist(CONFIG.pm.cnfFile, 'file')
		[name, path] = uigetfile([CONFIG.path.settings, '\*.cnf'], ...
			'Select PMAR convert configuration file');
		CONFIG.pm.cnfFile = fullfile(path, name);
	end
	CONFIG = parseCnf(CONFIG.pm.cnfFile, CONFIG);
end
end

%%%%%% NESTED FUNCTIONS %%%%%%
function CONFIG = parseCnf(userCnf, CONFIG)
% parse info from .cnf text files

fid = fopen(userCnf, 'r');
if fid == -1
	fprintf(1, 'No file selected. Exiting.\n')
	return
end
al = textscan(fid, '%s', 'delimiter', '\n');
nl = length(al{1});
if nl < 1
	fprintf(1, 'Warning: no data in configuration file. Only default paths set.\n')
else
	frewind(fid);
	for i = 1:nl
		line = fgets(fid);
		if ~strcmp(line(1), '%')
			eval(line);
		end
	end
end
fclose(fid);

end

