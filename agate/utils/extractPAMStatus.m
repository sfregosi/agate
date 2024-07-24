function [gpsSurfT, locCalcT, pamFiles, pamByDive] = extractPAMStatus(...
	CONFIG, gpsSurfT, locCalcT)
%EXTRACTPAMSTATUSBYFILE	Extracts PAM system on/off information from sound files
%
%   Syntax:
%	    [GPSSURFT, LOCCALCT, pamFiles] = EXTRACTPAMSTATUS(CONFIG, GPSSURFT, LOCCALCT)
%
%   Description:
%       Function to read info (audioinfo) and compile timing information
%       from all recorded acoustic files. User is prompted to select a
%       folder of .wav (or .flac?) files which will be opened one at a
%       time. Because this is slow, best to use the lowest frequency
%       dataset available (if it was downsampled) or from a local hard
%       drive rather than data on a server. The file start time is
%       extracted from the filename and the duration is pulled from the
%       file itself so stop time can be calculated. A list of all files and
%       timing info is output to the 'pamFiles' table.
%
%       'pamFiles' is then used to populate an additional 'pam' column in
%       locCalcT with a 0 (off) or 1 (on) for the pam system status at each
%       glider positional sample. Several columns are also added to
%       gpsSurfT with the pam duration and number of files for each dive. A
%       a separate 'pamByDive' summary table is also created with dive and
%       recording system timing info.
%
%   Inputs:
%       CONFIG     agate mission configuration file with relevant mission and
%                  glider information. Minimum CONFIG fields are 'glider',
%                  'mission', 'path.mission', logger field (either 'pm' or
%                  'ws') and logger sub fields 'fileLength', 'dateStart',
%                  'dateFormat'
%                  See exaxmple config file and config file help for more
%                  detail on each field:
%                  https://github.com/sfregosi/agate-public/blob/main/agate/settings/agate_config_example.cnf
%                  https://sfregosi.github.io/agate-public/configuration.html#mission-configuration-file
%       gpsSurfT   [table] glider surface locations exported from
%                  extractPositionalData
%       locCalcT   [table] glider fine scale locations exported from
%                  extractPositionalData
%
%   Outputs:
%       gpsSurfT   [table] glider surface locations, from GPS, one per
%                  dive. Input gpsSurfT is updated to now include a pam
%                  column with the minutes of PAM recording for that dive.
%                  Origingal columns include dive start and end
%                  time/lat/lon, dive duration, depth average current,
%                  average speed over ground as northing and easting,
%                  calculated by the hydrodynamic model or the glide slope
%                  model
%       locCalcT   [table] Glider calculated locations underwater every
%                  science file sampling interval. Input locCalcT is updated
%                  to include a pam column that has a 1 for pam system on or
%                  0 for pam system off for each location entry. Original
%                  instantaneous flight details and includes columns
%                  for time, lat, lon from hydrodynamic and glide slope
%                  models, displacement from both models, temperature,
%                  salinity, density, sound speed, glider vertical and
%                  horizontal speed (from both models), pitch, glide
%                  angle, and heading
%       pamFiles   [table] name, start and stop time and duration of all
%                  recorded sound files
%       pamByDive  [table] summary of recording start and stop, number of
%                  files for each dive. Includes dive start and stop times
%                  and offset of start and stop of pam relative to dive
%                  times
%
%   Examples:
%
%   See also EXTRACTPOSITIONALDATA
%
%   TO DO:
%      - build in option for FLAC
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%    FirstVersion:   ??
%    Updated:        11 July 2024
%
%    Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% initialization

% check acoustic system
if isfield(CONFIG, 'pm') && CONFIG.pm.loggers == 1
	loggerType = 'PMARXL';
elseif isfield(CONFIG, 'ws') && CONFIG.ws.loggers == 1
	loggerType = 'WISPR';
else
	fprintf(1, 'Unknown acoustic logger type. Exiting\n');
	return
end

% if specified in CONFIG, get file length (in seconds) and sample rate
switch loggerType
	case 'PMARXL'
		if isfield(CONFIG.pm, 'fileLength')
			fileLength = CONFIG.pm.fileLength;
			% 			sampleRate = CONFIG.pm.sampleRate;
		else
			fprintf(1, ['No file length specified in .cnf, using PMARXL ', ...
				'default fileLength = 600 s and sampleRate = 180260\n']);
			fileLength = 600;
			% 			sampleRate = 180260;
		end
		if isfield(CONFIG.pm, 'dateStart')
			dateStart = CONFIG.pm.dateStart;
		else
			fprintf(1, ['No dateStart specified in .cnf. Must specify ', ...
				'character where date string starts in file name.', ...
				'Exiting...'])
			return
		end
		if isfield(CONFIG.pm, 'dateFormat')
			dateFormat = CONFIG.pm.dateFormat;
		else
			fprintf(1, ['No dateFormat specified in .cnf. Must specify ', ...
				'format of date string in file name.', ...
				'Exiting...'])
			return
		end

	case 'WISPR'
		if isfield(CONFIG.ws, 'fileLength')
			fileLength = CONFIG.ws.fileLength;
		else
			fprintf(1, ['No file length specified in .cnf, using WISPR ', ...
				'default fileLength = 60 s and sampleRate = 180 kHz\n']);
			fileLength = 60;
		end
		if isfield(CONFIG.ws, 'dateStart')
			dateStart = CONFIG.ws.dateStart;
		else
			fprintf(1, ['No dateStart specified in .cnf. Must specify ', ...
				'character where date string starts in file name.', ...
				'Exiting...'])
			return
		end
		if isfield(CONFIG.ws, 'dateFormat')
			dateFormat = CONFIG.ws.dateFormat;
		else
			fprintf(1, ['No dateFormat specified in .cnf. Must specify ', ...
				'format of date string in file name.', ...
				'Exiting...'])
			return
		end
end

% specify deployment date and time to ignore all files before that
% (sometimes test files recorded in lab are in dataset)
deplDate = gpsSurfT.startDateTime(1);

% select folder with sound files and where to save
% path_in = uigetdir('G:\','Select base folder');
% pick 1 kHz data if available because it will run faster.
path_acous = uigetdir('C:\', ['Select folder with acoustic data. ' ...
	'Lower sample rate and local hard drive will run fastest.']);

%% Read in files and extract duration information
files = dir(fullfile(path_acous, '*.wav'));
if isempty(files)
	fprintf('No .wav files found...aborting\n');
	return
	% *****later build in switch to flac??
	% files=dir([path_flac '*.flac']);
end

pamFiles = table;
pamFiles.name = cell(length(files), 1);
pamFiles.start = NaT(length(files), 1, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
pamFiles.stop = NaT(length(files), 1, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

shortfiles = [];
fprintf(1,'%i files:\n', length(files));

% make matrix with start and end times for all PAM files
for f = 1:length(files)
	% calc file duration in sec using sampling rate..slow but works - more accurate
	try
		wavInfo = audioinfo(fullfile(path_acous, files(f,1).name));
		files(f,1).dur = wavInfo.TotalSamples./wavInfo.SampleRate;
		if files(f,1).dur < fileLength
			shortfiles = [shortfiles; f wavInfo.TotalSamples]; %#ok<AGROW>
			fprintf(1,'%s is short: %i samples, %.2f seconds\n', ...
				files(f,1).name, wavInfo.TotalSamples, files(f,1).dur);
		end
		% get start timing information from file name
		pamFiles.name{f} = files(f).name;
		dtIdx = dateStart:length(dateFormat) + dateStart - 1;
		pamFiles.start(f) = datetime(files(f).name(dtIdx), 'InputFormat', ...
			dateFormat);
		pamFiles.stop(f) = datetime(pamFiles.start(f,1) + ...
			seconds(files(f,1).dur), 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
		pamFiles.dur(f) = seconds(files(f,1).dur);

	catch % if there is some issue reading a file
		fprintf(1, '%s is corrupt\n', files(f,1).name);
	end
	if rem(f,1000)==0; fprintf(1,'%i DONE\n',f);end % counter
end

% remove all before deployment date
[r, ~] = find(pamFiles.start < deplDate, 1, 'last');
if ~isempty(r)
	pamFiles = pamFiles(r+1:end,:);
end

%% Specify 1's and 0s per locCalcT row
% 1 if pam on, 0 if off

locCalcT.pam = zeros(height(locCalcT),1);
fprintf(1,'%s - %d science samples:\n', [CONFIG.glider '_' CONFIG.mission], ...
	height(locCalcT));
fprintf(1, '\n%3d', floor((height(locCalcT))/8000));
for f = 1:height(locCalcT)
	idx = find(isbetween(locCalcT.dateTime(f), pamFiles.start, ...
		pamFiles.stop), 1);
	if ~isempty(idx)
		locCalcT.pam(f) = 1;
% 	else % for debugging
% 		fprintf(1, 'no idx match %s\n', locCalcT.dateTime(f));
	end
	clear idx

	% 	fprintf(1, '.');
	if rem(f, 100) == 0
		fprintf(1, '.');
	end
	if rem(f, 8000) == 0
		fprintf(1, '\n%3d', floor((height(locCalcT) - f)/8000));
	end
end
fprintf(1, '\n');

% % plotting test
%  plotDiveProfile(locCalcT)


%% duration per dive

pamByDive = table;
pamByDive.dive = gpsSurfT.dive;
pamByDive.diveStart = gpsSurfT.startDateTime;
pamByDive.diveStop = gpsSurfT.endDateTime;
pamByDive.numFiles = nan(height(pamByDive),1);

for f = 1:height(pamByDive)
	[r, ~] = find(isbetween(pamFiles.start, pamByDive.diveStart(f), ...
		pamByDive.diveStop(f)));
	if ~isempty(r)
		pamByDive.numFiles(f,1) = length(r);
		pamByDive.pamDur(f,1) = sum(pamFiles.dur(r));
		pamByDive.pamStart(f,1) = pamFiles.start(r(1));
		pamByDive.pamStop(f,1) = pamFiles.stop(r(end));
	end
end

% calc time between the dive start and the pam start, pam stop/dive stop
pamByDive.lagStart = pamByDive.pamStart - pamByDive.diveStart;
pamByDive.lagStop = pamByDive.diveStop - pamByDive.pamStop;

% append to gpsSurfT and save
gpsSurfT.pamDur = pamByDive.pamDur;
gpsSurfT.pamNumFiles = pamByDive.numFiles;
gpsSurfT.pamStart = pamByDive.pamStart;
gpsSurfT.pamStop = pamByDive.pamStop;




