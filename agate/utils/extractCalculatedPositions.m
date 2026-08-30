function locCalcT = extractCalculatedPositions(CONFIG, plotOn, debugOnError)
% EXTRACTCALCULATEDPOSITIONS	Extract glider dead-reckoned locations
%
%   Syntax:
%       LOCCALCT = EXTRACTCALCULATEDPOSITIONS(CONFIG, PLOTON)
%       LOCCALCT = EXTRACTCALCULATEDPOSITIONS(CONFIG, PLOTON, DEBUGONERROR)
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
%       NOTE (2026-08-30): Engineering variables (pitch, heading, roll)
%       were removed from this function -- they are extracted separately
%       (see EXTRACTENGINEERINGDATA) since they live on the sg_data_point
%       clock and should not be resampled onto the CTD clock. Every
%       variable remaining in this function is consistently backed by a
%       single dimension per glider vintage: sg_data_point for
%       Kistler-pressure-sensor gliders, ctd_data_point for RBR
%       Legato-CTD gliders (time/depth read from ctd_time/ctd_depth in
%       that case). No interpolation is required.
%
%   Inputs:
%       CONFIG    agate mission configuration file with relevant mission and
%                 glider information. Minimum CONFIG fields are 'glider',
%                 'mission', 'path.mission'
%       plotOn    optional argument to plot basic maps of outputs for
%                 checking; (1) to plot, (0) to not plot
%       debugOnError  optional argument (logical, default false) -- pauses
%                     at a keyboard prompt when a file fails to load, for
%                     inspecting the error interactively rather than just
%                     logging and skipping. Not mission-specific, so it's
%                     a call-time argument rather than a CONFIG field.
%
%	Outputs:
%       locCalcT  Table with glider calculated locations underwater every
%                 CTD/science sampling interval. This gives more
%                 instantaneous flight details and includes columns
%                 for time, lat, lon from hydrodynamic and glide slope
%                 models, displacement from both models, temperature,
%                 salinity, density, sound speed, glider vertical and
%                 horizontal speed (from both models), and glide angle
%
%   Examples:
%
%   See also EXTRACTSURFACEPOSITIONS, EXTRACTENGINEERINGDATA
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   30 August 2026
%
%   Created with MATLAB ver.: 24.2.0.3212159 (R2024b) Update 9
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3
	debugOnError = false;
end

% extracted from individual nc files
files = dir(fullfile(CONFIG.path.mission, 'basestationFiles\p*.nc'));

% set up output table
calcNames = {'dive', 'time', 'dateTime', 'latitude', 'longitude', ...
	'latitude_gsm', 'longitude_gsm', 'north_displacement', 'east_displacement', ...
	'north_displacement_gsm', 'east_displacement_gsm', 'depth', 'temperature', ...
	'salinity', 'soundVelocity', 'density', 'vertSpeed', 'horzSpeed', 'speed', ...
	'speed_qc', 'vertSpeed_gsm', 'horzSpeed_gsm', 'speed_gsm', ...
	'glideAngle', 'glideAngle_gsm'};  %#ok<NASGU> % kept here as the schema reference

% collect one table per file, then vertcat once at the end -- avoids the
% pre-allocation guesswork and spaceCheck bookkeeping from before
locCalcTAll = cell(length(files), 1);

% loop through all files
for f = 1:length(files)
		fname = fullfile(CONFIG.path.mission, 'basestationFiles', files(f,1).name);
		[~, fname_name, fname_ext] = fileparts(fname);
	try
        % determine which dimension this file's CTD/position data uses --
		% RBR Legato-equipped gliders carry a ctd_data_point dimension;
		% older Kistler-sensor gliders only have sg_data_point
		finfo = ncinfo(fname);
		dimNames = {finfo.Dimensions.Name};
		hasCTD = any(strcmp(dimNames, 'ctd_data_point'));

        % choose proper dimension based on CTD type
        if hasCTD
            dimMatch = strcmp(dimNames, 'ctd_data_point');
            timeVar = 'ctd_time';
            depthVar = 'ctd_depth';
        else
            dimMatch = strcmp(dimNames, 'sg_data_point');
            timeVar = 'time';
            depthVar = 'depth';
        end
        samples = finfo.Dimensions(dimMatch).Length;

        % build table for this dive/file
        fileT = table();
		fileT.dive                    = repmat(f, samples, 1);
		fileT.time                    = unix2matlab(ncread(fname, timeVar));
		fileT.dateTime                = datetime(fileT.time, 'ConvertFrom', 'datenum');
		fileT.latitude                = ncread(fname, 'latitude');
		fileT.longitude               = ncread(fname, 'longitude');
		fileT.latitude_gsm            = ncread(fname, 'latitude_gsm');
		fileT.longitude_gsm           = ncread(fname, 'longitude_gsm');
		fileT.north_displacement      = ncread(fname, 'north_displacement');
		fileT.east_displacement       = ncread(fname, 'east_displacement');
		fileT.north_displacement_gsm  = ncread(fname, 'north_displacement_gsm');
		fileT.east_displacement_gsm   = ncread(fname, 'east_displacement_gsm');
		fileT.depth                   = ncread(fname, depthVar);
		fileT.temperature             = ncread(fname, 'temperature');
		fileT.salinity                = ncread(fname, 'salinity');
		fileT.soundVelocity           = ncread(fname, 'sound_velocity');
		fileT.density                 = ncread(fname, 'density');
		fileT.vertSpeed               = ncread(fname, 'vert_speed');
		fileT.horzSpeed               = ncread(fname, 'horz_speed');
		fileT.speed                   = ncread(fname, 'speed');
		fileT.speed_qc                = ncread(fname, 'speed_qc');
		fileT.vertSpeed_gsm           = ncread(fname, 'vert_speed_gsm');
		fileT.horzSpeed_gsm           = ncread(fname, 'horz_speed_gsm');
		fileT.speed_gsm               = ncread(fname, 'speed_gsm');
		fileT.glideAngle              = ncread(fname, 'glide_angle');
		fileT.glideAngle_gsm          = ncread(fname, 'glide_angle_gsm');

        % add cell
        locCalcTAll{f} = fileT;

	catch ME
		fprintf(1, 'Problem loading %s: %s\n', [fname_name fname_ext], ME.message);
		if debugOnError 
			keyboard
		end
	end
end

% combine all files (skip any empty entries from files that errored above)
locCalcT = vertcat(locCalcTAll{~cellfun(@isempty, locCalcTAll)});

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

