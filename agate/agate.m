function agate(missionCnf)
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
%      No workspace outputs. Generates a global CONFIG variable
%
%   Examples:
%       agate agate_sgXXX_Location_MonYear_config.cnf
%
%   See also   SETCONFIG, CHECKPATH
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   06 April 2023
%   Updated:        01 June 2023
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear global CONFIG;  % clear out old globals
warning off % this is turned off for plotting messages

global CONFIG
% CONFIG = struct;

CONFIG.ver = '0.1.20230601 github.com/sfregosi/agate-public';
fprintf('              agate version %s\n\n', CONFIG.ver)

if nargin < 1
    CONFIG.missionCnf = [];
else
    CONFIG.missionCnf = missionCnf;
end

% get matlab version for differences and backwards capatibility
CONFIG.mver = version;

checkPath;

setCONFIG(CONFIG.missionCnf);

end
