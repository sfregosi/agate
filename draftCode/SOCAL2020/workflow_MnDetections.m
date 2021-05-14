% processing humpback whale detections

addpath(genpath('C:\Users\selene\OneDrive\MATLAB\wutils\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\DaveWhales\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\utils\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\gliderTools\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\GPL\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\osprey\'));


glider = 'sg607';
% glider = 'sg639';
species = 'Mn';
deploymentStr = 'SOCAL_Feb20';

path_wav = ['E:\SoCal2020\' glider '_downsampled\' glider '-5kHz\'];
path_out = ['E:\SoCal2020\largeWhaleAnalysis\' species '\' species '_' glider '\'];
indexFile = [path_wav 'file_dates-' glider '_SoCal_Feb20-5kHz.txt'];
fileExt = 'wav';
path_profile = ['E:\SoCal2020\profiles\' glider '\'];
path_shp = 'C:\Users\selene\OneDrive\GIS\';

if ~exist(indexFile, 'file')
    makeFileDatesFunction(fileExt, path_wav, 1, indexFile);
end
hIndex = readHarufileDateIndex(indexFile);

% detFile = 'detections_GPL_v2_150_1000_sg607_SOCAL_Feb20_allFiles.mat';
% detFile = 'detections_GPL_v2_150_1000_sg6397_SOCAL_Feb20_Fdrive.mat';
% detFile = 'detections_GPL_v2_150_1000_sg607_SOCAL_Feb20_exampleFiles.mat';

tritonFile = [glider '_Mn_manualLog.xls'];

path_deliverables = 'E:\SoCal2020\deliverables\';

%% convert GPL output to "Ishmael" log file

% load([path_det detFile]);
% logFile = [path_det detFile(1:end-4) '.log'];
% GPL_detsToLogFile(hyd, logFile, path_wav);
%
% clear hyd

%% check detections

% checkDetections SoCal_2020_sg607_Mn
% checkDetections SoCal_2020_sg639_Mn


% %% GPL Review
% % modify detection output to try to read into GPLreview from SIO
% load([path_det detFile]);
% bt(:,1) = [hyd.detection.calls(:).julian_start_time]';
% bt(:,2) = [hyd.detection.calls(:).julian_end_time]';
%
% save([path_det 'detsAsbt.mat'], 'bt');
%
% % couldn't get this to work. Put in issue request on GitHub

%% Working with Triton Outputs

% read in the triton log file
tt = readtable([path_out tritonFile]);
% times are already in datetime!

% loop through every ten mins/1 hour and see if calls are present
% load hour by hour matrix
pamEffortFile = ['E:\SoCal2020\profiles\' glider '\' glider '_SOCAL_Feb20_pamByMinHourDay.mat'];
load(pamEffortFile)

byHour = pamMinPerHour;
byHour.Properties.VariableNames{2} = 'recMins';

% loop through all hours
for f = 1:height(byHour)
    % is the start time within the hour?
    tf = isbetween(tt.StartTime, byHour.hour(f), byHour.hour(f) + seconds(3599));
    %     byHour.numDets(f) = nnz(tf); % don't want to count dets because might have marked twice/overlapping
    
    if nnz(tf) > 0 % start time is within this hour
        byHour.presence(f) = 1; % mark present
        byHour.score(f) = tt.Parameter1(find(tf > 0, 1, 'last'));
    else % start time is not within the looped hour
        % check if the hour is within any start and end time? (encounter
        % that spans multiple hours)
        tf2 = isbetween(byHour.hour(f), tt.StartTime, tt.EndTime);
        if nnz(tf2) > 0 % hour start is within an encounter
            byHour.presence(f) = 1; % mark present
            byHour.score(f) = tt.Parameter1(find(tf2 > 0, 1, 'last'));
        else % hour is not within an encounter and a start time is not within this hour
            byHour.presence(f) = 0; % mark absent
            byHour.score(f) = nan;
        end
    end
end

% add presence nans when pam is off
byHour.presence(isnan(byHour.recMins)) = nan;

hourlyPresence = byHour(byHour.presence > 0, :);

% how many hours per day?
for f = 1:height(pamHrPerDay)
    tf = isbetween(byHour.hour(byHour.presence == 1), pamHrPerDay.day(f), ...
        pamHrPerDay.day(f) + seconds(86399));
    pamHrPerDay.detHours(f) = nnz(tf);
end
byDay = pamHrPerDay;

% save.
save([path_out tritonFile(1:end-4) '_byHour.mat'], ...
    'byHour', 'hourlyPresence', 'byDay');

fprintf(1, 'Humpback whales detected by %s during %i hours over %i days\n', ...
    glider, nansum(byHour.presence), nansum(byDay.detHours > 0));



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
    title('Humpback whale detections: SG607', 'FontSize', 18)
elseif strcmp(glider, 'sg639')
    title('Humpback whale detections: SG639', 'FontSize', 18)
end

plotLandmarks

labelDatesTight(glider)

% add circles for humpback whale calls - one circle per hour
% size by qualitative score
% get locations of glider at each hour (mean location avail per hour)

for f = 1:height(byHour)
    tmp = sgInterp(isbetween(sgInterp.dateTime, byHour.hour(f), ...
        byHour.hour(f) + minutes(59)),:);
    byHour.latitude(f,1) = nanmean(tmp.latitude);
    byHour.longitude(f,1) = nanmean(tmp.longitude);
end

% turn legend plotting back on (off for landmarks)**I don't know why I have
% to do it twice..but just do it...
h = scatterm(byHour.latitude(byHour.presence > 0), ...
    byHour.longitude(byHour.presence > 0), ...
    (byHour.score(byHour.presence > 0)*3).^2, ...
    'Marker', 'o', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [1 1 1], ...
    'DisplayName', 'humpback whale');
set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','on');
legend('Location', 'northwest')

set(gcf, 'InvertHardCopy', 'off', 'color', 'w');

print([path_out 'map_' glider '_humpbackWhale_hourlyScored_final.png'], '-dpng')
% print([path_profile 'map_' glider '_surfaceTrack.eps'], '-depsc') (not
% editable in AI...bathy is too big imports as image
export_fig([path_out 'map_' glider '_humpbackWhale_hourlyScored_final.eps'], '-eps', '-painters');
savefig([path_out 'map_' glider '_humpbackWhale_hourlyScored_final.fig'])

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
    title('Hours with humpback calls: SG607')
elseif strcmp(glider, 'sg639')
    title('Hours with humpback calls: SG639')
end
set(gca,'FontSize', 14)

set(gcf, 'InvertHardCopy', 'off', 'color', 'w');
print([path_out species '_' glider '_DetHoursPerDay_final.png'], '-dpng');
export_fig([path_out species '_' glider '_DetHoursPerDay_final.eps'], '-eps', '-painters');
savefig([path_out species '_' glider '_DetHoursPerDay_final.fig'])





%% Save outputs for deliverables

load([path_out glider '_' species '_manualLog_byHour.mat']);
load([path_profile glider '_' deploymentStr '_interpolatedTrack.mat']);

for f = 1:height(byHour)
    tmp = sgInterp(isbetween(sgInterp.dateTime, byHour.hour(f), ...
        byHour.hour(f) + minutes(59)),:);
    byHour.latitude(f,1) = nanmean(tmp.latitude);
    byHour.longitude(f,1) = nanmean(tmp.longitude);  
end

% save byHour with locations as table and shapefile for deliverables
writetable(byHour, [path_deliverables glider '_' deploymentStr '_' species '_byHour.csv']);

% points shape file with points every hour with total recorded minutes in
% that hour and the score of vocalization density (1 to 5) of calls were
% present
byHourScoreToShapefile(glider, deploymentStr, species, byHour, path_deliverables);








