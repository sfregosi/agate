% WORKFLOW_EXPORTWISPRSENSITIVITY.M
%	One-line description here, please
%
%	Description:
%		Detailed description here, please
%
%	Notes
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	Updated:   2025 July 03
%
%	Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% make sure agate is on the path!
% addpath(genpath('C:\Users\User.Name\Documents\MATLAB\agate'))
addpath(genpath('C:\Users\selene.fregosi\Documents\MATLAB\agate'))

metadata = [];
path_out = [];
outType = 'both';
fRange = [1 70000];



sr = wisprSensitivity(metadata, path_out, outType, fRange);