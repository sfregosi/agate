function pp = extractPilotingParams(CONFIG, path_bsLocal, path_status, preload)

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% to calculate battery usage during the GoMex 2017 deployment
% updated 07/06/17
% S. Fregosi 2020 02 08 to work with PMAR
% Updated 2020 03 04 to work with second PMAR SD card
% updated 2022 04 05 for Hawaii deployment and eventually for AGATE public
% release

% Inputs:
% CONFIG       deployment parameters - glider serial, deployment string, pmcard
% path_bsLocal  location of locally saved basetation files
% path_status   output directory to save status plots and tables
% preload       optional argument to preload an existing table. default is
%               TRUE(1) to preload to save time. change to FALSE (0) to
%               overwrite from scratch (used in development)

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
if preload && exist(fullfile(path_status, ['diveTracking_' CONFIG.glider '.mat']), 'file')
    % if it already exists...preload it to save time.
    pptmp = load(fullfile(path_status, ['diveTracking_' CONFIG.glider '.mat']));
    fieldNames = fields(pptmp);
    pp = pptmp.(fieldNames{1}); %pp(148:150,:) = [];
    % which dives need to be newly processed?
    loopNums = [max(pp.diveNum)+1:numDives];
    % any need to be reprocessed?
    loopNums = [loopNums find(isnat(pp.diveStartTime))'];
    pp.diveNum(loopNums) = diveList(loopNums);
elseif ~preload || ~exist(fullfile(path_status, ['diveTracking_' CONFIG.glider '.mat']), 'file')
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
    else
        continue % move on to next loopNum dive and leave this row empty
    end
    
    
    %% times and location data
    
    % start and end time
    idxST = strfind(x,'$GPS2');
    % pp.diveStart(d,1) = datenum(x([idxST+6:idxST+18]),'ddmmyy,HHMMSS');
    pp.diveStartTime(d,1) = datetime(x([idxST+6:idxST+18]),'InputFormat','ddMMyy,HHmmss');
    idxET = strfind(x,'$GPS,');
    pp.diveEndTime(d,1) = datetime(x([idxET+5:idxET+17]),'InputFormat','ddMMyy,HHmmss');
    
    % actual start and end locations
    latgps = ncread(ncFileName,'log_gps_lat');
    longps = ncread(ncFileName,'log_gps_lon');
    timegps = ncread(ncFileName,'log_gps_time');
    pp.startGPS{d} = [latgps(2) longps(2)];
    pp.endGPS{d} = [latgps(3) longps(3)];

    % target location
    idx = strfind(x, '$TGT_LATLONG');
    idxComma = regexp(x(idx:end), '\,');
    idxPeriod = regexp(x(idx:end), '\.');
    idxBreak = regexp(x(idx:end),'\n','once') + idx;
    
    tgtLat = str2num(x(idx+idxComma(1):idx+idxPeriod(1)-4)) + ...
        str2num(x(idx+idxPeriod(1)-3:idx+idxComma(2)-2))/60;
    tgtLon = str2num(x(idx+idxComma(2):idx+idxPeriod(2)-4)) - ...
        str2num(x(idx+idxPeriod(2)-3:idxBreak-2))/60; % western hemisphere specific.
    
    pp.tgtLoc{d} = [tgtLat tgtLon];

    %% dive flight parameter settings
    % target dive duration, depth, max slope and buoy
    flightList = {'$T_DIVE', '$D_TGT', '$GLIDE_SLOPE', '$MAX_BUOY'};
    for c = 1:length(flightList)
        idx = strfind(x, flightList{c});
        sl = length(flightList{c});
        idxBreak = regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
        cVal = str2num(x(idx+sl+1:idxBreak-1));
        pp.(flightList{c}(2:end))(d) = cVal;
    end 
    
    %% actual depth, duration, distance traveled summaries
    % actual duration
    pp.diveDur_min(d,1) = round(minutes(pp.diveEndTime(d,1) - pp.diveStartTime(d,1)));
    % actual depth
    depth = ncread(ncFileName, 'eng_depth');
    pp.maxDepth_m(d,1) = round(max(depth)/100);
    % actual distance over ground
    [~, pp.dog_km(d)] = lldistkm(pp.startGPS{d}, pp.endGPS{d});
    % distance to next target
    [~, pp.distTGT_km(d)] = lldistkm(pp.endGPS{d}, [tgtLat tgtLon]);
    
    
    %% glider calculated target speed, pitch, and glide angle
    
    %     pp.Wd(d,1) = 2*dTgt*100/(tDive*60);
    % these are calculated based on $T_DIVE, $D_TGT, distance to next
    % target, %GLIDE_ANGLE, %MAX_BUOY
    idx = strfind(x, '$MHEAD_RNG_PITCHd_Wd');
    idxComma = regexp(x(idx:end), '\,');
    idxBreak = regexp(x(idx:end),'\n','once') + idx;
    pp.desVertVel(d) = str2num(x(idxComma(4)+idx:idxComma(5)+idx-2));
    pp.desPitch(d) = str2num(x(idxComma(3)+idx:idxComma(4)+idx-2));
    if CONFIG.sgVer == 66.12
        pp.desGlideAngle(d) = str2num(x(idxComma(5)+idx:idxComma(6)+idx-2));
        pp.dBdW(d) = str2num(x(idxComma(6)+idx:idxBreak-2));
        % could probably comment this out I don't actually know what it
        % means
    elseif CONFIG.sgVer == 67.00
        pp.desGlideAngle(d) = str2num(x(idxComma(5)+idx:idxBreak-2));
        %         pp.dBdW(d) = nan; %str2num(x(idxComma(6)+idx:idxBreak-2));
    end
    
    %% pitch and speed actual values
    
    vert_speed_gsm = ncread(ncFileName, 'vert_speed_gsm');
    pp.vertSpeedDive(d) = mean(vert_speed_gsm(vert_speed_gsm < 0));
    pp.vertSpeedClimb(d) = mean(vert_speed_gsm(vert_speed_gsm > 0));
    
    eng_pitchAng = ncread(ncFileName, 'eng_pitchAng');
    pp.pitchDive(d) = mean(eng_pitchAng(eng_pitchAng < 0));
    pp.pitchClimb(d) = mean(eng_pitchAng(eng_pitchAng > 0));
    
    pp.stwDive(d) = abs(pp.vertSpeedDive(d))/sind(abs(pp.pitchDive(d)));
    pp.stwClimb(d) = abs(pp.vertSpeedClimb(d))/sind(abs(pp.pitchClimb(d)));
    
    %% center parameters
    centersList = {'$C_VBD', '$C_PITCH', '$PITCH_GAIN', ...
        '$C_ROLL_DIVE', '$C_ROLL_CLIMB'};
    for c = 1:length(centersList)
        idx = strfind(x, centersList{c});
        sl = length(centersList{c});
        idxBreak = regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
        cVal = str2num(x(idx+sl+1:idxBreak-1));
        pp.(centersList{c}(2:end))(d) = cVal;
    end
    
    %% pressure and humidity
    safetyList = {'$HUMID', '$INTERNAL_PRESSURE'};
    for c = 1:length(safetyList)
        idx = strfind(x, safetyList{c});
        sl = length(safetyList{c});
        idxBreak = regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
        cVal = str2num(x(idx+sl+1:idxBreak-1));
        pp.(safetyList{c}(2:end))(d) = cVal;
    end
    
    %% pmar outputs
    % operating duration
    idx = strfind(x, '$SENSOR_SECS');
    idxComma = regexp(x(idx:end), '\,');
    sVal = str2num(x(idx+idxComma(7):idx+idxComma(8)-2));
    pp.PMAR_SEC(d) = sVal;
    pp.PMAR_MIN(d) = sVal/60;
    
    % power draw
    idx = strfind(x, '$SENSOR_MAMPS');
    idxComma = regexp(x(idx:end), '\,');
    sVal = str2num(x(idx+idxComma(7):idx+idxComma(8)-2));
    pp.PMAR_MAMPS(d) = sVal;
    
    % kJ used ***EXPERIMENTAL***
    pp.PMAR_kJ(d) = pp.PMAR_SEC(d)*pp.PMAR_MAMPS(d)*15/1000000;
    
    % find the current card
    if CONFIG.sgVer == 66.12 % active card is listed in log file
        idx = strfind(x, '$PM_ACTIVECARD');
        sl = length('$PM_ACTIVECARD');
        idxBreak = regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
        activeCard = str2num(x(idx+sl+1:idxBreak-1));
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
    pamFolders = dir(fullfile(path_bsLocal, ['pm' num2str(d,'%04.f') '*']));
    
    for pf = 1:length(pamFolders)
        xp = fileread(fullfile(path_bsLocal, pamFolders(pf).name, 'pm_ch00.eng'));
        idx = regexp(xp, '%datafiles: ');
        sl = length('%datafiles: ');
        idxBreak = regexp(xp(idx+sl:end), '\n', 'once') + idx + sl;
        if strcmp(pamFolders(pf).name(end), 'a')
            if ~isempty(idx)
                pp.numFilesDive(d) = str2num(xp(idx+sl:idxBreak-2));
            else
                pp.numFilesDive(d) = nan;
            end
        elseif strcmp(pamFolders(pf).name(end), 'b')
            if ~isempty(idx)
                pp.numFilesClimb(d) = str2num(xp(idx+sl:idxBreak-2));
            else
                pp.numFilesClimb(d) = nan;
            end
        end
    end
    pp.numFiles(d) = pp.numFilesDive(d) + pp.numFilesClimb(d);
    
    % space used in that dive
    % first set up this column (Want it to come before by-card space
    if d == 1
        pp.pmUsed_GB(d,1) = NaN;
    end
    
    % free space per card
    for sdc = 1:CONFIG.pm.numCards
        cardNumStr = sprintf('0%d', sdc-1);
        idx = strfind(x, ['$PM_FREEKB_' cardNumStr]);
        sl = length(['$PM_FREEKB_' cardNumStr]);
        idxBreak = regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
        cVal = str2num(x(idx+sl+1:idxBreak-1));
        if ~isempty(cVal)
%             pp.(['PM_FREEKB_' cardNumStr])(d) = cVal;
        pp.(['pmFree_' cardNumStr '_GB'])(d) = cVal/1000000;
        else
%             pp.(['PM_FREEKB_' cardNumStr])(d) = NaN;
        pp.(['pmFree_' cardNumStr '_GB'])(d) = NaN;
        end
%         pp.(['PM_FREEGB_' cardNumStr])(d) = pp.(['PM_FREEKB_' cardNumStr])(d)/1000000;
    end
    
    % space used on this dive (if not Dive 1)
    if d > 1
        pp.pmUsed_GB(d,1) = (pp.(['pmFree_' activeCardStr '_GB'])(d-1) - ...
            pp.(['pmFree_' activeCardStr '_GB'])(d));
    end
    
    %% battery usage
    % voltages
    idx = strfind(x, '$24V_AH');
    sl = length('$24V_AH');
    idxComma = regexp(x(idx:end), '\,');
    idxBreak = regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
    sVal = str2num(x(idx+idxComma(2):idxBreak-1));
    pp.ampHrConsumed(d) = sVal;
    
    sVal = str2num(x(idx+idxComma(1):idx+idxComma(2)-2));
    pp.minVolt_24(d) = sVal;
    idx = strfind(x, '$10V_AH');
    idxComma = regexp(x(idx:end), '\,');
    sVal = str2num(x(idx+idxComma(1):idx+idxComma(2)-2));
    pp.minVolt_10(d) = sVal;
    
    % By Devices *****EXPERIMENTAL******
    if CONFIG.sgVer == 66.12
        % order of devices = pitch, roll, VBD apogee, VBD surf, VBD valve
        idx = strfind(x, '$DEVICE_SECS');
        idxComma = regexp(x(idx:end), '\,');
        pSec    = str2num(x(idx+idxComma(1):idx+idxComma(2)-2));
        rSec    = str2num(x(idx+idxComma(2):idx+idxComma(3)-2));
        vSec1   = str2num(x(idx+idxComma(3):idx+idxComma(4)-2));
        vSec2   = str2num(x(idx+idxComma(4):idx+idxComma(5)-2));
        vSec3   = str2num(x(idx+idxComma(5):idx+idxComma(6)-2));
        
        idx = strfind(x, '$DEVICE_MAMPS');
        idxComma = regexp(x(idx:end), '\,');
        pMamps    = str2num(x(idx+idxComma(1):idx+idxComma(2)-2));
        rMamps    = str2num(x(idx+idxComma(2):idx+idxComma(3)-2));
        vMamps1   = str2num(x(idx+idxComma(3):idx+idxComma(4)-2));
        vMamps2   = str2num(x(idx+idxComma(4):idx+idxComma(5)-2));
        vMamps3   = str2num(x(idx+idxComma(5):idx+idxComma(6)-2));
        
        pp.pkJ(d,1) = pSec*pMamps*15/1000000;
        pp.rkJ(d,1) = rSec*rMamps*15/1000000;
        vkJ1 = vSec1*vMamps1*15/1000000;
        vkJ2 = vSec2*vMamps2*15/1000000;
        vkJ3 = vSec3*vMamps3*15/1000000;
        pp.vkJ(d,1) = vkJ1 + vkJ2 + vkJ3;
        
    elseif CONFIG.sgVer == 67.00
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
    pp.dac_east_cm_s(d) = ncread(ncFileName,'depth_avg_curr_east')*100;
    pp.dac_north_cm_s(d) = ncread(ncFileName,'depth_avg_curr_north')*100;
    
    
    %% any errors?
    idx = strfind(x, '$ERRORS');
    sl = length('$ERRORS');
    idxBreak = regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
    cVal = x(idx+sl+1:idxBreak-1);
    pp.ERRORS{d} = cVal;
    
end

end