function qInterp = interpQUE(instr,path_profiles)

% interpolate between GPS points for QUEphone

% load([path_profiles 'pamDurs.mat']);
load([path_profiles 'experimentLimits.mat']);

% load(['C:\Users\selene\OneDrive\projects\AFFOGATO\profiles\q003_CatBasin_Jul16\' ...
%     'q003_CatBasin_Jul16_locCalcT_pam.mat']);
load([path_profiles instr '_CatBasin_Jul16\' instr ...
    '_CatBasin_Jul16_depthTable.mat']);
% load('C:\Users\selene\OneDrive\projects\AFFOGATO\profiles\q003_CatBasin_Jul16\deploymentRecord_manualUpdate.mat')
load([path_profiles instr '_CatBasin_Jul16\' instr ...
    '_CatBasin_Jul16_gpsSurfaceTable_Basic.mat'])
load([path_profiles instr '_CatBasin_Jul16\' instr  ...
    '_CatBasin_Jul16_gpsSurfaceTable.mat'])

di = [expLimits(1):minutes(1): expLimits(2)]';

% basic table is already single list of times and locations
% use this because no repeats
timeTmp = gpsSurfTB.dateTime;
latTmp = gpsSurfTB.latitude;
lonTmp = gpsSurfTB.longitude;

% now interpolate
latInterp = interp1(timeTmp,latTmp,di);
lonInterp = interp1(timeTmp,lonTmp,di);

qInterp = table(di,latInterp,lonInterp,'VariableNames',{'dateTime', ...
    'latitude','longitude'});
qInterp.dive = NaN(height(qInterp),1);
for f = 1:height(qInterp)
    [r,~] = find(isbetween(qInterp.dateTime(f),gpsSurfT.startDateTime,gpsSurfT.endDateTime));
    if ~isempty(r)
        qInterp.dive(f,1) = gpsSurfT.dive(r(end));
    end
end

% check by plotting
% figure;
% color_line3(qInterp.longitude,qInterp.latitude,qInterp.dive,qInterp.dive*6,'LineWidth',4);
 
% now interpolate depth
qInterp.depth = interp1(depthT.dateTime,depthT.depth,di);

% finalize the nans
nanSet = isnan(qInterp.dive);
qInterp.latitude(nanSet) = nan;
qInterp.longitude(nanSet) = nan;
qInterp.depth(nanSet) = nan;

% plot check
% figure;
% plot(qInterp.dateTime,-qInterp.depth,'k.')

end

