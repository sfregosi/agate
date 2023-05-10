function pa = readpa(paFile)
%READPA    Read pmar generated pa file and extract summary information
%
%   Syntax:
%       pa = READPA(paFile)
%
%   Description:
%       Read in pa****.r files created by PMAR and downloaded from the 
%       basestation, and extract summary information on recording start
%       time, duration, energy use, number of files written
%
%   Inputs:
%       paFile   fullfile path and file name to pa****.r file to be read
%
%   Outputs:
%       pa        structure summary info including fields DiveNum, 
%                 WriteTime, TotalTime, MaxDepth, FreeSpace, Energy
%
%   Examples:
%       fName = 'C:\sg607\basestationFiles\pa0075au.r';
%       pa = paRead(fName)
%       pa = 
%           struct with fields:
%                DiveNum: 75
%              WriteTime: 737205.642326389
%              TotalTime: 25316
%               MaxDepth: 992.77
%                   Free: 66.24
%                 Energy: 27.68
%                   Volt: 14.01
%                Current: 0.266
%                Battery: 0
%             Detections: 10
%               Startups: 82
%
%   See also READWS
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   unknown
%   Updated:        10 May 2023
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% if CONFIG exists, use it to set up paths for file selection
global CONFIG
if isempty(CONFIG)
    clear -global CONFIG
    initialPath = pwd;
elseif ~isempty(CONFIG)
    if isfield(CONFIG.path, 'bsLocal')
        initialPath = CONFIG.path.bsLocal;
    else
        initialPath = CONFIG.path.mission;
    end
end

% if no file specified, prompt to select
if nargin < 1
    [name, path] = uigetfile({'*','All Files'}, 'Select pa file', initialPath);
    paFile = fullfile(path, name);
end

% check that input wsFile has path
[path, ~, ~] = fileparts(paFile);
if isempty(path)
    fprintf(1, 'No file path specified. Must select file.\n');
    [name, path] = uigetfile({'*','All Files'}, 'Select ws file', initialPath);
    paFile = fullfile(path, name);
end


pa = struct;
info = {'DiveNum' 'WriteTime' 'TotalTime' 'MaxDepth' 'Free' 'Energy' ...
     'Volt' 'Current' 'Battery' 'Detections' 'Startups'};
 % 'Avg Volt' 'Max Current' 'Battery Capacity' cannot be used because of 
 % space in name. 

x = fileread(paFile); % single long string
for f = 1:length(info)
    idx = strfind(x,info{f});
    idxc = regexp(x(idx:end),':','once');
    loc = idx+idxc;
    if f ~= 2
        out = sscanf(x(loc:end),'%f');  
    else
        out = datenum(sscanf(x(loc:end),'%s %s/n'),'mm/dd/yyyyHH:MM:SS');
    end
    pa.(info{f})=out;
end

