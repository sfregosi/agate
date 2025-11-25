% https://ncss.hycom.org/thredds/ncss/grid/GLBv0.08/expt_93.0/dataset.html
% download it.

% file = "C:\Users\Selene.Fregosi\Documents\MATLAB\agate\draftCode\HI2022\GLBv0_expt_93.nc";
% file = "C:\Users\selene.fregosi\Documents\PICSN28_Documents\MATLAB\agate-public_copy_2024-07-02\agate\draft\HI2022\GLBv0_expt_93.nc";
file = "C:\Users\selene.fregosi\Downloads\cmems_mod_glo_phy-so_anfc_0.083deg_P1D-m_1751413148144.nc";
info = ncinfo(file);
% file = "C:\Users\selene.fregosi\Downloads\ts3z_2024.nc4";

% Successfully read these variables
depth = ncread(file, 'depth');
lat = ncread(file, 'latitude');
lon = ncread(file, 'longitude');
time = ncread(file, 'time');

salinity = ncread(file, 'so');
water_temp = ncread(file, 'water_temp');

% surface stuff
salinity_surf = salinity(:,:,1);
nanmean(salinity_surf,'all')
min(salinity_surf,[],'all','omitnan')
max(salinity_surf,[],'all','omitnan')
surf(lat,lon,salinity_surf)

water_temp_surf = water_temp(:,:,1);
nanmean(water_temp_surf,'all')
min(water_temp_surf,[],'all','omitnan')
max(water_temp_surf,[],'all','omitnan')
surf(lat,lon,water_temp_surf)

% surface mean density
S = nanmean(salinity_surf,'all');
T = nanmean(water_temp_surf,'all');
p = 1;
[rho,rhodif] = seawater_density(S,T,p)



% depth stuff - row 33 = 1000 m
salinity_depth = salinity(:,:,33);
nanmean(salinity_depth,'all')
min(salinity_depth,[],'all','omitnan')
max(salinity_depth,[],'all','omitnan')
surf(lat,lon,salinity_depth)

water_temp_depth = water_temp(:,:,33);
nanmean(water_temp_depth,'all')
min(water_temp_depth,[],'all','omitnan')
max(water_temp_depth,[],'all','omitnan')
surf(lat,lon,water_temp_depth)

% depth mean density
S = nanmean(salinity_depth,'all');
T = nanmean(water_temp_depth,'all');
% p = 100;
p = 1; % glider uses sigma-t which does NOT incorporate depth/pressure data
[rho,rhodif] = seawater_density(S,T,p)

% range = 1031.99-1023.4
% sigma-t range 1027.4 @ depth - 1023.4 @ surf


%% make pycnocline plot


% Successfully read these variables
depth = ncread(file, 'depth');
lat = ncread(file, 'lat');
lon = ncread(file, 'lon');
time = ncread(file, 'time');

salinity = ncread(file, 'salinity');
water_temp = ncread(file, 'water_temp');

S = nanmean(salinity_depth,'all');
T = nanmean(water_temp_depth,'all');
p = 0;
[rho,rhodif] = seawater_density(salinity,water_temp,p);

% raw data
figure(12); hold on;
for f = 1:size(rho,1)
    for g = 1:size(rho,2)
        tmp = reshape(rho(f,g,:),1,40);
        plot(tmp, -depth,':', 'Color', [0.5 0.5 0.5])
    end
end
ylim([-1050 0]);

% median at each depth bin
medRho = nanmedian(rho,[1,2]);
medRho = reshape(medRho,1,40);
plot(medRho, -depth, 'r-', 'LineWidth', 2)
hold off;

max(medRho)
min(medRho)

% raw data
figure(14); hold on;
for f = 1:size(water_temp,1)
    for g = 1:size(water_temp,2)
        tmp = reshape(water_temp(f,g,:),1,40);
        plot(tmp, -depth,':', 'Color', [0.5 0.5 0.5])
    end
end
ylim([-1050 0]);

% raw data
figure(16); hold on;
for f = 1:size(salinity,1)
    for g = 1:size(salinity,2)
        tmp = reshape(salinity(f,g,:),1,40);
        plot(tmp, -depth,':', 'Color', [0.5 0.5 0.5])
    end
end
ylim([-1050 0]);



%%
[rho,rhodif] = seawater_density(salinity,water_temp,p);