function CONFIG = agate(missionCnf)
%AGATE	Initialize a new session of agate
%
%   Syntax:
%       AGATE missionCnf
%
%   Description:
%       Initialization step for agate toolbox. Reads in a specified
%       configuration file, or if none is specified, prompts user to select
%       configuration file. Sets paths and completes some checks.
%
%   Inputs:
%      missionCnf   Optional argument to specific configuration file for a
%                   particular mission e.g., 'sg639_MHI_Apr2023.cnf'
%
%   Outputs:
%       CONFIG  [struct] containing all the user-set configurations such as
%               paths, basestation login info, etc
%
%   Examples:
%       agate agate_sgXXX_Location_MonYear_config.cnf
%
%   See also   SETCONFIG, CHECKPATH
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:      1 February 2025
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear CONFIG;
% warning off % this is turned off for plotting messages

CONFIG = struct;

CONFIG.ver = '1.0.20250331   https://github.com/sfregosi/agate';
fprintf('      agate   version %s\n', CONFIG.ver)

if nargin < 1
	CONFIG.missionCnf = [];
else
	CONFIG.missionCnf = missionCnf;
end

% get matlab version for differences and backwards compatibility
CONFIG.mver = version;

CONFIG = checkPath(CONFIG);

CONFIG = setCONFIG(CONFIG);

fprintf('      loaded config file   %s\n\n', CONFIG.missionCnf)

end


function CONFIG = checkPath(CONFIG)
%CHECKPATH	Check the necessasry folders are there and on the path
%
%   Syntax:
%       CONFIG = CHECKPATH(CONFIG)
%
%   Description:
%       Called from the agate initialization. Sets up the necessary paths
%       in the CONFIG variable, while checking that all needed subfolders
%       are present and on the path. If not, it makes them.
%
%   Inputs:
%       CONFIG  [struct] containing all the user-set configurations such as
%               paths, basestation login info, etc
%
%	Outputs:
%       CONFIG  [struct] containing all the user-set configurations such as
%               paths, basestation login info, etc
%
%   Examples:
%       CONFIG = checkPath(CONFIG);
%
%	See also
%       agate
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%       This function is based off the 'check_path' function from Triton,
%       created by S. Wiggins and available at
%           https://github.com/MarineBioAcousticsRC/Triton/
%
%   Updated:      06 February 2025
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% root directory
CONFIG.path.agate = fileparts(which('agate'));
addpath(CONFIG.path.agate); % no subdirs

% make sure utils is on path
CONFIG.path.utils = fullfile(CONFIG.path.agate, 'utils');
addpath(genpath(CONFIG.path.utils)); % with subdirs

% check/create settings folder
CONFIG.path.settings = fullfile(CONFIG.path.agate,'settings');
if ~exist(CONFIG.path.settings, 'dir')
	disp(' ')
	disp('Settings directory is missing, creating it ...')
	mkdir(CONFIG.path.settings);
end
addpath(genpath(CONFIG.path.settings)); % with subdirs

end
