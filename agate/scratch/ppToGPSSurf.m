function surfSimp = ppToGPSSurf(CONFIG, pp)
% PPTOGPSSURF	One-line description here, please
%
%   Syntax:
%       SURFSIMP = PPTOGPSSURF(CONFIG, PP)
%
%   Description:
%       Create a simplified surface GPS table from the piloting params (pp)
%       table created during a mission. This is useful for alternative
%       plotting during a mission or to subsitute in where a GPSSurf table
%       would otherwise be used (typically created after a mission has
%       ended)
%
%   Inputs:
%       CONFIG    [struct] mission/agate configuration variable. Not
%                 actually required??
%       pp        [table] piloting params table created with
%                 extractPilotingParams function that includes start and
%                 end times and lat/lons for each dive
%
%	Outputs:
%       surfSimp  [table] 'simple' surface GPS table with cols for lat,
%                 lon, dive and time
%
%   Examples:
%
%   See also EXTRACTPILOTINGPARAMS, EXTRACTPOSITIONALDATA
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   20 September 2024
%   Updated:        15 October 2024
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


lat = nan(height(pp)*2,1);
lon = nan(height(pp)*2,1);
dive = nan(height(pp)*2,1);
time = nan(height(pp)*2,1);
per = cell(height(pp)*2,1);

for d = 1:height(pp)
    try
        lat((d*2-1):d*2) = [pp.startGPS{d}(1); pp.endGPS{d}(1)];
        lon((d*2-1):d*2) = [pp.startGPS{d}(2); pp.endGPS{d}(2)];
        dive((d*2-1):d*2) = [d; d];
        time((d*2-1):d*2) = [datenum(pp.diveStartTime(d));
            datenum(pp.diveEndTime(d))];
        per((d*2-1):d*2) = [{'start'}; {'stop'}]; % start/stop label
    catch
        continue
    end
end

% assemble into a table
surfSimp = table(dive, time, datetime(time, 'ConvertFrom', 'datenum'), lat, lon, per);
surfSimp.Properties.VariableNames = {'dive', 'time_UTC', 'dateTime_UTC', ...
	'latitude', 'longitude', 'label'};

end