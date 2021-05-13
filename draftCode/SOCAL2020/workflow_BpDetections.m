% processing fin whale detections

addpath(genpath('C:\Users\selene\OneDrive\MATLAB\wutils\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\DaveWhales\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\utils\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\osprey\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\gliderTools\'));

glider = 'sg607';
% glider = 'sg639'; 
species = 'Bp';

path_out = ['E:\SoCal2020\largeWhaleAnalysis\' species '\' species '_' glider '\'];
path_wav = ['E:\SoCal2020\' glider '_downsampled\' glider '-1kHz\'];
indexFile = [path_wav 'file_dates-' glider '_SoCal_Feb20-1kHz.txt'];
fileExt = 'wav';

if ~exist(indexFile, 'file')
    makeFileDatesFunction(fileExt, path_wav, 1, indexFile);
end
hIndex = readHarufileDateIndex(indexFile);

% logFileName = [glider '_Bp_20201022.log'];
logFileName = [glider '_Bp_20201022-checked_10min.log'];


%% check detections prep/run

% checkDetections SoCal_2020_sg607_Bp
% checkDetections SoCal_2020_sg639_Bp


%% Clean up/extract checked detections
% For SG607 checked detections by 10 min bins. 
% Need to clean up checked detections - remove duplicates

cleanFileName = [path_out logFileName(1:end-4) '_clean.log'];
removeDetLogDuplicates([path_out logFileName], cleanFileName);

% extract checked detections
[absTimes, relTimes, soundFiles, peakInfo, ~] = ...
    readDetLog(cleanFileName, hIndex);

save([cleanFileName(1:end-4) '.mat'], 'absTimes', 'relTimes', 'soundFiles');

% whats it look like?
% plot(absTimes(:,1), repmat(1, length(absTimes), 1), '.k')


%% bin by hour

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
    tf = isbetween(absTimesDT, byHour.hour(f), byHour.hour(f) + seconds(3599));
    byHour.numDets(f) = nnz(tf);
    
    if byHour.numDets(f) > 0
        byHour.presence(f) = 1;
    else
        byHour.presence(f) = 0;
    end
end

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

% save.
save([cleanFileName(1:end-4) '_byHour.mat'], ...
    'byHour', 'hourlyPresence', 'byDay');

fprintf(1, 'Fin whale 20 Hz calls detected by %s during %i hours over %i days\n', ...
    glider, sum(byHour.presence), sum(byDay.dets > 0));

%% Plot on Map
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
if strcmp(glider, 'sg607')
    title('Fin whale detections: SG607', 'FontSize', 18)
elseif strcmp(glider, 'sg639')
    title('Fin whale detections: SG639', 'FontSize', 18)
end

plotLandmarks

labelDatesTight(glider)

% add circles for fin whale pulses
% size by number 10 min bins with calls in that hour
% get locations of glider at each hour (mean location avail per hour)

for f = 1:height(byHour)
    tmp = sgInterp(isbetween(sgInterp.dateTime, byHour.hour(f), ...
        byHour.hour(f) + minutes(59)),:);
    byHour.latitude(f,1) = nanmean(tmp.latitude);
    byHour.longitude(f,1) = nanmean(tmp.longitude);  
end

% turn legend plotting back on (off for landmarks)**I don't know why I have
% to do it twice..but just do it...
h = scatterm(byHour.latitude(byHour.numDets > 0), ...
    byHour.longitude(byHour.numDets > 0), ...
    (byHour.numDets(byHour.numDets > 0)).^2, ...
    'Marker', 'o', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [1 1 1], ...
    'DisplayName', 'fin whale');
set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','on');
legend('Location', 'northwest')

set(gcf, 'InvertHardCopy', 'off', 'color', 'w');

print([path_out 'map_' glider '_finWhale_detsPerHour_10minBins_final.png'], '-dpng')
% print([path_profile 'map_' glider '_surfaceTrack.eps'], '-depsc') (not
% editable in AI...bathy is too big imports as image
export_fig([path_out 'map_' glider '_finWhale_detsPerHour_10minBins_final.eps'], '-eps', '-painters');
savefig([path_out 'map_' glider '_finWhale_detsPerHour_10minBins_final.fig'])

%% plot - bar plot

figure(10); clf
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

% xlim([pamHrPerDay.day(1)-hours(12) pamHrPerDay.day(end)]);
xlim([datetime(2020,02,06,12,0,0) datetime(2020,03,31)])
xticks([datetime(2020,02,07):days(7):datetime(2020,03,31)])
xtickangle(0)

if strcmp(glider, 'sg607')
    title('Hours with fin whale 20 Hz pulse detections: SG607')
elseif strcmp(glider, 'sg639')
    title('Hours with fin whale 20 Hz pulse detections: SG639')
end
set(gca,'FontSize', 14)

set(gcf, 'InvertHardCopy', 'off', 'color', 'w');
print([path_out species '_' glider '_DetHoursPerDay_10minBins_final.png'], '-dpng');
export_fig([path_out species '_' glider '_DetHoursPerDay_10minBins_final.eps'], '-eps', '-painters');
savefig([path_out species '_' glider '_DetHoursPerDay_10minBins_final.fig'])













