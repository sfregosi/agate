% processing minke whale detections


%% check detections prep/run
% **doesn't work because diff log file format! 

addpath(genpath('C:\Users\selene\OneDrive\MATLAB\wutils\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\DaveWhales\'));

fileExt = 'wav';
path_wav = 'E:\SoCal2020\sg607_downsampled\sg607-10kHz\';
outFileName = [path_wav 'file_dates-sg607_SoCal_Feb20-10kHz.txt'];
makeFileDatesFunction(fileExt, path_wav, 1, outFileName);

checkDetections SoCal_2020_sg607_Ba

%% Ishmael detection checks
  
% got through first 1649 files in Ishmael in about 1.5 hours. 
% No minke's so far. 
% primarily triggering on glider roll noise, glider pump noise, and
% humpbacks. Also sometimes surface noise. 







%%
% bin by hour
% bin by file (up to 10 min duty cycle bins)

addpath(genpath('C:\Users\selene\OneDrive\MATLAB\wutils\'));

path_detOut = 'E:\SoCal2020\detectorOutputs\sg607_Bp\';
logFileName = [path_detOut 'sg607_Bp_20200923.log'];
haruDateFile = 'E:\SoCal2020\sg607_downsampled\sg607-1kHz\file_dates-sg607_SoCal_Feb20-1kHz.txt';
pamEffortFile = 'E:\SoCal2020\profiles\sg607\sg607_SOCAL_Feb20_pamByMinHourDay.mat';
load(pamEffortFile)

hIndex = readHarufileDateIndex(haruDateFile);

[absTimes, relTimes, soundFiles, peakInfo, effortTimes] = ...
    readDetLog(logFileName, hIndex);

% define hour bins create empty table
% dh = [effortTimes(1):1/(86400/60/60):effortTimes(2)]';
effortTimesDT = dateshift(datetime(effortTimes, 'ConvertFrom', 'datenum'), ...
    'start', 'minute');

dh = [dateshift(effortTimesDT(1), 'start', 'hour'):hours(1): ...
    dateshift(effortTimesDT(2), 'start', 'hour')]';

% create empty hour by hour matrix

% loop through every hour, and check if there were clicks in that hour.
% Tally the number of minutes in that hour containing clicks.
byHour = table;
byHour.hour = dh;

[r1, ~] = find(pamMinPerHour.hour == byHour.hour(1));
[re, ~] = find(pamMinPerHour.hour == byHour.hour(end));
if re == height(byHour)
    byHour.recMin = pamMinPerHour.pam(r1:re);
end

absTimesDT = datetime(absTimes(:,1), 'ConvertFrom', 'datenum');


for f = 1:height(byHour) 
    tf = isbetween(absTimesDT, byHour.hour(f), byHour.hour(f) + minutes(59) + seconds(59));
    byHour.numDets(f) = nnz(tf);
    
    if byHour.numDets(f) > 0
        byHour.presence(f) = 1;
    else
        byHour.presence(f) = 0;
    end
end

max(byHour.numDets)
byHour.scaledDets = byHour.numDets/max(byHour.numDets);
byHour.normDets = byHour.numDets./byHour.recMin.*60;

plot(byHour.hour, byHour.scaledDets, 'k.');

figure;
plot(byHour.hour, byHour.normDets, 'k.');
xlim(effortTimesDT)
ylabel('normalized detections per hour')
title('Fin 20 Hz Detections - SG607')
datetick('x', 'mm/dd', 'keeplimits')
set(gca, 'FontSize', 12)
grid on

print([path_detOut 'finDetsByHour_sg607_normalized.png'], '-dpng');

