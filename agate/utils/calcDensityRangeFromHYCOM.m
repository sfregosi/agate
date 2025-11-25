function [rho_min, rho_max, dt] = calcDensityRangeFromHYCOM(CONFIG, HYCOMFileName, plotOn)
%CALCDENSITYRANGEFROMHYCOM Calculate min and max density from HYCOM data
%
%   Syntax:
%       [rho_min, rho_max, dt] = CALCDENSITYRANGEFROMHYCOM(CONFIG, HYCOMFileName, plotOn)
%       [rho_min, rho_max, dt] = CALCDENSITYRANGEFROMHYCOM(HYCOMFileName, plotOn)
%       [rho_min, rho_max, dt] = CALCDENSITYRANGEFROMHYCOM(HYCOMFileName)

%   Description:
%       Calculate minimum and maximum seawater density (at atmospheric
%       pressure, as is used for glider ballasting) from an input .nc data
%       file downloaded from HYCOM:
%       https://ncss.hycom.org/thredds/ncss/grid/GLBy0.08/expt_93.0/ts3z/dataset.html
%       
%       Recommend just downloading a single day at a time for a reasonable
%       file size, then process several days over the planned mission
%       duration to get a range
%
%   Inputs:
%       dataFileName   fullfile filename to downloaded .nc file. If no
%		                file is specified, will prompt to select one
%
%   Outputs:
%       rho_min        minimum density across all lat/lons and depths of
%		               the input data file
%       rho_max        maximum density across all lat/lons and depths of
%                      the input data file
%       dt             table of mean salinity, mean temperature, mean,
%                      min, and max density at the surface and at the
%                      deepest depth extracted (closest to, but greater 
%                       than 1000 m) 
%
%   Examples:
%       [rho_min, rho_max, dt] = calcDensityRangeFromHYCOM('C:\MHI_2022-04-01.nc')
%   See also
%
%
%   Authors:
%	   S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion: 	24 April 2023
%   Updated:
%
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% global CONFIG

    % Handle input arguments
    if nargin < 1
        CONFIG = [];
        HYCOMFileName = '';
        plotOn = 0;
    elseif nargin < 2
        if isstruct(CONFIG)
            % case: calcDensityRangeFromHYCOM(CONFIG)
            HYCOMFileName = '';
            plotOn = 0;
        else
            % case: calcDensityRangeFromHYCOM(HYCOMFileName)
            HYCOMFileName = CONFIG;
            CONFIG = [];
            plotOn = 0;
        end
    elseif nargin < 3
        if isstruct(CONFIG)
            % case: calcDensityRangeFromHYCOM(CONFIG, HYCOMFileName)
            plotOn = 0;
        else
            % case: calcDensityRangeFromHYCOM(HYCOMFileName, plotOn)
            plotOn = HYCOMFileName;
            HYCOMFileName = CONFIG;
            CONFIG = [];
        end
    end

    % If no file specified, prompt user
    if isempty(HYCOMFileName)
        if ~isempty(CONFIG) && isfield(CONFIG, 'path') && isfield(CONFIG.path, 'mission')
            startPath = CONFIG.path.mission;
        else
            startPath = pwd;
        end
        [fileName, filePath] = uigetfile(fullfile(startPath, '*.nc;*.nc4'), ...
            'Select .nc file downloaded from HYCOM');
        HYCOMFileName = fullfile(filePath, fileName);
    end

% if nargin < 3
%     plotOn = 0;
% end
% 
% if nargin < 2 % no file specified
%     [fileName, filePath] = uigetfile([CONFIG.path.mission, '*.nc;*.nc4'], ...
%         'Select .nc file downloaded from HYCOM');
%     HYCOMFileName = fullfile(filePath, fileName);
% end

% for exploring datafile
% info = ncinfo(HYCOMFileName);

% Read in relevant variables
lat = ncread(HYCOMFileName, 'lat');
lon = ncread(HYCOMFileName, 'lon');

% typically depth data goes beyond 1000 m, trim to 1000 m only
depth = ncread(HYCOMFileName, 'depth');
deepIdx = find(depth > 1000, 1, 'first');
depth = depth(1:deepIdx);

salinity = ncread(HYCOMFileName, 'salinity');
salinity = salinity(:, :, 1:deepIdx); % trim >1000 m
water_temp = ncread(HYCOMFileName, 'water_temp');
water_temp = water_temp(:, :, 1:deepIdx); % trim >1000 m

% get data output sizes
nRows = size(water_temp, 1);
nCols = size(water_temp, 2);
nMats = size(water_temp, 3);

% pull surface layer data (should be least dense)
% salinity
salinity_surf = salinity(:, :, 1);
fprintf(1, 'Surface salinity [psu]: mean %0.2f, min %0.2f, max %0.2f\n', ...
    mean(salinity_surf, 'all', 'omitnan'), ...
    min(salinity_surf, [], 'all', 'omitnan'), ...
    max(salinity_surf, [], 'all', 'omitnan'));

% temperature
water_temp_surf = water_temp(:,:,1);
fprintf(1, 'Surface temperature [°C]: mean %0.2f, min %0.2f, max %0.2f\n', ...
    mean(water_temp_surf, 'all', 'omitnan'), ...
    min(water_temp_surf, [], 'all', 'omitnan'), ...
    max(water_temp_surf, [], 'all', 'omitnan'));

% density
[rho_surf, ~] = seawater_density(salinity_surf, water_temp_surf, ...
    zeros(nRows, nCols));
fprintf(1, 'Surface density [km/m^3]: mean %0.2f, min %0.2f, max %0.2f\n', ...
    mean(rho_surf, 'all', 'omitnan'), ...
    min(rho_surf, [], 'all', 'omitnan'), ...
    max(rho_surf, [], 'all', 'omitnan'));

% pull deep water stuff (should be most dense)
% salinity
salinity_deep = salinity(:, :, end);
fprintf(1, 'Deep water salinity [psu]: mean %0.2f, min %0.2f, max %0.2f\n', ...
    mean(salinity_deep, 'all', 'omitnan'), ...
    min(salinity_deep, [], 'all', 'omitnan'), ...
    max(salinity_deep, [], 'all', 'omitnan'));

% temperature
water_temp_deep = water_temp(:, :, end);
fprintf(1, 'Deep water temperature [°C]: mean %0.2f, min %0.2f, max %0.2f\n', ...
    mean(water_temp_deep, 'all', 'omitnan'), ...
    min(water_temp_deep, [], 'all', 'omitnan'), ...
    max(water_temp_deep, [], 'all', 'omitnan'));

% density
% glider uses sigma-t which does NOT incorporate depth/pressure data, so
% use pressure value of 1
[rho_deep, ~] = seawater_density(salinity_deep, water_temp_deep, ...
    zeros(nRows, nCols));
fprintf(1, 'Deep water density [km/m^3]: mean %0.2f, min %0.2f, max %0.2f\n', ...
    mean(rho_deep, 'all', 'omitnan'), ...
    min(rho_deep, [], 'all', 'omitnan'), ...
    max(rho_deep, [], 'all', 'omitnan'));

% compile into table
dt = table;
dt.depth = [0, depth(end)]';
dt.salinity_mean = [mean(salinity_surf, 'all', 'omitnan'), ...
    mean(salinity_deep, 'all', 'omitnan')]';
dt.temperature_mean = [mean(water_temp_surf, 'all', 'omitnan'), ...
    mean(water_temp_deep, 'all', 'omitnan')]';
dt.density_mean = [mean(rho_surf, 'all', 'omitnan'), ...
    mean(rho_deep, 'all', 'omitnan')]';
dt.density_min = [min(rho_surf, [], 'all', 'omitnan'), ...
    min(rho_deep, [], 'all', 'omitnan')]';
dt.density_max = [max(rho_surf, [], 'all', 'omitnan'), ...
    max(rho_deep, [], 'all', 'omitnan')]';

rho_min = min(dt.density_min);
rho_max = max(dt.density_max);

% optional plots
if plotOn == 1

    % surface data spatial surface plot
    figure;
    surf(lat, lon, salinity_surf)
    figure;
    surf(lat, lon, water_temp_surf)
    figure;
    surf(lat, lon, rho_surf)

    % deep water data spatial surface plot
    figure;
    surf(lat, lon, salinity_deep)
    figure;
    surf(lat, lon, water_temp_deep)
    figure;
    surf(lat, lon, rho_deep)

    % plot pycnocline
    [rho, ~] = seawater_density(salinity,water_temp,p);
    % raw data - this is slow
    figure; hold on;
    for f = 1:size(rho, 1)
        for g = 1:size(rho, 2)
            tmp = reshape(rho(f, g, :), 1, nMats);
            plot(tmp, -depth, '-', 'Color', [0.5 0.5 0.5 0.3])
        end
    end
    % median at each depth bin
    medRho = median(rho, [1, 2], 'omitnan');
    medRho = reshape(medRho, 1, nMats);
    plot(medRho, -depth, 'k-', 'LineWidth', 2)
    hold off;
    % label median min and max
    text(min(medRho), -850, sprintf('min median: %.2f', min(medRho)));
    text(min(medRho), -925, sprintf('max median: %.2f', max(medRho)));
    % clean up
    grid on;
    ylim([-1050 0]);
    ylabel('depth [m]');
    xlabel('density [kg/m^3]')
    title('pycnocline')


    % plot halocline
    % raw data - this is slow
    figure; hold on;
    for f = 1:size(salinity, 1)
        for g = 1:size(salinity, 2)
            tmp = reshape(salinity(f, g, :), 1, nMats);
            plot(tmp, -depth, '-', 'Color', [0.5 0.5 0.5 0.3])
        end
    end
    % median at each depth bin
    medSalinity = median(salinity, [1, 2], 'omitnan');
    medSalinity = reshape(medSalinity, 1, nMats);
    plot(medSalinity, -depth, 'k-', 'LineWidth', 2)
    hold off;
    % label median min and max
    mid = min(medSalinity) + (max(medSalinity) - min(medSalinity))/2;
    text(mid, -850, sprintf('min median: %.2f', min(medSalinity)));
    text(mid, -925, sprintf('max median: %.2f', max(medSalinity)));
    % clean up
    grid on;
    ylim([-1050 0]);
    ylabel('depth [m]');
    xlabel('salinity [PSU]')
    title('halocline')

    % plot thermocline
    % raw data - this is slow
    figure; hold on;
    for f = 1:size(water_temp, 1)
        for g = 1:size(water_temp, 2)
            tmp = reshape(water_temp(f, g, :), 1, nMats);
            plot(tmp, -depth, '-', 'Color', [0.5 0.5 0.5 0.3])
        end
    end
    % median at each depth bin
    medTemp = median(water_temp, [1, 2], 'omitnan');
    medTemp = reshape(medTemp, 1, nMats);
    plot(medTemp, -depth, 'k-', 'LineWidth', 2)
    hold off;
    % label median min and max
    mid = min(medTemp) + (max(medTemp) - min(medTemp))/2;
    text(mid, -850, sprintf('min median: %.2f', min(medTemp)));
    text(mid, -925, sprintf('max median: %.2f', max(medTemp)));
    % clean up
    grid on;
    ylim([-1050 0]);
    ylabel('depth [m]');
    xlabel('temperature [°C]')
    title('thermocline')
end % optional plotting

end
