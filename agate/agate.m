function agate(missionCnf)
% AGATE	Initialize a new session of agate
%
%	Syntax:
%		AGATE
%
%	Description:
%		Detailed description here, please
%	Inputs:
%		missionCnf  optional argument to specific configuration file for a
%                   particular mission e.g., 'sg639_MHI_Apr2023.cnf'
%
%	Outputs:
%
%	Examples:
%       agate agate_sgXXX_Location_MonYear_config.cnf
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	06 April 2023
%	Updated:        14 April 2023
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear global;  % clear out old globals
warning off % this is turned off for plotting messages

global CONFIG
% CONFIG = struct;

CONFIG.ver = '0.0.20230414 github.com/sfregosi/agate-public';
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