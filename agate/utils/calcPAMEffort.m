function [pamByMin, pamMinPerHour, pamMinPerDay, pamHrPerDay] = ...
    calcPAMEffort(CONFIG, gpsSurfT, pamFiles, pamByDive, expLimits)
%CALCPAMEFFORT	Calculates acoustic recording effort by minute, hour, day
%
%   Syntax:
%	    [GPSSURFT, LOCCALCT, pamFiles] = CALCPAMEFFORT(CONFIG, GPSSURFT, PAMFILES, PAMBYDIVE, EXPLIMITS)
%
%   Description:
%       Summarizes recording effort in several ways by creating tables of
%       all possible recording minutes, hours, and days, and quantifying
%       how many of each of those bins contain recordings. The assessment
%       of minutes is someone imperfect because some minutes only contain
%       partial recordings (if a file ends within that minute) and some
%       minutes are missed (if a recording starts partway through a minute)
%
%       Experiment limits can be defined if multiple instruments were
%       deployed and you want to compare across the maximum deployment time
%       for all of them. Optionally can be left out and the bins will just
%       populate from the first sound file to the end of the last file
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
%                  recorded sound files, created with extractPAMStatus
%       pamByDive  [table] summary of recording start and stop, number of
%                  files for each dive. Includes dive start and stop times
%                  and offset of start and stop of pam relative to dive
%                  times, created with extractPAMStatus
%       expLimits  [vector] two datetimes defining the start and end of an
%                  'experiment' to set limits of the maximum possible
%                  recording times
%
%   Outputs:
%       pamByMin      [table] one minute bins with 1 for recordings during
%                     this minute, 0 for no recordings this minute, and
%                     NaNs if the glider was at the surface or not deployed
%       pamMinPerHour [table] one hour bins with the total number of
%                     minutes of that hour with recordings
%       pamMinPerDay  [table] daily bins with total number of minutes with
%                     recordings per day
%       pamHrPerDay   [table] daily bins with total hours with recordings
%                     each day. This is the total minutes/60 so is total
%                     complete hours, not the number of hour bins with any
%                     partial amount of recording
%
%   Examples:
%
%   See also EXTRACTPAMSTATUS
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%    FirstVersion:   ??
%    Updated:        12 July 2024
%
%    Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 5 % default 'experiment time' is deploy start/end
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
    [rD, ~] = find(isbetween(dc, diveCheck(:,1), diveCheck(:,2)));
    if isempty(rD) % if not, put NaN
        pamByMin.pam(f,1) = nan;
    end
    % is PAM on in this minute?
    [rP, ~] = find(isbetween(dc, pamCheck(:,1), pamCheck(:,2)));
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
	hours(sum(pamFiles.dur, 'omitnan')));

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
    pamHrPerDay.pam(f,1) = round(sum(dayTmp, 'omitnan')/60, 2);
end
pamHrPerDay.pam(pamHrPerDay.pam == 0) = nan;

fprintf(1, '%s: %i partial days with PAM on, total %.2f days\n', ...
	CONFIG.glider, sum(~isnan(pamMinPerDay.pam)), ...
	sum(pamMinPerDay.pam, 'omitnan')/(60*24));

end



