function [paStats] = paRead(fileName)
% read PAM stats from pa file off basestation, into a way it can be
% utilized in matlab for plotting, etc
%
% Input:
%       filename
%       ideally use this to loop through all pa****.r files downloaded from
%       basestation
% Output:
%       paStats is a structure with information DiveNum, WriteTime,
%       TotalTime, MaxDepth, FreeSpace, Energy, etc
%
% Example: 
% fName = 'C:\Users\selene\OneDrive\projects\GoMexBOEM\piloting\deployment\basestationFiles\pa0075au.r';
% paStats = paRead(fName)
% paStats = 
% 
%   struct with fields:
% 
%        DiveNum: 75
%      WriteTime: 737205.642326389
%      TotalTime: 25316
%       MaxDepth: 992.77
%           Free: 66.24
%         Energy: 27.68
%           Volt: 14.01
%        Current: 0.266
%        Battery: 0
%     Detections: 10
%       Startups: 82

paStats=struct;
stats={'DiveNum' 'WriteTime' 'TotalTime' 'MaxDepth' 'Free' 'Energy' ...
     'Volt' 'Current' 'Battery' 'Detections' 'Startups'};
 % 'Avg Volt' 'Max Current' 'Battery Capacity' cannot be used because of 
 % space in name. 

x = fileread(fileName); % single long string
for f = 1:length(stats);
    idx = strfind(x,stats{f});
    idxc = regexp(x(idx:end),':','once');
    loc = idx+idxc;
    if f ~= 2
        out = sscanf(x(loc:end),'%f');  
    else
        out = datenum(sscanf(x(loc:end),'%s %s/n'),'mm/dd/yyyyHH:MM:SS');
    end
    paStats.(stats{f})=out;
end

