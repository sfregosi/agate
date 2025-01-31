function pp = extractPilotingParams(CONFIG, path_bsLocal, path_status, preload)
%EXTRACTPILOTINGPARAMS Compile various piloting-relevant values from log and nc files
%
%   Syntax:
%       pp = EXTRACTPILOTINGPARAMS(CONFIG, path_bsLocal, path_status, preload)
%
%   Description:
%       Multi-part function that loops through all dive files (either from
%       the start of mission if preload = 0, or for just new dives) and
%       extracts various piloting-related parameters including times,
%       locations, durations, input centers and target dive values, pam
%       outputs, battery usage, and safety/error checks. The purpose of
%       the table is to enable a pilot to look at what parameters were
%       changed, and how those changes manifested in the gliders flight,
%       from dive to dive.
%
%       **NOTE** WISPR processing/plotting is not currently working
%       (2024-09-06) following updates to WISPR software?
%
%   Inputs:
%       CONFIG         [struct] mission/agate configuration variable.
%                      Required fields: CONFIG.glider, CONFIG.sgVer,
%                      CONFIG.pm section (if running PMAR) or CONFIG.ws (if
%                      running WISPR - NOT WORKING)
%       path_bsLocal   [char] path to local basestation files. Can be
%                      defined in CONFIG file (as CONFIG.path.bs) or as
%                      input argument. Suggested path is:
%                      fullfile(CONFIG.path.mission, 'basestationFiles')
%       path_status    [char] path to 'flightStatus' output folder.
%                      Suggested path is:
%                      fullfile(CONFIG.path.mission, 'flightStatus').
%                      This is used to load a previously made table to
%                      speed up processing by only running new dives
%       preload        [double] optional argument to preload an existing
%                      table. Default is 1 to preload to save time (will
%                      only process new dives. Change to 0 to overwrite
%                      and create table from scratch (used in development).
%
%   Outputs:
%       pp             [table] piloting parameters table
%
%   Examples:
%       pp = extractPilotingParams(CONFIG, path_bsLocal, path_status, 0);
%
%   See also
%
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   06 July 2017
%   Updated:        10 September 2024
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 4
	preload = true;
end

%% Get file lists and dive numbers

% log files - also get the dive numbers they are available for.
logFileList = dir(fullfile(path_bsLocal, ['p' CONFIG.glider(3:end) '*.log']));
logFileNames = {logFileList.name}';
logFileNums = zeros(length(logFileNames),1);
for f = 1:length(logFileNames)
	logFileNums(f) = str2double(logFileNames{f}(5:8)); %p6390000.log
end

% ncfiles - also get the dive numbers they are available for.
ncFileList = dir(fullfile(path_bsLocal, ['p' CONFIG.glider(3:end) '*.nc']));
ncFileNames = {ncFileList.name}';
ncFileNums = zeros(length(ncFileNames),1);
for f = 1:length(ncFileNames)
	ncFileNums(f) = str2double(ncFileNames{f}(5:8)); %p6390000.log
end
% ncCompFile = dir([base_path 'sg' glider(3:end) '*.nc']);

% pamFolders = dir([path_bsLocal 'pm*']);
% pdos_files = dir([path_bsLocal 'p' CONFIG.glider(3:end) '*.pdos']);

% check that length .nc files matches length logs/numDives
% may not if conversion/processing problems with one of the binaries
% numDives = length(logFileList)-1; % minus the pre-launch test log files
numDives = max([logFileNums; ncFileNums]); % get max of list of dive nums
diveList = [1:numDives]';

% set up output table

% try to preload an existing table to save processing time
if preload
	preloadFile = fullfile(path_status, ['diveTracking_' CONFIG.glider '.mat']);
	% if file doesn't exist, prompt to choose one
	if ~exist(preloadFile, 'file')
		[fn, path] = uigetfile(fullfile(path_status, '*.mat*'), ...
			'Select piloting params table');
		if fn == 0 && path == 0
			fprintf(1, '.mat selection canceled, skipping preload.\n')
			preload = 0;
		else
			preloadFile = fullfile(path, fn);
		end
	end
end

if preload
	pptmp = load(preloadFile);
	fieldNames = fields(pptmp);
	pp = pptmp.(fieldNames{1}); %pp(148:150,:) = [];
	% which dives need to be newly processed?
	loopNums = [max(pp.diveNum)+1:numDives];
	% any need to be reprocessed?
	loopNums = [loopNums find(isnat(pp.diveStartTime))'];
	pp.diveNum(loopNums) = diveList(loopNums);
elseif ~preload % if not, start fresh
	pp = table;
	pp.diveNum = [1:numDives]';
	loopNums = [1:numDives];
end

%% loop through the dives that need to be updated
for d = loopNums

	% get the files for this loop
	if any(logFileNums == d) && any(ncFileNums == d) % do these files exist?
		x = fileread(fullfile(path_bsLocal, logFileNames{logFileNums == d}));
		ncFileName = fullfile(path_bsLocal, ncFileNames{ncFileNums == d});
	elseif any(logFileNums == d) % at least log file exists
		x = fileread(fullfile(path_bsLocal, logFileNames{logFileNums == d}));
		ncFileName = [];
	else
		continue % move on to next loopNum dive and leave this row empty
	end


	%% times and location data

	% start and end time
	idxST = strfind(x,'$GPS2');
	pp.diveStartTime(d,1) = datetime(x(idxST+6:idxST+18), 'InputFormat', ...
		'ddMMyy,HHmmss');
	idxET = strfind(x,'$GPS,');
	pp.diveEndTime(d,1) = datetime(x(idxET+5:idxET+17), 'InputFormat', ...
		'ddMMyy,HHmmss');

	% start lat/lon
	idxBreak = regexp(x(idxST:end),'\n','once') + idxST;
	idxComma = regexp(x(idxST:idxBreak), '\,');
	sLatDM = x(idxST + idxComma(3):idxST + idxComma(4) - 2);
	idxPer = regexp(sLatDM, '\.', 'once');
	sLatDD = degmin2decdeg([str2double(sLatDM(1:idxPer-3)), ...
		str2double(sLatDM(idxPer-2:end))]);
	sLonDM = x(idxST + idxComma(4):idxST + idxComma(5) - 2);
	idxPer = regexp(x(idxST + idxComma(4):idxBreak), '\.', 'once');
	sLonDD = degmin2decdeg([str2double(sLonDM(1:idxPer-3)), ...
		str2double(sLonDM(idxPer-2:end))]);
	pp.startGPS{d} = [sLatDD sLonDD];

	% end lat/lon
	idxComma = regexp(x(idxET:end), '\,');
	eLatDM = x(idxET + idxComma(3):idxET + idxComma(4) - 2);
	idxPer = regexp(eLatDM, '\.', 'once');
	eLatDD = degmin2decdeg([str2double(eLatDM(1:idxPer-3)), ...
		str2double(eLatDM(idxPer-2:end))]);
	eLonDM = x(idxET + idxComma(4):idxET + idxComma(5) - 2);
	idxPer = regexp(x(idxET + idxComma(4):end), '\.', 'once');
	eLonDD = degmin2decdeg([str2double(eLonDM(1:idxPer-3)), ...
		str2double(eLonDM(idxPer-2:end))]);
	pp.endGPS{d} = [eLatDD eLonDD];

	% actual start and end locations
	% can also get info from nc file but nc files don't always exist
	if ~isempty(ncFileName)
		latgps = ncread(ncFileName,'log_gps_lat');
		longps = ncread(ncFileName,'log_gps_lon');
		%     timegps = ncread(ncFileName,'log_gps_time');
		pp.startGPS{d} = [latgps(2) longps(2)];
		pp.endGPS{d} = [latgps(3) longps(3)];
	end

	% target name
	pp.tgtName{d} = parseLogToBreak(x, '$TGT_NAME') ;
	if strcmp(pp.tgtName(d), 'HEADING')
		val = parseLogToBreak(x, '$HEADING');
		pp.tgtName{d} = [pp.tgtName{d} ',' val];
	end

	% target location
	idx = strfind(x, '$TGT_LATLONG');
	idxComma = regexp(x(idx:end), '\,');
	idxPer = regexp(x(idx:end), '\.');
	idxBreak = regexp(x(idx:end),'\n','once') + idx;

	tgtLat = str2double(x(idx+idxComma(1):idx+idxPer(1)-4)) + ...
		str2double(x(idx+idxPer(1)-3:idx+idxComma(2)-2))/60;
	tgtLon = str2double(x(idx+idxComma(2):idx+idxPer(2)-4)) - ...
		str2double(x(idx+idxPer(2)-3:idxBreak-2))/60; % western hemisphere specific.

	pp.tgtLoc{d} = [tgtLat tgtLon];
	% put placeholder here and calculate below
	pp.distTGT_km(d) = nan;

	%% actual depth, duration, distance traveled summaries
	% actual duration
	pp.diveDur_min(d,1) = round(minutes(pp.diveEndTime(d,1) - ...
		pp.diveStartTime(d,1)));
	% actual depth
	if ~isempty(ncFileName)
		depth = ncread(ncFileName, 'eng_depth');
	else
		depth = 0;
	end
	pp.maxDepth_m(d,1) = round(max(depth)/100);
	% actual distance over ground
	[~, pp.dog_km(d)] = lldistkm(pp.startGPS{d}, pp.endGPS{d});
	% distance to next target
	[~, pp.distTGT_km(d)] = lldistkm(pp.endGPS{d}, [tgtLat tgtLon]);

	%% dive flight parameter settings
	% target dive duration, depth, max slope and buoy
	flightList = {'$T_DIVE', '$D_TGT', '$GLIDE_SLOPE', '$MAX_BUOY'};
	for c = 1:length(flightList)
		pp.(flightList{c}(2:end))(d) = str2double(parseLogToBreak(x, ...
			flightList{c}));
	end

	%% glider calculated target speed, pitch, and glide angle

	% pp.Wd(d,1) = 2*dTgt*100/(tDive*60);
	% these are calculated based on $T_DIVE, $D_TGT, distance to next
	% target, %GLIDE_ANGLE, %MAX_BUOY
	idx = strfind(x, '$MHEAD_RNG_PITCHd_Wd');
	idxComma = regexp(x(idx:end), '\,');
	idxBreak = regexp(x(idx:end),'\n','once') + idx;
	pp.desVertVel(d) = str2double(x(idxComma(4)+idx:idxComma(5)+idx-2));
	pp.desPitch(d) = str2double(x(idxComma(3)+idx:idxComma(4)+idx-2));
	if CONFIG.sgVer == 66.12
		pp.desGlideAngle(d) = str2double(x(idxComma(5)+idx:idxComma(6)+idx-2));
		pp.dBdW(d) = str2double(x(idxComma(6)+idx:idxBreak-2));
		% could probably comment this out I don't actually know what it
		% means
	elseif CONFIG.sgVer == 67.00
		pp.desGlideAngle(d) = str2double(x(idxComma(5)+idx:idxBreak-2));
		%         pp.dBdW(d) = nan; %str2num(x(idxComma(6)+idx:idxBreak-2));
	end

	%% pitch and speed actual values
	if ~isempty(ncFileName)
		vert_speed_gsm = ncread(ncFileName, 'vert_speed_gsm');
		pp.vertSpeedDive(d) = mean(vert_speed_gsm(vert_speed_gsm < 0));
		pp.vertSpeedClimb(d) = mean(vert_speed_gsm(vert_speed_gsm > 0));

		eng_pitchAng = ncread(ncFileName, 'eng_pitchAng');
		pp.pitchDive(d) = mean(eng_pitchAng(eng_pitchAng < 0));
		pp.pitchClimb(d) = mean(eng_pitchAng(eng_pitchAng > 0));

		pp.stwDive(d) = abs(pp.vertSpeedDive(d))/sind(abs(pp.pitchDive(d)));
		pp.stwClimb(d) = abs(pp.vertSpeedClimb(d))/sind(abs(pp.pitchClimb(d)));
	end

	%% center parameters
	centersList = {'$C_VBD', '$C_PITCH', '$PITCH_GAIN', ...
		'$C_ROLL_DIVE', '$C_ROLL_CLIMB'};
	for c = 1:length(centersList)
		pp.(centersList{c}(2:end))(d) = str2double(parseLogToBreak(x, ...
			centersList{c}));
	end

	%% pressure and humidity
	safetyList = {'$HUMID', '$INTERNAL_PRESSURE'};
	for c = 1:length(safetyList)
		pp.(safetyList{c}(2:end))(d) = str2double(parseLogToBreak(x, ...
			safetyList{c}));
	end

	%% pmar outputs
	if isfield(CONFIG, 'pm') && CONFIG.pm.loggers == 1 % pam system is active
		% operating duration
		idx = strfind(x, '$SENSOR_SECS');
		idxComma = regexp(x(idx:end), '\,');
		sVal = str2double(x(idx+idxComma(7):idx+idxComma(8)-2));
		pp.PMAR_SEC(d) = sVal;
		pp.PMAR_MIN(d) = sVal/60;

		% power draw
		idx = strfind(x, '$SENSOR_MAMPS');
		idxComma = regexp(x(idx:end), '\,');
		sVal = str2double(x(idx+idxComma(7):idx+idxComma(8)-2));
		pp.PMAR_MAMPS(d) = sVal;

		% kJ used ***EXPERIMENTAL***
		pp.PMAR_kJ(d) = calckJ(pp.PMAR_SEC(d), pp.PMAR_MAMPS(d), 15);

		% find the current card
		if CONFIG.sgVer == 66.12 % active card is listed in log file
			activeCard = str2double(parseLogToBreak(x, '$PM_ACTIVECARD'));
			activeCardStr = sprintf('0%d', activeCard);
			pp.activeCard(d) = activeCard;
		elseif CONFIG.sgVer == 67.00
			% for sgVer 67.00 does it not print the active card - must specify
			% in CONFIG
			if isfield(CONFIG.pm,'activeCard')
				% which active card for this dive?
				acIdx = find(d >= CONFIG.pm.activeCard(:,1), 1, 'last');
				pp.activeCard(d) = CONFIG.pm.activeCard(acIdx,2);
				activeCardStr = sprintf('0%d', CONFIG.pm.activeCard(acIdx,2));
			else
				fprintf(1, 'Need to specify CONFIG.pm.activeCard. Exiting.\n')
				return
			end
		end

		% number of files recorded per dive
		paFolders = dir(fullfile(path_bsLocal, ['pm' num2str(d,'%04.f') '*']));

		for pf = 1:length(paFolders)
			xp = fileread(fullfile(path_bsLocal, paFolders(pf).name, ...
				'pm_ch00.eng'));
			val = str2double(parseLogToBreak(xp, '%datafiles:'));
			if strcmp(paFolders(pf).name(end), 'a')
				pp.numFilesDive(d) = val;
			elseif strcmp(paFolders(pf).name(end), 'b')
				pp.numFilesClimb(d) = val;
			end
		end
		pp.numFiles(d) = sum([pp.numFilesDive(d) pp.numFilesClimb(d)], ...
			'omitnan');

		% space used in that dive
		% first set up this column (Want it to come before by-card space
		if d == 1
			pp.pmUsed_GB(d,1) = NaN;
		end

		% free space per card
		for sdc = 1:CONFIG.pm.numCards
			cardNumStr = sprintf('0%d', sdc-1);
			val = str2double(parseLogToBreak(x,  ['$PM_FREEKB_' cardNumStr]));
			if ~isempty(val)
				pp.(['pmFree_' cardNumStr '_GB'])(d) = val/1000000;
			else
				pp.(['pmFree_' cardNumStr '_GB'])(d) = NaN;
			end
		end

		% space used on this dive (if not Dive 1)
		if d > 1
			pp.pmUsed_GB(d,1) = (pp.(['pmFree_' activeCardStr '_GB'])(d-1) - ...
				pp.(['pmFree_' activeCardStr '_GB'])(d));
		end
	end

	%% wispr outputs
	% 	if isfield(CONFIG, 'ws') && CONFIG.ws.loggers == 1 % wispr pam system is active
	%
	% 		% WISPR reported analysis and processing durations
	% 		% for now, only reading 'a' files from glider descent; 'b' files all blank
	% 		wsFiles = dir(fullfile(path_bsLocal, ['ws' num2str(d, '%04.f') 'az']));
	% 		bytes = [wsFiles.bytes];
	% 		wsFiles = wsFiles(bytes > 2,:);
	% 		for wf = 1:length(wsFiles)
	% 			ws = readws(fullfile(path_bsLocal, wsFiles(wf).name));
	% 		end
	% 		pp.wsAnDurDive_min(d) = ws.anDur_min;
	% 		pp.wsProcTimeDive_sec(d) = ws.procTime_sec;
	% 		pp.wsAnDurClimb_min(d) = NaN;
	% 		pp.wsProcTimeClimb_sec(d) = NaN;
	%
	% 		% seaglider reported operating duration
	% 		idx = strfind(x, '$SENSOR_SECS');
	% 		idxComma = regexp(x(idx:end), '\,');
	% 		sVal = round(str2double(x(idx+idxComma(8):idx+idxComma(9)-2)));
	% 		pp.WS_SEC(d) = sVal;
	% 		pp.WS_MIN(d) = sVal/60;
	%
	% 		% power draw
	% 		%         idx = strfind(x, '$SENSOR_MAMPS');
	% 		%         idxComma = regexp(x(idx:end), '\,');
	% 		%         sVal = str2double(x(idx+idxComma(8):idx+idxComma(9)-2));
	% 		%         pp.WS_MAMPS(d) = sVal;
	% 		WS_MAMPS = 33.3; % estimate 0.5 W @ 15 v = 33.3 mAmps
	%
	% 		% seaglider on board battery is not accounting for correct WISPR
	% 		% power draw and RPi/detector power draw
	%
	% 		% kJ used ***EXPERIMENTAL***
	% 		% get base kJ just used by WISPR
	% 		kJ_base = calckJ(pp.WS_SEC(d), WS_MAMPS, 15);
	% 		% then get kJ used by RPi...this is very rough estimate
	% 		RPi_MAMPS = 400; % estimate 6 W @ 15 V = 400 mAmps
	% 		RPi_SECS = pp.wsProcTimeDive_sec(d)*2 + 10; % from ws****az file,
	% 		% x2 because only dive reported,
	% 		% + 10 sec for start up
	% 		kJ_RPi = calckJ(RPi_SECS, RPi_MAMPS, 15);
	% 		pp.WS_kJ(d) = kJ_base + kJ_RPi;
	%
	% 		% calculate a WISPR ampHr to be added to the cumulative
	% 		% ampHrConsumed value output in the .log file below
	% 		Ah_base = calcAh(pp.WS_SEC(d), WS_MAMPS);
	% 		Ah_RPi = calcAh(RPi_SECS, RPi_MAMPS);
	%
	% 		% seaglider on board battery is not accounting for correct WISPR
	% 		% power draw and RPi/detector power draw
	% 		% calculate a WISPR ampHr to be added to the cumulative
	% 		% ampHrConsumed value output in the .log file below
	% 		pp.WS_ampHr(d) = Ah_base + Ah_RPi;
	% 		% could also calculate this from total kJ
	% 		%         pp.WS_ampHr(d) = pp.WS_kJ(d)/3.6/15;
	%
	% 	end


	%% battery usage
	% voltages
	idx = strfind(x, '$24V_AH');
	sl = length('$24V_AH');
	idxComma = regexp(x(idx:end), '\,');
	idxBreak = regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
	sVal = str2double(x(idx+idxComma(2):idxBreak-1));
	pp.ampHrConsumed(d) = sVal;

	% minimum voltages
	sVal = str2double(x(idx+idxComma(1):idx+idxComma(2)-2));
	pp.minVolt_24(d) = sVal;
	idx = strfind(x, '$10V_AH');
	idxComma = regexp(x(idx:end), '\,');
	sVal = str2double(x(idx+idxComma(1):idx+idxComma(2)-2));
	pp.minVolt_10(d) = sVal;

	% By Devices *****EXPERIMENTAL******
	if CONFIG.sgVer == 66.12 || CONFIG.sgVer == 66.14
		% order of devices = pitch, roll, VBD apogee, VBD surf, VBD valve
		idx = strfind(x, '$DEVICE_SECS');
		idxComma = regexp(x(idx:end), '\,');
		pSec    = str2double(x(idx+idxComma(1):idx+idxComma(2)-2));
		rSec    = str2double(x(idx+idxComma(2):idx+idxComma(3)-2));
		vSec1   = str2double(x(idx+idxComma(3):idx+idxComma(4)-2));
		vSec2   = str2double(x(idx+idxComma(4):idx+idxComma(5)-2));
		vSec3   = str2double(x(idx+idxComma(5):idx+idxComma(6)-2));

		idx = strfind(x, '$DEVICE_MAMPS');
		idxComma = regexp(x(idx:end), '\,');
		pMamps    = str2double(x(idx+idxComma(1):idx+idxComma(2)-2));
		rMamps    = str2double(x(idx+idxComma(2):idx+idxComma(3)-2));
		vMamps1   = str2double(x(idx+idxComma(3):idx+idxComma(4)-2));
		vMamps2   = str2double(x(idx+idxComma(4):idx+idxComma(5)-2));
		vMamps3   = str2double(x(idx+idxComma(5):idx+idxComma(6)-2));

		V = 15;
		pp.pkJ(d,1) = calckJ(pSec, pMamps, V);
		pp.rkJ(d,1) = calckJ(rSec, rMamps, V);
		vkJ1 = calckJ(vSec1, vMamps1, V);
		vkJ2 = calckJ(vSec2, vMamps2, V);
		vkJ3 = calckJ(vSec3, vMamps3, V);
		pp.vkJ(d,1) = vkJ1 + vkJ2 + vkJ3;

	elseif CONFIG.sgVer == 67.00 || CONFIG.sgVer == 67.01
		% order of devices = VBD, pitch, roll
		idx = strfind(x, '$DEVICE_SECS');
		idxComma = regexp(x(idx:end), '\,');
		vSec    = str2num(x(idx+idxComma(1):idx+idxComma(2)-2));
		pSec    = str2num(x(idx+idxComma(2):idx+idxComma(3)-2));
		rSec    = str2num(x(idx+idxComma(3):idx+idxComma(4)-2));

		idx = strfind(x, '$DEVICE_MAMPS');
		idxComma = regexp(x(idx:end), '\,');
		vMamps    = str2num(x(idx+idxComma(1):idx+idxComma(2)-2));
		pMamps    = str2num(x(idx+idxComma(2):idx+idxComma(3)-2));
		rMamps    = str2num(x(idx+idxComma(3):idx+idxComma(4)-2));

		pp.pkJ(d,1) = pSec*pMamps*15/1000000;
		pp.rkJ(d,1) = rSec*rMamps*15/1000000;
		pp.vkJ(d,1) = vSec*vMamps*15/1000000;
	end

	%% depth average currents
	if ~isempty(ncFileName)
		pp.dac_east_cm_s(d) = ncread(ncFileName,'depth_avg_curr_east')*100;
		pp.dac_north_cm_s(d) = ncread(ncFileName,'depth_avg_curr_north')*100;
	end

	%% any errors?
	pp.ERRORS{d} = parseLogToBreak(x, '$ERRORS');

end % dives

end


