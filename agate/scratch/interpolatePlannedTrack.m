function interpTrack = interpolatePlannedTrack(CONFIG, targets)
% INTERPOLATEPLANNEDTRACK	One-line description here, please
%
%   Syntax:
%       OUTPUT = INTERPOLATEPLANNEDTRACK(INPUT)
%
%   Description:
%       Detailed description here, please
%   Inputs:
%       input   describe, please
%
%	Outputs:
%       output  describe, please
%
%   Examples:
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   06 August 2024
%   Updated:
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(targetsFile)
    [fn, path] = uigetfile(fullfile(CONFIG.path.mission, '*.*'), ...
        'Select targets file');
    targetsFile = fullfile(path, fn);
end

[targets, targetsFile] = readTargetsFile;
