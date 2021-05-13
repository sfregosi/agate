% workflow to extract glider positions from deployment for Navy to send
% along with acoustic files

addpath(genpath('C:\Users\selene\OneDrive\MATLAB\gliderTools\'));

%% SG607

gldr = 'sg607';
lctn = 'SOCAL';
dplymnt = 'Feb20';
saveOn = 1;

% path_profiles = ['C:\Users\selene\Box\HDR-SOCAL-2020\piloting\' gldr '\'];
path_profiles = ['E:\SoCal2020\profiles\' gldr '\'];

% extract glider flight positions
% creates and saves gpsSurfTable.mat and locCalcT.mat
if ~exist([path_profiles gldr '_' lctn '_' dplymnt '_gpsSurfaceTable.mat'], 'file') ...
        || ~exist([path_profiles gldr '_' lctn '_' dplymnt '_locCalcT.mat'], 'file')
    [gpsSurfT, locCalcT] = positionalDataExtractor(gldr, lctn, dplymnt, saveOn, path_profiles);
else
    load([path_profiles gldr '_' lctn '_' dplymnt '_gpsSurfaceTable.mat']);
    load([path_profiles gldr '_' lctn '_' dplymnt '_locCalcT.mat']);
end

% plot sound speed profile if desired
% will be prompted to enter title for figure.
% opted to save it in this case
plotSoundSpeedProfile(locCalcT, path_profiles)


% PAM Effort calculations
fileLength = 600; % in seconds. this is what it should be...not all are this long?
dateFormat = 'yyMMdd-HHmmss.SSS';   % in datetime input format sytnax
dateStart = 1; % what part of file name starts the date format

% creates and saves gpsSurfTable_pam.mat and locCalcT_pam.mat and _pamByFile.mat
[gpsSurfT, locCalcT, pam] = extractPAMStatusByFile(gldr, lctn, dplymnt, ...
    fileLength, dateFormat, dateStart, gpsSurfT, locCalcT);

% creates and saves pamByMinHourDay.mat and _pamByMin.csv
[pamByMin, pamMinPerHour, pamMinPerDay, pamHrPerDay] = ...
    calcPAMEffort(gldr, lctn, dplymnt, [], gpsSurfT, path_profiles);

% Extract positional data for each acoustic file
secs = 180; % buffer around sound file to look for glider position

% create and save _pamFilePosits.mat and .csv
filePosits = extractPositsPerPAMFile(gldr, lctn, dplymnt, ...
    pam, locCalcT,secs, path_profiles);





%% SG639

gldr = 'sg639';
lctn = 'SOCAL';
dplymnt = 'Feb20';
saveOn = 1;

% path_profiles = ['C:\Users\selene\Box\HDR-SOCAL-2020\piloting\' gldr '\'];
path_profiles = ['E:\SoCal2020\profiles\' gldr '\'];

% extract glider flight positions
% creates and saves gpsSurfTable.mat and locCalcT.mat
if ~exist([path_profiles gldr '_' lctn '_' dplymnt '_gpsSurfaceTable.mat'], 'file') ...
        || ~exist([path_profiles gldr '_' lctn '_' dplymnt '_locCalcT.mat'], 'file')
    [gpsSurfT, locCalcT] = positionalDataExtractor(gldr, lctn, dplymnt, saveOn, path_profiles);
else
    load([path_profiles gldr '_' lctn '_' dplymnt '_gpsSurfaceTable.mat']);
    load([path_profiles gldr '_' lctn '_' dplymnt '_locCalcT.mat']);
end

% plot sound speed profile if desired
% will be prompted to enter title for figure.
% opted to save it in this case
plotSoundSpeedProfile(locCalcT, path_profiles)


% PAM Effort calculations
fileLength = 600; % in seconds. this is what it should be...not all are this long?
dateFormat = 'yyMMdd-HHmmss.SSS';   % in datetime input format sytnax
dateStart = 1; % what part of file name starts the date format

% creates and saves gpsSurfTable_pam.mat and locCalcT_pam.mat and _pamByFile.mat
[gpsSurfT, locCalcT, pam] = extractPAMStatusByFile(gldr, lctn, dplymnt, ...
    fileLength, dateFormat, dateStart, gpsSurfT, locCalcT);

% creates and saves pamByMinHourDay.mat and _pamByMin.csv
[pamByMin, pamMinPerHour, pamMinPerDay, pamHrPerDay] = ...
    calcPAMEffort(gldr, lctn, dplymnt, [], gpsSurfT, path_profiles);

% Extract positional data for each acoustic file
secs = 180; % buffer around sound file to look for glider position

% create and save _pamFilePosits.mat and .csv
filePosits = extractPositsPerPAMFile(gldr, lctn, dplymnt, ...
    pam, locCalcT,secs, path_profiles);


