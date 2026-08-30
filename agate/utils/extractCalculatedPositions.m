function locCalcT = extractCalculatedPositions(CONFIG, plotOn)
% EXTRACTCALCULATEDPOSITIONS	Extract glider dead-reckoned locations
%
%   Syntax:
%       LOCCALCT = EXTRACTCALCULATEDPOSITIONS(CONFIG, PLOTON)
%
%   Description:
%	    Extracts glider positional data from basestation-generated .nc
%	    files and compiles into a table of calculated, dead-reckoned
%	    locations underwater with measured depth and environmental
%	    variables including temperature, salinity, desnity, sound speed,
%	    displacement and speeds, from both the hydrodynamic model and
%	    glide-slope model (gsm) 
%
%       Note, this process was originally part of the
%       EXTRACTPOSITIONALDATA function but was extracted to allow for
%       greater flexibility in processing steps. 
%
%       NOTE!!!! New gliders with RBR Legato CTDs produce CTD data and
%       enginneering data at two different sets of times (sg_data_point and
%       ctd_data_point dimensions in the nc file). The current function
%       (2026-08-30) uses the sg_data_point dimension and interpolates
%       (the ctd_data_points down to that smaller time series). This was
%       done just to make this workable ahead of a deadline. This is an
%       issue flagged in agate and needs to be addressed after discussing
%       best approaches with the seaglider community. It is also tied to
%       the potential issues with the Kistler pressure sensor jumping. 
%
%   Inputs:
%       CONFIG    agate mission configuration file with relevant mission and
%                 glider information. Minimum CONFIG fields are 'glider',
%                 'mission', 'path.mission'
%       plotOn    optional argument to plot basic maps of outputs for
%                 checking; (1) to plot, (0) to not plot
%
%	Outputs:
%       locCalcT  Table with glider calculated locations underwater every
%                 science file sampling interval. This gives more
%                 instantaneous flight details and includes columns
%                 for time, lat, lon from hydrodynamic and glide slope
%                 models, displacement from both models, temperature,
%                 salinity, density, sound speed, glider vertical and
%                 horizontal speed (from both models), pitch, glide
%                 angle, and heading
%
%   Examples:
%
%   See also EXTRACTSURFACEPOSITIONS
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   30 August 2026
%
%   Created with MATLAB ver.: 24.2.0.3212159 (R2024b) Update 9
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% extracted from individual nc files
files = dir(fullfile(CONFIG.path.mission, 'basestationFiles\p*.nc'));
lf = length(files);

% guesstimate size for preallocation
% 6 hr dives with 10 sec sampling interval (6 samples per min) == 2160 samples per dive
initSize = 2160*lf;

% set up output table
calcNames = {'dive', 'time', 'dateTime', 'latitude', 'longitude', ...
	'latitude_gsm', 'longitude_gsm', 'north_displacement', 'east_displacement', ...
	'north_displacement_gsm', 'east_displacement_gsm', 'depth', 'temperature', ...
	'salinity', 'soundVelocity', 'density', 'vertSpeed', 'horzSpeed', 'speed', ...
	'speed_qc', 'vertSpeed_gsm', 'horzSpeed_gsm', 'speed_gsm', 'pitch', ...
	'glideAngle', 'glideAngle_gsm', 'heading'};

locCalcT = array2table(NaN(initSize, length(calcNames)));
locCalcT.Properties.VariableNames = calcNames;
locCalcT.dateTime = datetime(locCalcT.dateTime, 'ConvertFrom', 'datenum');

% loop through all files
lastIdx = 0;
spaceCheck = false;
for f = 1:length(files)
			fname = fullfile(CONFIG.path.mission, 'basestationFiles', files(f,1).name);
		[~, fname_name, fname_ext] = fileparts(fname);
	try
		%how many data points
		finfo = ncinfo(fname);
		dimMatch = strcmp({finfo.Dimensions.Name}, 'sg_data_point');
		samples = finfo.Dimensions(dimMatch).Length;
		sampIdx = lastIdx + 1:lastIdx + samples;
		% check for sufficient space - if not enough, pre-allocate more
		if sampIdx(end) > height(locCalcT) && spaceCheck == false
			fprintf(1, 'FYI More rows were needed!!\n')
			spaceCheck = true; % only print that once...
		end

		% assign values
		locCalcT.dive(sampIdx)					= repmat(f, samples, 1);
		locCalcT.time(sampIdx)					= unix2matlab(ncread(fname, 'time'));
		locCalcT.latitude(sampIdx)				= ncread(fname, 'latitude');
		locCalcT.longitude(sampIdx)				= ncread(fname, 'longitude');
		locCalcT.latitude_gsm(sampIdx)			= ncread(fname, 'latitude_gsm');
		locCalcT.longitude_gsm(sampIdx)			= ncread(fname, 'longitude_gsm');
		locCalcT.north_displacement(sampIdx)	= ncread(fname, 'north_displacement');
		locCalcT.east_displacement(sampIdx)		= ncread(fname, 'east_displacement');
		locCalcT.north_displacement_gsm(sampIdx) = ncread(fname, 'north_displacement_gsm');
		locCalcT.east_displacement_gsm(sampIdx)	= ncread(fname, 'east_displacement_gsm');
		locCalcT.depth(sampIdx)					= ncread(fname, 'depth');
		locCalcT.temperature(sampIdx)			= ncread(fname, 'temperature');
		locCalcT.salinity(sampIdx)				= ncread(fname, 'salinity');
		locCalcT.soundVelocity(sampIdx)			= ncread(fname, 'sound_velocity');
		locCalcT.density(sampIdx)				= ncread(fname, 'density');
		locCalcT.vertSpeed(sampIdx)				= ncread(fname, 'vert_speed');
		locCalcT.horzSpeed(sampIdx)				= ncread(fname, 'horz_speed');
		locCalcT.speed(sampIdx)					= ncread(fname, 'speed');
		locCalcT.speed_qc(sampIdx)				= ncread(fname, 'speed_qc');
		locCalcT.vertSpeed_gsm(sampIdx)			= ncread(fname, 'vert_speed_gsm');
		locCalcT.horzSpeed_gsm(sampIdx)			= ncread(fname, 'horz_speed_gsm');
		locCalcT.speed_gsm(sampIdx)				= ncread(fname, 'speed_gsm');
		locCalcT.pitch(sampIdx)					= ncread(fname, 'eng_pitchAng');
		locCalcT.glideAngle(sampIdx)			= ncread(fname, 'glide_angle');
		locCalcT.glideAngle_gsm(sampIdx)		= ncread(fname, 'glide_angle_gsm');
		locCalcT.heading(sampIdx)				= ncread(fname, 'eng_head');

		% move incrementally
		lastIdx = lastIdx + samples;
	catch
		fprintf(1, 'Problem loading %s. Skipped.\n', [fname_name fname_ext])
	end
end

% get dateTime from datenum
locCalcT.dateTime = datetime(locCalcT.time, 'ConvertFrom', 'datenum');
% remove extra NaNs from preallocation
locCalcT = locCalcT(1:lastIdx,:);

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

