function CONFIG = setCONFIG(input)
% SETCONFIG	Set up global CONFIG structure for agate
%
%	Syntax:
%		CONFIG = SETCONFIG(INPUT)
%
%	Description:
%		Detailed description here, please
%	Inputs:
%		input 	describe, please
%
%	Outputs:
%		CONFIG  structure containing all the user-set configurations such
%		as paths, basestation login info, etc
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


global CONFIG

CONFIG.ver = '0.0.20230406 github.com/sfregosi/agate-public';
disp(' ')
disp(['         agate version ', CONFIG.ver])


