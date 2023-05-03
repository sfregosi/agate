function sgInterp = interpGlider(glider, deploymentStr, expLimits, path_out)

% interpolate between GPS points and depth readings for glider

load([path_out glider '_' deploymentStr '_gpsSurfaceTable_pam.mat']);
load([path_out glider '_' deploymentStr '_locCalcT_pam.mat']);
load([path_out glider '_' deploymentStr '_pamByMinHourDay.mat']);
% 
try
    load([path_out 'experimentLimits.mat']);
end

if isempty(expLimits)
    clearvars expLimits
    expLimits(1) = dateshift(gpsSurfT.startDateTime(1),'start','minute');
    expLimits(2) = dateshift(gpsSurfT.endDateTime(end),'end','minute');
end

di = [expLimits(1):minutes(1):expLimits(2)]';

% build continuous time series with dive starts and ends
timeTmp = [];
latTmp = [];
lonTmp = [];
diveTmp = [];
for f = 1:height(gpsSurfT)
    timeTmp = [timeTmp; gpsSurfT.startDateTime(f); gpsSurfT.endDateTime(f)];
    latTmp = [latTmp; gpsSurfT.startLatitude(f); gpsSurfT.endLatitude(f)];
    lonTmp = [lonTmp; gpsSurfT.startLongitude(f); gpsSurfT.endLongitude(f)];
    diveTmp = [diveTmp; repmat(gpsSurfT.dive(f),2,1)];
end

% now interpolate
latInterp = interp1(timeTmp,latTmp,di);
lonInterp = interp1(timeTmp,lonTmp,di);

sgInterp = table(di,latInterp,lonInterp,'VariableNames',{'dateTime', ...
    'latitude','longitude'});
sgInterp.dive = NaN(height(sgInterp),1);
for f = 1:height(sgInterp)
    [r,~] = find(isbetween(sgInterp.dateTime(f),gpsSurfT.startDateTime,gpsSurfT.endDateTime));
    if ~isempty(r) ; sgInterp.dive(f,1) = gpsSurfT.dive(r); end
end

% check by plotting
% color_line3(sgInterp.longitude,sgInterp.latitude,sgInterp.dive,sgInterp.dive*6);

% now interpolate depth
sgInterp.depth = interp1(locCalcT.dateTime,locCalcT.depth,di);

% finalize the nans
nanSet = isnan(sgInterp.dive);
sgInterp.latitude(nanSet) = nan;
sgInterp.longitude(nanSet) = nan;
sgInterp.depth(nanSet) = nan;

if height(pamByMin) == height(sgInterp)
    sgInterp.pam = pamByMin.pam;
else
    fprintf(1,'pamByMin length does not match interpolated length. No PAM column\n');
end

% plot check
% figure;
% plot(sgInterp.dateTime,-sgInterp.depth,'k.')

if ~isempty(path_out)
    save([path_out glider '_' deploymentStr '_interpolatedTrack.mat'], 'sgInterp');
end

end

