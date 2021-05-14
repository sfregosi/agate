% processing blue whale detections

addpath(genpath('C:\Users\selene\OneDrive\MATLAB\wutils\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\DaveWhales\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\utils\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\gliderTools\'));

glider = 'sg607';
% glider = 'sg639'; % NO Detections in SG639.
species = 'Bm';
deploymentStr = 'SOCAL_Feb20';

path_out = ['E:\SoCal2020\largeWhaleAnalysis\Bm\Bm_' glider '\'];
path_wav = ['E:\SoCal2020\' glider '_downsampled\' glider '-1kHz\'];
indexFile = [path_wav 'file_dates-' glider '_SoCal_Feb20-1kHz.txt'];
fileExt = 'wav';
path_profile = ['E:\SoCal2020\profiles\' glider '\'];
path_shp = 'C:\Users\selene\OneDrive\GIS\';

if ~exist(indexFile, 'file')
    makeFileDatesFunction(fileExt, path_wav, 1, indexFile);
end
hIndex = readHarufileDateIndex(indexFile);

% logFileName = 'sg607_Bm_20200918.log';
logFileName = 'sg607_Bm_20200918-checked.log';

% glider = 'sg639';
% % logFileName = 'sg639_Bm_20201007.log';
% logFileName = 'sg639_Bm_20201007_run2.log';

path_deliverables = 'E:\SoCal2020\deliverables\';

%% Check Detections
% 
% checkDetections SoCal_2020_sg607_Bm
% % checkDetections SoCal_2020_sg639_Bm
% 
% logFileName = 'sg607_Bm_20200918-checked.log';

%% bin by hour

% extract checked detections
[absTimes, relTimes, soundFiles, peakInfo, effortTimes] = ...
    readDetLog([path_out logFileName], hIndex);
save([path_out logFileName(1:end-4) '.mat'], 'absTimes', 'relTimes', 'soundFiles');

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
save([path_out logFileName(1:end-4) '_byHour.mat'], ...
    'byHour', 'hourlyPresence', 'byDay');

fprintf(1, 'Blue whale B calls detected by %s during %i hours over %i days\n', ...
    glider, sum(byHour.presence), length(unique(day(hourlyPresence.hour))));

%% Plot on Map
deploymentStr = 'SOCAL_Feb20';
path_profile = ['E:\SoCal2020\profiles\' glider '\'];
path_shp = 'C:\Users\selene\OneDrive\GIS\';

latlim = [30.8 33.8];
lonlim = [-121.2 -118];

load([path_profile glider '_' deploymentStr '_interpolatedTrack.mat']);
plotInterpolatedTrack_PAM(glider, sgInterp, path_shp, latlim, lonlim, [], 0)

mapFig = gcf;
mapFigPosition = [50 50  900  900];
mapFig.Position = mapFigPosition;

% add labels
title('Blue whale detections: SG607', 'FontSize', 18)

plotLandmarks

labelDatesTight(glider)

% add circles for Blue whale B calls - one circle per hour
% size by number of detections in that hour.
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
    byHour.numDets(byHour.numDets > 0)*10, ...
    'Marker', 'o', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [1 1 1], ...
    'DisplayName', 'blue whale');
set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','on');
legend('Location', 'northwest')

set(gcf, 'InvertHardCopy', 'off', 'color', 'w');

print([path_out 'map_' glider '_blueWhale_detsPerHour_final.png'], '-dpng')
% print([path_profile 'map_' glider '_surfaceTrack.eps'], '-depsc') (not
% editable in AI...bathy is too big imports as image
export_fig([path_out 'map_' glider '_blueWhale_detsPerHour_final.eps'], '-eps', '-painters');
savefig([path_out 'map_' glider '_blueWhale_detsPerHour_final.fig'])



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

xlim([pamHrPerDay.day(1)-hours(12) pamHrPerDay.day(end)]);
title('Hours with blue whale B call detections: SG607')
set(gca,'FontSize', 14)

set(gcf, 'InvertHardCopy', 'off', 'color', 'w');
print([path_out species '_' glider '_DetHoursPerDay_final.png'], '-dpng');
export_fig([path_out species '_' glider '_DetHoursPerDay_final.eps'], '-eps', '-painters');
savefig([path_out species '_' glider '_DetHoursPerDay_final.fig'])


% %% plot - scatter plot
% figure;
% 
% plot(byHour.hour, byHour.normDets, 'k.');
% % xlim(effortTimesDT)
% % effort from files not log
% xlim([dh(1) dh(end)]);
% ylabel('normalized detections per hour')
% title('Blue whale B call Detections - SG607')
% datetick('x', 'mm/dd', 'keeplimits')
% set(gca, 'FontSize', 12)
% grid on
% 
% print([path_detOut species '_DetsByHour_' glider '_normalized.png'], '-dpng');
% 
% 
% %% spectrogram for report
% detSounds = dir([path_detOut glider '_' species '_detectedSoundClips\*.wav']);
% 
% % import sound clip
% s = 74;
% [sig, fs] = audioread([detSounds(s).folder '\' detSounds(s).name]);
% 
% % calc fft
% win = 1024;
% novr = round(win*.95);
% nfft = win;
% [SC,FC,TC,PC] = spectrogram(sig,win,novr,nfft,fs);
% 
% % plot
% figure(10)
% set(gcf,'Color','white')
% imagesc(TC,FC,10*log10(PC)); % axes here make no sense - must fill them in
% set(gca,'YDir','normal', 'FontSize', 14);
% xlabel('time (secs)'); ylabel('frequency (Hz)');
% ylim([0 80]);
% colormap(jet)
% caxis([-100 -60]); % don't change across a CEE;
% colorbar
% 
% print([path_detOut species '_exampleCall.png'], '-dpng');


%% Save outputs for deliverables

load([path_out logFileName(1:end-4) '_byHour.mat']);

% save byHour with locations as table and shapefile for deliverables
writetable(byHour, [path_deliverables glider '_' deploymentStr '_' species '_byHour.csv']);

% points shape file with points every hour with total recorded minutes in
% that hour and the number of detections, presence, and normalized dets per
% hour
byHourDetsToShapefile(glider, deploymentStr, species, byHour, path_deliverables);
