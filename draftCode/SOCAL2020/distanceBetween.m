% how far apart were the gliders in the beginning?


%% SET PATHS
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\gliderTools\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\myFunctions\'));

deploymentStr = 'SOCAL_Feb20';
path_shp = 'C:\Users\selene\OneDrive\GIS\';

%% load sg607 surface data
glider = 'sg607';
path_profile = ['E:\SoCal2020\profiles\' glider '\'];
path_piloting = ['C:\Users\selene\Box\HDR-SOCAL-2020\piloting\' glider '\'];

load([path_profile glider '_' deploymentStr '_gpsSurfaceTable_pam.mat']);
gpsSurfT_sg607 = gpsSurfT;

load([path_profile glider '_' deploymentStr '_interpolatedTrack.mat']);
sgInterp_sg607 = sgInterp;

%% load sg639 surface data
glider = 'sg639';
path_profile = ['E:\SoCal2020\profiles\' glider '\'];
path_piloting = ['C:\Users\selene\Box\HDR-SOCAL-2020\piloting\' glider '\'];

load([path_profile glider '_' deploymentStr '_gpsSurfaceTable_pam.mat']);
gpsSurfT_sg639 = gpsSurfT;

load([path_profile glider '_' deploymentStr '_interpolatedTrack.mat']);
sgInterp_sg639 = sgInterp;


%% plot
figure;
colorline(gpsSurfT_sg639.startLongitude, gpsSurfT_sg639.startLatitude, 's-', ...
'LineWidth', 2)
hold on;
plot(gpsSurfT_sg607.startLongitude, gpsSurfT_sg607.startLatitude, 's-', ...
'LineWidth', 2)

%% plot
figure; hold on;
color_line3(sgInterp_sg639.longitude, sgInterp_sg639.latitude, ...
    datenum(sgInterp_sg639.dateTime), datenum(sgInterp_sg639.dateTime), ...
    'LineWidth', 2);
color_line3(sgInterp_sg607.longitude(1:7720), sgInterp_sg607.latitude(1:7720), ...
    datenum(sgInterp_sg607.dateTime(1:7720)), datenum(sgInterp_sg607.dateTime(1:7720)), ...
    'LineWidth', 2);


%% min by min distance
% sg639 interp starts at 2/7 16:55
% sg607 interp starts at 2/7 15:20
% so they line up at sg639 row 1, sg607 row 96

% trim them
i_sg639 = sgInterp_sg639(1:7000,:);
i_sg607 = sgInterp_sg607(96:7095,:);
%check
i_sg607.dateTime(7000)
i_sg639.dateTime(7000)

% get dists
dist = table;
dist.min = sgInterp_sg639.dateTime(1:7000);
for f = 1:height(dist)
[dist.km_hav(f,1) dist.km_pyth(f,1)] = lldistkm([i_sg639.latitude(f) i_sg639.longitude(f)], ...
    [i_sg607.latitude(f) i_sg607.longitude(f)]);
end

nanmean(dist.km_hav)
histogram(dist.km_hav)
min(dist.km_hav)
max(dist.km_hav)
