function [lat, lon] = ppToGPSSurf(CONFIG, pp)
% PPTOGPSSURF	One-line description here, please
%
%   Syntax:
%       OUTPUT = PPTOGPSSURF(CONFIG, PP)
%
%   Description:
%       Detailed description here, please
%   Inputs:
%       CONFIG   describe, please
%       pp   describe, please
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
%   FirstVersion:   20 September 2024
%   Updated:
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


lat = nan(height(pp)*2,1);
lon = nan(height(pp)*2,1);
dive = nan(height(pp)*2,1);
time = nan(height(pp)*2,1);
per = nan(height(pp)*2,1);
for d = 1:height(pp)
    try
        lat((d*2-1):d*2) = [pp.startGPS{d}(1); pp.endGPS{d}(1)];
        lon((d*2-1):d*2) = [pp.startGPS{d}(2); pp.endGPS{d}(2)];
        dive((d*2-1):d*2) = [d; d];
        time((d*2-1):d*2) = [datenum(pp.diveStartTime(d));
            datenum(pp.diveEndTime(d))];
        per((d*2-1):d*2) = [1, 2];
    catch
        continue
    end
end
