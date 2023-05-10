function [pamByMin, pamMinPerHour, pamMinPerDay, pamHrPerDay] = ...
    calcPAMEffort(glider, deploymentStr, expLimits, gpsSurfT, path_profiles)
% CALCPAMEFFORT 	*PLACEHOLDER - NOT YET WORKING*  Extracts glider location data from nc files
%
%	Syntax:
%		[gpsSurfT, locCalcT] = CALCPAMEFFORT(CONFIG, SAVEON)
%
%	Description:
%		Extracts 
%
%	Inputs:
%		CONFIG  agate mission configuration file with relevant mission and
%		        glider information. Minimum CONFIG fields are 'glider',
%		        'mission'
%       plotOn  optional argument to plot basic maps of outputs for
%               checking; (1) to plot, (0) to not plot
%
%	Outputs:
%		gpsSurfT    Table with glider surface locations, from GPS, one per
%		            dive, and includes columns for dive start and end
%		            time/lat/lon, dive duration, depth average current,
%                   average speed over ground as northing and easting,
%                   calculated by the hydrodynamic model or the glide slope
%                   model
%       locCalcT    Table with glider calculated locations underwater every
%                   science file sampling interval. This gives more
%                   instantaneous flight details and includes columns
%                   for time, lat, lon from hydrodynamic and glide slope
%                   models, displacement from both models, temperature,
%                   salinity, density, sound speed, glider vertical and
%                   horizontal speed (from both models), pitch, glide
%                   angle, and heading
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
%	FirstVersion: 	unknown
%	Updated:        23 April 2023
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% make a table of PAM on or off by minute for single glider
% and build up by hour and by day table with total minutes of recording in
% each of those bins

% need to define experiment limits externally if want padding because of
% other instruments in the water, otherwise make [] and will pull from dive
% data
if isempty(expLimits)
    clearvars expLimits
    expLimits(1) = dateshift(gpsSurfT.startDateTime(1),'start','minute');
    expLimits(2) = dateshift(gpsSurfT.endDateTime(end),'end','minute');
end

% build empty table for whole deployment
dm = [expLimits(1):minutes(1):expLimits(2)]';

pamByMin = table;
pamByMin.min = dm;

% build minutes per hour empty table
dh = [dateshift(expLimits(1), 'start', 'hour'):hours(1): ...
    dateshift(expLimits(2), 'start', 'hour')]';
pamMinPerHour = table;
pamMinPerHour.hour = dh;

% build minutes per day empty table
ddm = [dateshift(expLimits(1),'start','day'):days(1):dateshift(expLimits(2),'start','day')]';
pamMinPerDay = table;
pamMinPerDay.day = ddm;

% build hours per day empty table
ddh = [dateshift(expLimits(1),'start','day'):days(1):dateshift(expLimits(2),'start','day')]';
pamHrPerDay = table;
pamHrPerDay.day = ddh;


% now loop through each instrument
fprintf(1,'Calculating PAM status by min: %s\n', glider)

load([path_profiles glider '_' deploymentStr '_pamByFile.mat']);
% pamCheck = [pamByDive.pamStart pamByDive.pamEnd]; % this works when not duty cycling
pamCheck = [pam.fileStart pam.fileEnd];
diveCheck = [pamByDive.diveStart pamByDive.diveEnd];

% by Minute - NaN if not deployed or at surface, 0 if PAM OFF, 1 if ON
for f = 1:length(dm)
    dc = dm(f);
    % is this minute within a dive?
    [rD, ~] = find(isbetween(dc,diveCheck(:,1), diveCheck(:,2)));
    if isempty(rD) % if not, put NaN
        pamByMin.pam(f,1) = nan;
    end
    % is PAM on in this minute?
    [rP, ~] = find(isbetween(dc,pamCheck(:,1),pamCheck(:,2)));
    if ~isempty(rP)
        pamByMin.pam(f,1) = 1;
    end
end
fprintf(1, '%s: %i minutes with PAM on\n', glider, nansum(pamByMin.pam));
% this is not perfect...not always full minutes (at end of a recording 
% and misses some partial minutes (At the start of a recording) 

% by Hour
for f = 1:length(dh)
    dc = dh(f);
    hourTmp = pamByMin.pam(isbetween(pamByMin.min,dc,dc+minutes(59)+seconds(59)));
    pamMinPerHour.pam(f,1) = nansum(hourTmp);
end
pamMinPerHour.pam(pamMinPerHour.pam == 0) = nan; % if all zeros, make nan
fprintf(1, '%s: %i partial hours with PAM on, total %.2f hours\n', glider, ...
    sum(~isnan(pamMinPerHour.pam)), nansum(pamMinPerHour.pam)/60);

% by Day
%   Minutes per day
for f = 1:length(ddm)
    dc = ddm(f);
    dayTmp = pamByMin.pam(isbetween(pamByMin.min,dc,dc+minutes(1439)+seconds(59)));
    pamMinPerDay.pam(f,1) = nansum(dayTmp);
end
pamMinPerDay.pam(pamMinPerDay.pam == 0) = nan;
%   Hours per day
for f = 1:length(ddh)
    dc = ddh(f);
    dayTmp = pamMinPerHour.pam(isbetween(pamMinPerHour.hour,dc,dc+minutes(1439)+seconds(59)));
    pamHrPerDay.pam(f,1) = sum(~isnan(dayTmp));
end
pamHrPerDay.pam(pamHrPerDay.pam == 0) = nan;

fprintf(1, '%s: %i partial days with PAM on, total %.2f days\n', glider, ...
    sum(~isnan(pamMinPerDay.pam)), nansum(pamMinPerDay.pam)/(60*24));

save([path_profiles glider '_' deploymentStr '_pamByMinHourDay.mat'], ...
    'pamByMin', 'pamMinPerHour', 'pamMinPerDay', 'pamHrPerDay');
writetable(pamByMin, [path_profiles glider '_' deploymentStr '_pamByMin.csv']);

end



