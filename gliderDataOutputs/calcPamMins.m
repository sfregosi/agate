function [pamDurs, pamByMin, pamMinPerHour, pamMinPerDay] = ...
    calcPamMins(gldr, expLimits, gpsSurfT, pamDurs, path_profiles)

% make a table of PAM on or off by minute for single glider
% and build up by hour and by day table with total minutes of recording in
% each of those bins

% need to define experiment limits externally if want padding because of
% other instruments in the water, otherwise make [] and will pull from dive
% data
if isempty(expLimits)
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
dd = [dateshift(expLimits(1),'start','day'):days(1):dateshift(expLimits(2),'start','day')]';
pamMinPerDay = table;
pamMinPerDay.day = dd;

% now loop through each instrument
    fprintf(1,'Calculating PAM status by min: %s\n',instr)
    if strcmp(gldr,'sg607') || strcmp(instr,'q003')     % SG607 or Q003
        load([path_profiles instr '_CatBasin_Jul16\' instr '_CatBasin_Jul16_pam.mat']);
        pamCheck = [pamByDive.pamStart pamByDive.pamEnd];
    elseif strcmp(gldr,'H01')   % H01
        pamCheck = [pamDurs.startTime(3) pamDurs.endTime(3)];
    elseif strcmp(gldr,'H02')   % H02
        pamCheck = [pamDurs.startTime(4) pamDurs.endTime(4)];
    else
        break
        fprintf('invalid instrument: %s \n',instr);
    end
    
    % by Minute - leave as 0 if PAM is on, NaN if pam is off. 
    for f = 1:length(dm)
        dc = dm(f);
        [rP, ~] = find(isbetween(dc,pamCheck(:,1),pamCheck(:,2)));
        if isempty(rP)
            pamByMin.(instr)(f,1) = nan;
        end
    end    
    pamDurs.mins(i,1) = sum(~isnan(pamByMin.(instr)));
    
    % by Hour
    for f = 1:length(dh)
        dc = dh(f);
        hourTmp = pamByMin.(instr)(isbetween(pamByMin.min,dc,dc+minutes(59)));
        pamMinPerHour.(instr)(f,1) = sum(~isnan(hourTmp));
    end
    pamMinPerHour.(instr)(pamMinPerHour.(instr) == 0) = nan;
    
    % by Day
 for f = 1:length(dd)
        dc = dd(f);
        dayTmp = pamByMin.(instr)(isbetween(pamByMin.min,dc,dc+minutes(1439)));
        pamMinPerDay.(instr)(f,1) = sum(~isnan(dayTmp));
    end
    pamMinPerDay.(instr)(pamMinPerDay.(instr) == 0) = nan;
end



