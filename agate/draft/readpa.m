function pa = readpa(fileName)
% READPA    Read pa file from basestation and extract summary information
%
%	Syntax:
%		PASTATS = READPA(FILENAME)
%
%	Description:
%		Read in pa****.r files created by PMAR and downloaded from the 
%       basestation, and extract summary information on recording start
%       time, duration, energy use, number of files written
%
%	Inputs:
%		fileName    fullfile path and file name to pa****.r file to be read
%
%	Outputs:
%		pa          structure with fields DiveNum, WriteTime, TotalTime,
%		            MaxDepth, FreeSpace, Energy, etc
%
%	Examples:
%       fName = 'C:\Users\selene\OneDrive\projects\GoMexBOEM\piloting\deployment\basestationFiles\pa0075au.r';
%       paStats = paRead(fName)
%       paStats = 
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
%	See also
%       readws
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	unknown
%	Updated:        4 May 2023
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pa = struct;
info = {'DiveNum' 'WriteTime' 'TotalTime' 'MaxDepth' 'Free' 'Energy' ...
     'Volt' 'Current' 'Battery' 'Detections' 'Startups'};
 % 'Avg Volt' 'Max Current' 'Battery Capacity' cannot be used because of 
 % space in name. 

x = fileread(fileName); % single long string
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

