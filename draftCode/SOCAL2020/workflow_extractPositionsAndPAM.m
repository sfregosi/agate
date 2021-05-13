% workflow to extract glider positions and PAM status for final report

addpath(genpath('C:\Users\selene\OneDrive\MATLAB\gliderTools\'));

%% set glider/paths

glider = 'sg607';
% glider = 'sg639';

deploymentStr = 'SOCAL_Feb20';
% lctn = 'SOCAL';
% dplymnt = 'Feb20';
saveOn = 1;

% path_profiles = ['C:\Users\selene\Box\HDR-SOCAL-2020\piloting\' gldr '\'];
path_profile = ['E:\SoCal2020\profiles\' glider '\'];


%% extract glider flight positions
% creates and saves gpsSurfTable.mat and locCalcT.mat
if ~exist([path_profile glider '_' deploymentStr '_gpsSurfaceTable.mat'], 'file') ...
        || ~exist([path_profile glider '_' deploymentStr '_locCalcT.mat'], 'file')
    [gpsSurfT, locCalcT] = positionalDataExtractor(glider, deploymentStr, saveOn, path_profile);
else
    load([path_profile glider '_' deploymentStr '_gpsSurfaceTable.mat']);
    load([path_profile glider '_' deploymentStr '_locCalcT.mat']);
end

% plot sound speed profile if desired
% will be prompted to enter title for figure.
% opted to save it in this case
plotSoundSpeedProfile(locCalcT, path_profile)


%% PAM Effort calculations
fileLength = 600; % in seconds. this is what it should be...not all are this long?
dateFormat = 'yyMMdd-HHmmss.SSS';   % in datetime input format sytnax
dateStart = 1; % what part of file name starts the date format

% creates and saves gpsSurfTable_pam.mat and locCalcT_pam.mat and _pamByFile.mat
if ~exist([path_profile glider '_' deploymentStr '_gpsSurfaceTable_pam.mat'], 'file') ...
        || ~exist([path_profile glider '_' deploymentStr '_locCalcT_pam.mat'], 'file')
    [gpsSurfT, locCalcT, pam] = extractPAMStatusByFile(glider, deploymentStr, ...
        fileLength, dateFormat, dateStart, gpsSurfT, locCalcT);
else
    load([path_profile glider '_' deploymentStr '_gpsSurfaceTable_pam.mat']);
    load([path_profile glider '_' deploymentStr '_locCalcT_pam.mat']);
    load([path_profile glider '_' deploymentStr '_pamByFile.mat']);

end

% creates and saves pamByMinHourDay.mat and _pamByMin.csv
[pamByMin, pamMinPerHour, pamMinPerDay, pamHrPerDay] = ...
    calcPAMEffort(glider, deploymentStr, [], gpsSurfT, path_profile);

% Extract positional data for each acoustic file
secs = 180; % buffer around sound file to look for glider position

% create and save _pamFilePosits.mat and .csv
filePosits = extractPositsPerPAMFile(glider, deploymentStr, ...
    pam, locCalcT, secs, path_profile);

%% interpolated positions
% saves _interpolatedTrack.mat for plotting with pam on/off
sgInterp = interpGlider(glider, deploymentStr, [], path_profile);


