function [pamByMin, pamMinPerHour, pamMinPerDay, pamHrPerDay] = ...
    calcPAMEffort(gldr, lctn, dplymnt, expLimits, gpsSurfT, path_profiles)

% make a table of PAM on or off by minute for single glider
% and build up by hour and by day table with total minutes of recording in
% each of those bins

% need to define experiment limits externally if want padding because of
% other instruments in the water, otherwise make [] and will pull from dive
% data
if isempty(expLimits)
    clearvars expLimits
    expLimits(1) = gpsSurfT.startDateTime(1);
    expLimits(2) = gpsSurfT.endDateTime(end);
end

% build empty table for whole deployment
dm = [expLimits(1):minutes(1):expLimits(2)]';
pamByMin = table;
pamByMin.min = dm;

% build minutes per hour empty table
dh = [expLimits(1):hours(1):expLimits(2)]';
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
fprintf(1,'Calculating PAM status by min: %s\n', gldr)

load([path_profiles gldr '_' lctn '_' dplymnt '_pamByFile.mat']);
pamCheck = [pamByDive.pamStart pamByDive.pamEnd];
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
fprintf(1, '%s: %i minutes with PAM on\n', gldr, nansum(pamByMin.pam));

% by Hour
for f = 1:length(dh)
    dc = dh(f);
    hourTmp = pamByMin.pam(isbetween(pamByMin.min,dc,dc+minutes(59)+seconds(59)));
    pamMinPerHour.pam(f,1) = nansum(hourTmp);
end
pamMinPerHour.pam(pamMinPerHour.pam == 0) = nan; % if all zeros, make nan
fprintf(1, '%s: %i partial hours with PAM on, total %.2f hours\n', gldr, ...
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

fprintf(1, '%s: %i partial days with PAM on, total %.2f days\n', gldr, ...
    sum(~isnan(pamMinPerDay.pam)), nansum(pamMinPerDay.pam)/(60*24));

save([path_profiles gldr '_' lctn '_' dplymnt '_pamByMinHourDay.mat'], ...
    'pamByMin', 'pamMinPerHour', 'pamMinPerDay', 'pamHrPerDay');
writetable(pamByMin, [path_profiles gldr '_' lctn '_' dplymnt '_pamByMin.csv']);

end



