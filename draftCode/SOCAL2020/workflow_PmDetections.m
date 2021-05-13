% processing sperm whale detections

addpath(genpath('C:\Users\selene\OneDrive\MATLAB\wutils\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\DaveWhales\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\utils\'));

species = 'Pm';
glider = 'sg607';
% glider = 'sg639';

path_out = ['E:\SoCal2020\largeWhaleAnalysis\Pm\Pm_' glider '\'];
path_wav = ['E:\SoCal2020\' glider '_downsampled\' glider '-5kHz\'];
indexFile = [path_wav 'file_dates-' glider '_SoCal_Feb20-5kHz.txt'];
fileExt = 'wav';


if ~exist(indexFile, 'file')
    makeFileDatesFunction(fileExt, path_wav, 1, indexFile);
end
hIndex = readHarufileDateIndex(indexFile);

if strcmp(glider, 'sg607')
    logFileName = [glider '_Pm_20200921_soundClips.log'];
elseif strcmp(glider, 'sg639')
    logFileName = [glider '_Pm_20201022_soundClips.log'];
end

%% check detections prep/run
%
% fileExt = 'wav';
% path_wav = 'E:\SoCal2020\sg607_downsampled\sg607-5kHz\';
% outFileName = [path_wav 'file_dates-sg607_SoCal_Feb20-5kHz.txt'];
% if ~exist(outFileName, 'file')
%     makeFileDatesFunction(fileExt, path_wav, 1, outFileName);
% end
%
% checkDetections SoCal_2020_sg607_Pm
% % marking other "clicky" sounds as not sures. Sound more like burst pulses


%% Ishmael detection checks

% checkDetections was pretty slow...so loaded sound clips into Ishmael and
% checked that way.
% marked each snippet as noise (eventually stopped marking these),
% burstPulse, clicks, or unknown (using hot keys)

% process Ish checked log to get counts/times of dets
% modified readDetLog to deal with detection lines that don't have any
% start time, threshold, etc. Just list snippet file name.


%% sperm clicks

% EXTRACT CHECKED DETECTIONS
searchstr = 'clicks';
[absTimes,relTimes,soundFiles,~,~] = ...
    readDetLog([path_out logFileName], hIndex, searchstr);
save([path_out logFileName(1:end-4) '_spermClicks.mat'], 'absTimes', 'relTimes', 'soundFiles');

% whats it look like?
% plot(absTimes(:,1), repmat(1, length(absTimes), 1), '.k')

% BIN BY HOUR
% load hour by hour matrix
pamEffortFile = ['E:\SoCal2020\profiles\' glider '\' glider '_SOCAL_Feb20_pamByMinHourDay.mat'];
load(pamEffortFile)

byHour = pamMinPerHour;
byHour.Properties.VariableNames{2} = 'recMins';

% convert to datetime so I can monitor more easily
absTimesDT = datetime(absTimes(:,1), 'ConvertFrom', 'datenum');

% loop through all hours
for f = 1:height(byHour)
    tf = isbetween(absTimesDT, byHour.hour(f), byHour.hour(f) + minutes(59) + seconds(59));
    byHour.numDets(f) = nnz(tf);
    
    if byHour.numDets(f) > 0
        byHour.presence(f) = 1;
    else
        byHour.presence(f) = 0;
    end
end

% now pull out just hours with detections
hourlyPresence = byHour(byHour.presence > 0, :);
% normalize the number of detections by the minutes recorded in hour
byHour.detsPerHour = byHour.numDets./byHour.recMins.*60;

% how many hours per day? 
for f = 1:height(pamHrPerDay)
        tf = isbetween(absTimesDT, pamHrPerDay.day(f), ...
            pamHrPerDay.day(f) + seconds(86399));
        pamHrPerDay.dets(f) = nnz(tf);
        tf = isbetween(byHour.hour(byHour.presence == 1), pamHrPerDay.day(f), ...
            pamHrPerDay.day(f) + seconds(86399));
        pamHrPerDay.detHours(f) = nnz(tf);
end
byDay = pamHrPerDay;


save([path_out logFileName(1:end-4) '_spermClicks_byHour.mat'], ...
    'byHour', 'hourlyPresence', 'byDay');

fprintf(1, 'Sperm whale click sequences detected by %s during %i hours over %i days\n', ...
    glider, sum(byHour.presence), sum(byDay.dets > 0));

%% Plot Sperm Clicks on Map
deploymentStr = 'SOCAL_Feb20';
path_profile = ['E:\SoCal2020\profiles\' glider '\'];
path_shp = 'C:\Users\selene\OneDrive\GIS\';

latlim = [30.8 33.8];
lonlim = [-121.2 -118];

load([path_profile glider '_' deploymentStr '_interpolatedTrack.mat']);
plotInterpolatedTrack_PAM(glider, sgInterp, path_shp, latlim, lonlim, [], 0)

mapFig = gcf;
mapFigPosition = [5200   -1350   900    900];
mapFig.Position = mapFigPosition;

% add labels
title('Sperm whale detections: SG607', 'FontSize', 18)

plotLandmarks
labelDatesTight(glider)

% add circles sperm whale click sequences - one circle per hour
% size by number of detections in that hour.
% get locations of glider at each hour (mean location avail per hour)

for f = 1:height(byHour)
    tmp = sgInterp(isbetween(sgInterp.dateTime, byHour.hour(f), ...
        byHour.hour(f) + seconds(3599)),:);
    byHour.latitude(f,1) = nanmean(tmp.latitude);
    byHour.longitude(f,1) = nanmean(tmp.longitude);  
end

% turn legend plotting back on (off for landmarks)**I don't know why I have
% to do it twice..but just do it...
h = scatterm(byHour.latitude(byHour.numDets > 0), ...
    byHour.longitude(byHour.numDets > 0), ...
    (byHour.numDets(byHour.numDets > 0)*10), ...
    'Marker', 'o', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [1 1 1], ...
    'DisplayName', 'sperm whale clicks');
set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','on');
legend('Location', 'northwest')

set(gcf, 'InvertHardCopy', 'off', 'color', 'w');

print([path_out 'map_' glider '_spermDetections_detsPerHour_final.png'], '-dpng')
% print([path_profile 'map_' glider '_surfaceTrack.eps'], '-depsc') (not
% editable in AI...bathy is too big imports as image
export_fig([path_out 'map_' glider '_spermDetections_detsPerHour_final.eps'], '-eps', '-painters');
savefig([path_out 'map_' glider '_spermDetections_detsPerHour_final.fig'])


% % PLOT EVERY DETECTION
% % get locations of glider at each time of sperm detections
% detLocs = table;
% detLocs.absTime = absTimesDT;
% 
% for f = 1:length(absTimesDT)
%     [~, idx] = min(abs(absTimesDT(f) - sgInterp.dateTime));
%     detLocs.latitude(f,1) = sgInterp.latitude(idx);
%     detLocs.longitude(f,1) = sgInterp.longitude(idx);
%     if isnan(detLocs.latitude(f,1)) % in case next minute recording off
%         detLocs.latitude(f,1) = sgInterp.latitude(idx-1);
%         detLocs.longitude(f,1) = sgInterp.longitude(idx-1);
%     end
% end
% 
% % turn legend plotting back on (off for landmarks)**I don't know why I have
% % to do it twice..but just do it...
% h = scatterm(detLocs.latitude, detLocs.longitude, 40, 'Marker', 'o', ...
%     'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [1 1 1], ...
%     'DisplayName', 'sperm whale clicks');
% set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','on');
% legend('Location', 'northwest')
% 
% print([path_out 'map_' glider '_spermDetections_v1.png'], '-dpng')
% % print([path_profile 'map_' glider '_surfaceTrack.eps'], '-depsc') (not
% % editable in AI...bathy is too big imports as image
% export_fig([path_out 'map_' glider '_spermDetections_v1.eps'], '-eps', '-painters');
% savefig([path_out 'map_' glider '_spermDetections_v1.fig'])



%% plot - bar plot

figure(10)
set(gcf, 'Position', [5600 -900 1300 420]);

yyaxis left
% plot gray bars of recording hours per instrument per day
bb = bar(pamHrPerDay.day, pamHrPerDay.pam, ...
   'FaceColor', 'flat', 'handlevisibility', 'off', 'BarWidth', 1);
    bb.CData = repmat([1 1 1],height(pamMinPerDay),1);
    bb.EdgeColor = [0.8 0.8 0.8];
set(gca, 'Ycolor', 'k', 'YLim', [0 24])
ylabel(sprintf('hours recorded\n[white bars]'))
set(gca, 'Color', [0.9 0.9 0.9]);

yyaxis right
b = bar(pamHrPerDay.day, pamHrPerDay.detHours, ...
   'FaceColor', 'flat', 'BarWidth', 1);
b.CData = [1 0.4 0.2];
ylabel(sprintf('hours with detections\n[orange bars]'))
set(gca, 'Ycolor', 'k', 'YLim', [0 24])

xlim([datetime(2020,02,06,12,0,0) datetime(2020,03,31)])
xticks([datetime(2020,02,07):days(7):datetime(2020,03,31)])
xtickangle(0)

title('Hours with sperm whale click sequences: SG607')
set(gca,'FontSize', 14)

set(gcf, 'InvertHardCopy', 'off', 'color', 'w');
print([path_out species '_' glider '_DetHoursPerDay_final.png'], '-dpng');
export_fig([path_out species '_' glider '_DetHoursPerDay_final.eps'], '-eps', '-painters');
savefig([path_out species '_' glider '_DetHoursPerDay_final.fig'])












%% % burst pulses
searchstr = 'burstPulse';
[absTimes,relTimes,soundFiles,~,~] = readDetLog([path_out logFileName], ...
    hIndex, searchstr);
save([path_out logFileName(1:end-4) '_burstPulses.mat'], 'absTimes', ...
    'relTimes', 'soundFiles');

% whats it look like?
% plot(absTimes(:,1), repmat(1, length(absTimes), 1), '.k')

% BIN BY HOUR
% load hour by hour matrix
pamEffortFile = ['E:\SoCal2020\profiles\' glider '\' glider '_SOCAL_Feb20_pamByMinHourDay.mat'];
load(pamEffortFile)

byHour = pamMinPerHour;
byHour.Properties.VariableNames{2} = 'recMins';

% convert to datetime so I can monitor more easily
absTimesDT = datetime(absTimes(:,1), 'ConvertFrom', 'datenum');

% loop through all hours
for f = 1:height(byHour)
    tf = isbetween(absTimesDT, byHour.hour(f), byHour.hour(f) + minutes(59) + seconds(59));
    byHour.numDets(f) = nnz(tf);
    
    if byHour.numDets(f) > 0
        byHour.presence(f) = 1;
    else
        byHour.presence(f) = 0;
    end
end

% now pull out just hours with detections
hourlyPresence = byHour(byHour.presence > 0, :);

% don't do anything with number of detections of normalizing. Just do
% presence/absence per hour.
save([path_out logFileName(1:end-4) '_burstPulses_byHour.mat'], ...
    'byHour', 'hourlyPresence');

fprintf(1, 'Burst pulses detected by %s during %i hours over %i days\n', ...
    glider, sum(byHour.presence), length(unique(day(hourlyPresence.hour))));

