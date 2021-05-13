% workflow to extract glider positions from deployment for Navy to send
% along with acoustic files

%% SG607

gldr = 'sg607';
lctn = 'SOCAL';
dplymnt = 'Feb20';
saveOn = 1;

path_in = ['C:\Users\selene\Box\HDR-SOCAL-2020\piloting\' gldr '\'];

% extract glider flight positions
[gpsSurfT, locCalcT] = positionalDataExtractor(gldr, lctn, dplymnt, saveOn, path_in);


% PAM Effort calculations
load([path_in gldr '_' lctn '_' dplymnt '_gpsSurfaceTable.mat']);

[gpsSurfT, locCalcT, pam] = extractPAMStatusByFile(gldr, lctn, dplymnt, ...
    fileLength, dateFormat, dateStart, gpsSurfT, locCalcT)

[pamByMin, pamMinPerHour, pamMinPerDay, pamHrPerDay] = ...
    calcPAMEffort(gldr, lctn, dplymnt, [], gpsSurfT, path_in);

%% SG639
gldr = 'sg639';
path_in = ['C:\Users\selene\Box\HDR-SOCAL-2018\piloting\' gldr '\'];
[gpsSurfT, locCalcT] = positionalDataExtractor(gldr, lctn, dplymnt, saveOn, path_in);


