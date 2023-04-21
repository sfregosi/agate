function [gpsSurfT, locCalcT] = extractPositionalData(CONFIG, plotOn)
% EXTRACTPOSITIONALDATA	Extracts glider location data from nc files
%
%	Syntax:
%		[gpsSurfT, locCalcT] = EXTRACTPOSITIONALDATA(CONFIG, SAVEON)
%
%	Description:
%		Extracts glider positional data from basestation-generated .nc
%		files and compiles into two tables, one with just GPS/surface
%		locations and one with dead-reckoned locations underwater. Also
%		includes various metrics related to speed and currents
%
%	Inputs:
%		CONFIG  agate mission configuration file with relevant mission and
%		        glider information. Minimum CONFIG fields are 'glider',
%		        'mission', 'path.mission'
%       plotOn  optional argument to plot basic maps of outputs for
%               checking; (1) to plot, (0) to not plot
%
%	Outputs:
%		gpsSurfT    Table with glider surface locations, from GPS, one per
%		            dive, and includes columns for dive start and end
%		            time/lat/lon, dive duration, depth average current,
%                   average speed over ground as northing and easting,
%                   calculated by the hydrodynamic model or the glide slope
%                   model
%       locCalcT    Table with glider calculated locations underwater every
%                   science file sampling interval. This gives more
%                   instantaneous flight details and includes columns
%                   for time, lat, lon from hydrodynamic and glide slope
%                   models, displacement from both models, temperature,
%                   salinity, density, sound speed, glider vertical and
%                   horizontal speed (from both models), pitch, glide
%                   angle, and heading
%
%	Examples:
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	03 September 2019
%	Updated:        21 April 2023
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Surface locations - extracted from individual nc files
files = dir(fullfile(CONFIG.path.mission, 'basestationFiles\p*.nc'));

for f = 1:length(files)
    fname = fullfile(CONFIG.path.mission, 'basestationFiles', files(f,1).name);
    % ncdisp(fname,'/','min');
    try
        latgps=ncread(fname,'log_gps_lat');
        longps=ncread(fname,'log_gps_lon');
        timegps=ncread(fname,'log_gps_time');

        dive(f,1) = f;
        startTime(f,1) = unix2matlab(timegps(2));
        startDateTime(f,1) = datetime(startTime(f,1),'ConvertFrom','datenum');
        startLatitude(f,1) = latgps(2);
        startLongitude(f,1) = longps(2);
        endTime(f,1) = unix2matlab(timegps(3));
        endDateTime(f,1) = datetime(endTime(f,1),'ConvertFrom','datenum');
        endLatitude(f,1) = latgps(3);
        endLongitude(f,1) = longps(3);
        duration_hrs(f,1) = hours(endDateTime(f,1)-startDateTime(f,1));
        dac_n(f,1) = ncread(fname,'depth_avg_curr_north');
        dac_e(f,1) = ncread(fname,'depth_avg_curr_east');
        dac_qc(f,1) = ncread(fname,'depth_avg_curr_qc');
        dac_n_gsm(f,1) = ncread(fname,'depth_avg_curr_north_gsm');
        dac_e_gsm(f,1) = ncread(fname,'depth_avg_curr_east_gsm');
        avg_speed_n(f,1) = ncread(fname,'flight_avg_speed_north');
        avg_speed_e(f,1) = ncread(fname,'flight_avg_speed_east');
        avg_speed_n_gsm(f,1) = ncread(fname,'flight_avg_speed_north_gsm');
        avg_speed_e_gsm(f,1) = ncread(fname,'flight_avg_speed_east_gsm');
        hdm_qc(f,1) = ncread(fname,'hdm_qc');
    catch
    end
end

gpsSurfT = table(dive, startTime, startDateTime, startLongitude, ...
    startLatitude, endTime, endDateTime, endLatitude, endLongitude, ...
    duration_hrs, dac_n, dac_e, dac_n_gsm, dac_e_gsm, dac_qc, avg_speed_n, ...
    avg_speed_e, avg_speed_n_gsm, avg_speed_e_gsm, hdm_qc);

% optional check by plotting
if plotOn
    figure
    plot(gpsSurfT.startLongitude,gpsSurfT.startLatitude,'.k');
    text(gpsSurfT.startLongitude+0.002,gpsSurfT.startLatitude+0.002,num2str(gpsSurfT.dive));
end

% Sample locations - extracted from individual nc files
files = dir(fullfile(CONFIG.path.mission, 'basestationFiles\p*.nc'));

% set up output variables
dive = []; time = [];
latitude = []; longitude = []; latitude_gsm = []; longitude_gsm = [];
north_displacement = []; east_displacement = [];
north_displacement_gsm = []; east_displacement_gsm = [];
depth = []; temperature = []; salinity = []; soundVelocity = []; density = [];
vertSpeed = []; horzSpeed = []; speed = []; speed_qc = [];
vertSpeed_gsm = []; horzSpeed_gsm = []; speed_gsm = [];
pitch = []; glideAngle = []; glideAngle_gsm = []; heading = [];

for f = 1:length(files)
    try
        fname = fullfile(CONFIG.path.mission, 'basestationFiles', files(f,1).name);
        %how many data points
        finfo = ncinfo(fname);
        dimMatch = strcmp({finfo.Dimensions.Name}, 'sg_data_point');
        samples = finfo.Dimensions(dimMatch).Length;
        dive = [dive; repmat(f, samples, 1)];
        time = [time; unix2matlab(ncread(fname, 'time'))];
        latitude = [latitude; ncread(fname, 'latitude')];
        longitude = [longitude; ncread(fname, 'longitude')];
        latitude_gsm = [latitude_gsm; ncread(fname, 'latitude_gsm')];
        longitude_gsm = [longitude_gsm; ncread(fname, 'longitude_gsm')];
        north_displacement = [north_displacement; ncread(fname, 'north_displacement')];
        east_displacement = [east_displacement; ncread(fname, 'east_displacement')];
        north_displacement_gsm = [north_displacement_gsm; ncread(fname, 'north_displacement_gsm')];
        east_displacement_gsm = [east_displacement_gsm; ncread(fname, 'east_displacement_gsm')];
        depth = [depth; ncread(fname, 'depth')];
        temperature = [temperature; ncread(fname, 'temperature')];
        salinity = [salinity; ncread(fname, 'salinity')];
        soundVelocity = [soundVelocity; ncread(fname, 'sound_velocity')];
        density = [density; ncread(fname, 'density')];
        vertSpeed = [vertSpeed; ncread(fname, 'vert_speed')];
        horzSpeed = [horzSpeed; ncread(fname, 'horz_speed')];
        speed = [speed; ncread(fname, 'speed')];
        speed_qc = [speed_qc; ncread(fname, 'speed_qc')];
        vertSpeed_gsm = [vertSpeed_gsm; ncread(fname, 'vert_speed_gsm')];
        horzSpeed_gsm = [horzSpeed_gsm; ncread(fname, 'horz_speed_gsm')];
        speed_gsm = [speed_gsm; ncread(fname, 'speed_gsm')];
        pitch = [pitch; ncread(fname, 'eng_pitchAng')];
        glideAngle = [glideAngle; ncread(fname, 'glide_angle')];
        glideAngle_gsm = [glideAngle_gsm; ncread(fname, 'glide_angle_gsm')];
        heading = [heading; ncread(fname, 'eng_head')];
    catch
    end
end

dateTime = datetime(time, 'ConvertFrom', 'datenum');
locCalcT = table(dive, time, dateTime, latitude, longitude, latitude_gsm, ...
    longitude_gsm,north_displacement,east_displacement, north_displacement_gsm, ...
    east_displacement_gsm, depth, temperature, salinity, soundVelocity, ...
    density, vertSpeed, horzSpeed, speed, speed_qc, vertSpeed_gsm, ...
    horzSpeed_gsm, speed_gsm, pitch, glideAngle, glideAngle_gsm, heading);

% check by plotting
if plotOn
    % dive profile
    figure;
    plot(locCalcT.time,-locCalcT.depth)
    title('dive profile');
    % compare hydro vs glide slope models
    figure;
    plot(locCalcT.longitude, locCalcT.latitude)
    hold on
    plot(locCalcT.longitude_gsm, locCalcT.latitude_gsm)
end

end

