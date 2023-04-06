function output = checkPath(input)
% CHECKPATH	One-line description here, please
%
%	Syntax:
%		OUTPUT = CHECKPATH(INPUT)
%
%	Description:
% % only in MATLAB mode, are paths to various subfolders checked, if not
% present make the subfolders.
% subfolders check here are Remoras and Settings
% other subfolders not used here are Extras, ExampleRemoras
%if settings and java folder are in the search path for Matlab. If
% it is not in there, it is added in
% should also clear remoras to be added when installedRemoras.txt is read
% in...remove this comment when done
%	Inputs:
%		input 	describe, please
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
%		This function is based off the 'check_path' function from Triton,
%		created by S. Wiggins and available at 
%           https://github.com/MarineBioAcousticsRC/Triton/
%
%	FirstVersion: 	06 April 2023
%	Updated:
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global CONFIG

% root directory
CONFIG.path_agate = fileparts(which('agate'));

% Settings folder
CONFIG.path_settings = fullfile(CONFIG.path_agate,'Settings');
if ~exist(CONFIG.path_settings, 'dir')
    disp(' ')
    disp('Settings directory is missing, creating it ...')
    mkdir(CONFIG.path_settings);
    if ~isdeployed % standard in MATLAB mode
        addpath(CONFIG.path_settings)
    end
end

end