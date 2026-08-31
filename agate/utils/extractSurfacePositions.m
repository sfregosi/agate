unixfunction gpsSurfT = extractSurfacePositions(CONFIG, plotOn)
% EXTRACTSURFACEPOSITIONS	Extract glider surface GPS locations from nc files
%
%   Syntax:
%       GPSSURFT = EXTRACTSURFACEPOSITIONS(CONFIG, PLOTON)
%
%   Description:
%       Extracts glider positional data from basestation-generated .nc
%	    files and compiles a table of surface GPS locations at dive-level
%	    resolution. It also includes dive duration, distance over ground
%	    (straight line distance between the start and end locations),
%	    maximum depth, depth average current and flight average speed
%	    information for both the hydrodynamic and glide slope model (gsm)
%	    as well as a quality flag for the hydrodynamic model. 
%
%       Note, this process was originally part of the
%       EXTRACTPOSITIONALDATA function but was extracted to allow for
%       greater flexibility in processing steps. 
%
%   Inputs:
%       CONFIG    agate mission configuration file with relevant mission and
%                 glider information. Minimum CONFIG fields are 'glider',
%                 'mission', 'path.mission'
%       plotOn    optional argument to plot basic maps of outputs for
%                 checking; (1) to plot, (0) to not plot
%
%   Outputs:
%       gpsSurfT  Table with glider surface locations, from GPS, one per
%                 dive, and includes columns for dive start and end
%                 time/lat/lon, dive duration, depth average current,
%                 average speed over ground as northing and easting,
%                 calculated by the hydrodynamic model and the glide slope
%                 model
%
%   Examples:
%
%   See also EXTRACTCALCULATEDPOSITIONS
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   30 August 2026
%
%   Created with MATLAB ver.: 24.2.0.3212159 (R2024b) Update 9
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Surface locations - extracted from individual nc files
files = dir(fullfile(CONFIG.path.mission, 'basestationFiles\p*.nc'));
lf = length(files);

% use number of files (number of dives) to preallocate
% sometimes odd abort behaviors mess this up, but NaNs will fill in
surfNames = {'dive', 'startTime', 'startDateTime', 'startLatitude', ...
	'startLongitude', 'endTime', 'endDateTime', 'endLatitude', 'endLongitude', ...
	'duration_hr', 'distance_km', 'maxDepth_m', 'dac_n', 'dac_e', ...
	'dac_n_gsm', 'dac_e_gsm', 'dac_qc', 'avg_speed_n', 'avg_speed_e', ...
	'avg_speed_n_gsm', 'avg_speed_e_gsm', 'hdm_qc'};

gpsSurfT = array2table(NaN(lf, length(surfNames)));
gpsSurfT.Properties.VariableNames = surfNames;
gpsSurfT.startDateTime = datetime(gpsSurfT.startDateTime, 'ConvertFrom', 'datenum');
gpsSurfT.endDateTime = datetime(gpsSurfT.endDateTime, 'ConvertFrom', 'datenum');

% loop through each file/dive
for f = 1:length(files)
	fname = fullfile(CONFIG.path.mission, 'basestationFiles', files(f,1).name);
	[~, fname_name, fname_ext] = fileparts(fname);
	% ncdisp(fname,'/','min');
	try
		latgps = ncread(fname,'log_gps_lat');
		longps = ncread(fname,'log_gps_lon');
		timegps = ncread(fname,'log_gps_time');

		gpsSurfT.dive(f)			= f;
		gpsSurfT.startTime(f)		= unix2datenum(timegps(2));
		gpsSurfT.startDateTime(f)	= datetime(gpsSurfT.startTime(f), ...
										'ConvertFrom','datenum');
		gpsSurfT.startLatitude(f)	= latgps(2);
		gpsSurfT.startLongitude(f)	= longps(2);
		gpsSurfT.endTime(f)			= unix2matlab(timegps(3));
		gpsSurfT.endDateTime(f)		= datetime(gpsSurfT.endTime(f), ...
										'ConvertFrom','datenum');
		gpsSurfT.endLatitude(f)		= latgps(3);
		gpsSurfT.endLongitude(f)	= longps(3);
		gpsSurfT.duration_hr(f)		= hours(gpsSurfT.endDateTime(f) - ...
										gpsSurfT.startDateTime(f));
		gpsSurfT.distance_km(f)		= lldistkm([latgps(2) longps(2)], ...
										[latgps(3) longps(3)]);
		gpsSurfT.maxDepth_m(f)		= max(ncread(fname, 'depth'));
		gpsSurfT.dac_n(f)			= ncread(fname,'depth_avg_curr_north');
		gpsSurfT.dac_e(f)			= ncread(fname,'depth_avg_curr_east');
		gpsSurfT.dac_qc(f)			= str2double(ncread(fname,'depth_avg_curr_qc'));
		gpsSurfT.dac_n_gsm(f)		= ncread(fname,'depth_avg_curr_north_gsm');
		gpsSurfT.dac_e_gsm(f)		= ncread(fname,'depth_avg_curr_east_gsm');
		gpsSurfT.avg_speed_n(f)		= ncread(fname,'flight_avg_speed_north');
		gpsSurfT.avg_speed_e(f)		= ncread(fname,'flight_avg_speed_east');
		gpsSurfT.avg_speed_n_gsm(f)	= ncread(fname,'flight_avg_speed_north_gsm');
		gpsSurfT.avg_speed_e_gsm(f)	= ncread(fname,'flight_avg_speed_east_gsm');
		gpsSurfT.hdm_qc(f)			= str2double(ncread(fname,'hdm_qc'));
	catch
		fprintf(1, 'Problem loading %s. Skipped.\n', [fname_name fname_ext])
	end
end

% optional check by plotting
if plotOn
	figure
	plot(gpsSurfT.startLongitude,gpsSurfT.startLatitude,'.k');
	text(gpsSurfT.startLongitude+0.002,gpsSurfT.startLatitude+0.002, ...
		num2str(gpsSurfT.dive));
end

end