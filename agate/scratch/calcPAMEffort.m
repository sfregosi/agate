function [pamByMin, pamMinPerHour, pamMinPerDay, pamHrPerDay] = ...
    calcPAMEffort(CONFIG, gpsSurfT, pamFiles, pamByDive, expLimits)
%CALCPAMEFFORT	Extracts PAM system on/off information from sound files
%
%   Syntax:
%	    [GPSSURFT, LOCCALCT, pamFiles] = EXTRACTPAMSTATUS(CONFIG, GPSSURFT, LOCCALCT)
%
%   Description:
% make a table of PAM on or off by minute for single glider
% and build up by hour and by day table with total minutes of recording in
% each of those bins
% need to define experiment limits externally if want padding because of
% other instruments in the water, otherwise make [] and will pull from dive
% data
%
%   Inputs:
%       CONFIG     agate mission configuration file with relevant mission and
%                  glider information. Minimum CONFIG fields are 'glider',
%                  'mission', 'path.mission', logger field (either 'pm' or
%                  'ws') and logger sub fields 'fileLength', 'dateStart',
%                  'dateFormat'
%                  See exaxmple config file and config file help for more
%                  detail on each field: 
%                  https://github.com/sfregosi/agate-public/blob/main/agate/settings/agate_config_example.cnf
%                  https://sfregosi.github.io/agate-public/configuration.html#mission-configuration-file
%       gpsSurfT   [table] glider surface locations exported from
%                  extractPositionalData
%       pamFiles   [table] name, start and stop time and duration of all
%                  recorded sound files
%       pamByDive  [table] summary of recording start and stop, number of
%                  files for each dive. Includes dive start and stop times
%                  and offset of start and stop of pam relative to dive
%                  times
%
%       locCalcT   [table] glider fine scale locations exported from
%                  extractPositionalData
%
%   Outputs:
%
%   Examples:
%
%   See also 
%
%   TO DO:
%      - build in option for FLAC
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%    FirstVersion:   ??
%    Updated:        11 July 2024
%
%    Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3 % default 'experiment time' is deploy start/end
    expLimits(1) = dateshift(gpsSurfT.startDateTime(1), 'start', 'minute');
    expLimits(2) = dateshift(gpsSurfT.endDateTime(end), 'end', 'minute');
end

% build empty table for whole deployment
dm = (expLimits(1):minutes(1):expLimits(2))';

pamByMin = table;
pamByMin.min = dm;

% build minutes per hour empty table
dh = (dateshift(expLimits(1), 'start', 'hour'):hours(1): ...
    dateshift(expLimits(2), 'start', 'hour'))';
pamMinPerHour = table;
pamMinPerHour.hour = dh;

% build minutes per day empty table
ddm = (dateshift(expLimits(1),'start','day'):days(1):dateshift(expLimits(2), ...
	'start', 'day'))';
pamMinPerDay = table;
pamMinPerDay.day = ddm;

% build hours per day empty table
ddh = (dateshift(expLimits(1),'start','day'):days(1):dateshift(expLimits(2), ...
	'start', 'day'))';
pamHrPerDay = table;
pamHrPerDay.day = ddh;

fprintf(1,'Calculating PAM status by min: %s\n', CONFIG.glider)

% pamCheck = [pamByDive.pamStart pamByDive.pamEnd]; % this works when not duty cycling
pamCheck = [pamFiles.start pamFiles.stop];
diveCheck = [pamByDive.diveStart pamByDive.diveStop];

% by Minute - NaN if not deployed or at surface, 0 if PAM OFF, 1 if ON
for f = 1:length(dm)
    dc = dm(f);
    % is this minute within a dive?
    [rD, ~] = find(isbetween(dc,diveCheck(:,1), diveCheck(:,2)));
    if isempty(rD) % if not, put NaN
        pamByMin.pam(f,1) = nan;
    end
    % is PAM on in this minute?
    [rP, ~] = find(isbetween(dc,pamCheck(:,1), pamCheck(:,2)));
    if ~isempty(rP)
        pamByMin.pam(f,1) = 1;
    end
end
fprintf(1, '%s: %i minutes with PAM on\n', CONFIG.glider, ...
	sum(pamByMin.pam, 'omitnan'));
% this is not perfect...not always full minutes (at end of a recording 
% and misses some partial minutes (At the start of a recording) 

% by Hour
for f = 1:length(dh)
    dc = dh(f);
    hourTmp = pamByMin.pam(isbetween(pamByMin.min, dc, ...
		dc + minutes(59) + seconds(59)));
    pamMinPerHour.pam(f,1) = sum(hourTmp, 'omitnan');
end
pamMinPerHour.pam(pamMinPerHour.pam == 0) = nan; % if all zeros, make nan
fprintf(1, '%s: %i partial hours with PAM on, total %.2f hours\n', ...
	CONFIG.glider, sum(~isnan(pamMinPerHour.pam)), ...
	sum(pamMinPerHour.pam, 'omitnan')/60);

% by Day
%   Minutes per day
for f = 1:length(ddm)
    dc = ddm(f);
    dayTmp = pamByMin.pam(isbetween(pamByMin.min, dc, ...
		dc + minutes(1439) + seconds(59)));
    pamMinPerDay.pam(f,1) = sum(dayTmp, 'omitnan');
end
pamMinPerDay.pam(pamMinPerDay.pam == 0) = nan;
%   Hours per day
for f = 1:length(ddh)
    dc = ddh(f);
    dayTmp = pamMinPerHour.pam(isbetween(pamMinPerHour.hour, dc, ...
		dc + minutes(1439) + seconds(59)));
    pamHrPerDay.pam(f,1) = sum(dayTmp, 'omitnan');
end
pamHrPerDay.pam(pamHrPerDay.pam == 0) = nan;

fprintf(1, '%s: %i partial days with PAM on, total %.2f days\n', ...
	CONFIG.glider, sum(~isnan(pamMinPerDay.pam)), ...
	sum(pamMinPerDay.pam, 'omitnan')/(60*24));

end



