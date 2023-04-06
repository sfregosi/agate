function agate(surveyCnf)
% AGATE	Initialize a new session of agate
%
%	Syntax:
%		AGATE
%
%	Description:
%		Detailed description here, please
%	Inputs:
%		surveyCnf   optional argument to specific configuration file for a
%                   particular survey e.g., 'sg639_MHI_Apr2023.cnf'
%
%	Outputs:
%		output 	describe, please
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
%	FirstVersion: 	06 April 2023
%	Updated:
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear global;  % clear out old globals
warning off % this is turned off for plotting messages

global CONFIG

CONFIG.ver = '0.0.20230406 github.com/sfregosi/agate-public';
disp(' ')
disp(['         agate version ', CONFIG.ver])

if nargin < 1
    CONFIG.surveyCnf = [];
else
    CONFIG.surveyCnf = surveyCnf;
end

% get matlab version for differences and backwards capatibility
CONFIG.mver = version;

checkPath

CONFIG = setCONFIG;

end