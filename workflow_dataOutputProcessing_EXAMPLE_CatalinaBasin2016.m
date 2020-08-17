% workflow
% glider data output processing for Catalina Basin 2016

% 2019 09 03
% involved some updates over past versions, so wanted to record all here. 
% new outputs should overwrite old ones - but saved those in "old" folder


%% EXTRACT POSITIONAL DATA

gldr = 'sg607';
lctn = 'CatBasin';
dplymnt = 'Jul16';
% save in default location or no?
saveOn = 1;

% can specify path in - to folder ABOVE basestationFiles folder
% or leave argument blank and will be able to select it. 
path_profiles = ['C:\Users\selene\OneDrive\projects\AFFOGATO\' ...
    'CatalinaComparison\profiles\' gldr '_' lctn '_' dplymnt '\']; 

[gpsSurfT, locCalcT] = positionalDataExtractor(gldr, lctn, dplymnt, saveOn, path_profiles);
% saved automatically gpsSurfTable.mat and locCalcT.mat

% close figs 
close all

% plot sound speed profile if desired
% will be prompted to enter title for figure. 
% opted to save it in this case
plotSoundSpeedProfile(locCalcT, path_profiles)

%% Extract Acoustic Data

fileLength = 120; % in seconds
dateFormat = 'yyMMdd-HHmmss';
dateStart = 1; % what part of file name starts the date format

[gpsSurfT, locCalcT, pam] = extractPAMStatusByFile(gldr, lctn, dplymnt, ...
    fileLength, dateFormat, dateStart, gpsSurfT, locCalcT);
% saved automatically gpsSurfTable_pam.mat and locCalcT_pam.mat and
% _pamByFile.mat

%% Extract positional data for each acoustic file
secs = 180;

filePosits = extractPositsPerPAMFile(gldr, lctn, dplymnt, ...
    pam, locCalcT,secs, path_profiles);

% this saves _pamFilePosits.mat and .csv

%% BY minute
% create byMin, minPerHour, minPerDay matrices for full experiment extent
% will need this for comparison down the line
[pamByMin, pamMinPerHour, pamMinPerDay] = ...
    calcPAMEffort(gldr, lctn, dplymnt, expLimits, gpsSurfT, path_profiles);
% this saves _pamByMin.mat






