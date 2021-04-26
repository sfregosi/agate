% SoCal Deployment 2020 - SG607

% ********** SG607 **************

%% set paths
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\gliderTools\'));
addpath(genpath('C:\Users\selene\Box\HDR-SOCAL-2018\piloting\SeagliderPilotingTools_1.3.R3\Matlab\'));

glider = 'sg607';
pmCard = 1;
path_out = ['C:\Users\selene\Box\HDR-SOCAL-2018\piloting\' glider '\'];
path_base = [path_out 'basestationFiles\'];
path_shp = 'C:\Users\selene\OneDrive\projects\AFFOGATO\CatalinaComparison\profiles\matlabMapping\';

%%download files from the basestation
basestationFileExtract_PMAR(glider, pmCard, path_base)

% DiveData

%% extract various piloting parameters and values reported by .log file
pp607 = extractPilotingParams(glider, pmCard, path_base);
pp607.ERRORS(end)
writetable(pp607, [path_out 'diveTracking_' glider '.xlsx']);
writetable(pp607, ['C:\Users\selene\Box\HDR-SOCAL-2018\flight status\diveTracking_' glider '.xlsx']);
save([path_base 'diveTracking_' glider '.mat'], 'pp607');

%% plots
% create and print plot of battery usage and free space on PMAR
if pmCard == 0
    plot_BatteryUsageAndFreeSpace_SD1(glider, pp607);
elseif pmCard == 1
    plot_BatteryUsageAndFreeSpace_SD2(glider, pp607);
end
print(['C:\Users\selene\Box\HDR-SOCAL-2018\flight status\battUseFreeSpace_' glider '.png'], '-dpng')

plot_voltagePackUse(glider, pp607)
print(['C:\Users\selene\Box\HDR-SOCAL-2018\flight status\usageByDevice_' glider '.png'], '-dpng')

plot_humidityPressure(glider, pp607)
print(['C:\Users\selene\Box\HDR-SOCAL-2018\flight status\humidityPressure_' glider '.png'], '-dpng')

% print map **SLOW**
% plotGliderPath(glider, pp, path_out, path_shp);
% plotGliderPath_etopo(glider, pp607, path_out, path_shp, 204);
plotGliderPath_etopo_recovery(glider, pp607, path_out, path_shp, 206);
print(['C:\Users\selene\Box\HDR-SOCAL-2018\flight status\map_' glider '.png'], '-dpng')
savefig(['C:\Users\selene\Box\HDR-SOCAL-2018\flight status\map_' glider '.fig'])