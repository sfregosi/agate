function pp = extractPilotingParams(glider, pmCard, base_path)

% to calculate battery usage during the GoMex 2017 deployment
% updated 07/06/17
% S. Fregosi 2020 02 08 to work with PMAR
% Updated 2020 03 04 to work with second PMAR SD card

% base_path = [path_out '/basestationFiles/'];

log_files = dir([base_path 'p' glider(3:end) '*.log']);
numDives = length(log_files)-1; % minus the pre-launch test log files
ncFileList = dir([base_path 'p' glider(3:end) '*.nc']);
% ncCompFile = dir([base_path 'sg' glider(3:end) '*.nc']);
pamFolders = dir([base_path 'pm*']);
pdos_files = dir([base_path 'p' glider(3:end) '*.pdos']);

% set up output table
if exist([base_path 'diveTracking_' glider '.mat'], 'file')
    pptmp = load([base_path 'diveTracking_' glider '.mat']);
    fieldNames = fields(pptmp);
    pp = pptmp.(fieldNames{1}); %pp(148:150,:) = [];
    loopNums = [height(pp) + 1: numDives];
    pp.diveNum(1:numDives,1) = [1:numDives]';
else
    pp = table;
    pp.diveNum = [1:numDives]';
    loopNums = [1:numDives];
end

for d = loopNums
    
    f = d+1; % because first log file is dive 0/sealaunch
    x = fileread([base_path log_files(f).name]);
    ncFileName = [base_path ncFileList(d).name];
    
    %% times
    idxST = strfind(x,'$GPS2');
    % pp.diveStart(d,1) = datenum(x([idxST+6:idxST+18]),'ddmmyy,HHMMSS');
    pp.diveStartTime(d,1) = datetime(x([idxST+6:idxST+18]),'InputFormat','ddMMyy,HHmmss');
    idxET = strfind(x,'$GPS,');
    pp.diveEndTime(d,1) = datetime(x([idxET+5:idxET+17]),'InputFormat','ddMMyy,HHmmss');
    
    pp.diveDur(d,1) = round(minutes(pp.diveEndTime(d,1) - pp.diveStartTime(d,1)));
    
    %% locations
    latgps = ncread(ncFileName,'log_gps_lat');
    longps = ncread(ncFileName,'log_gps_lon');
    timegps = ncread(ncFileName,'log_gps_time');
    
    pp.startGPS{d} = [latgps(2) longps(2)];
    pp.endGPS{d} = [latgps(3) longps(3)];
    [~, pp.dog_km(d)] = lldistkm(pp.startGPS{d}, pp.endGPS{d});
    
    idx = strfind(x, '$TGT_LATLONG');
    idxComma = regexp(x(idx:end), '\,');
    idxPeriod = regexp(x(idx:end), '\.');
    idxBreak = regexp(x(idx:end),'\n','once') + idx;
    
    tgtLat = str2num(x(idx+idxComma(1):idx+idxPeriod(1)-4)) + ...
        str2num(x(idx+idxPeriod(1)-3:idx+idxComma(2)-2))/60;
    tgtLon = str2num(x(idx+idxComma(2):idx+idxPeriod(2)-4)) - ...
        str2num(x(idx+idxPeriod(2)-3:idxBreak-2))/60; % western hemisphere specific.
    
    pp.tgtLoc{d} = [tgtLat tgtLon];
    [~, pp.distTGT(d)] = lldistkm(pp.endGPS{d}, [tgtLat tgtLon]);
    
    
    
    %% target depth and time
    idx = strfind(x,'$D_TGT');
    sl = length('$D_TGT');
    % find edges
    idxBreak = regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
    % values I want...
    dTgt = str2num(x(idx+sl+1:idxBreak-1));
    pp.D_TGT(d) = dTgt;
    
    idx = strfind(x,'$T_DIVE');
    sl = length('$T_DIVE');
    idxBreak = regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
    % values I want...
    tDive = str2num(x(idx+sl+1:idxBreak-1));
    pp.T_DIVE(d) = tDive;
    pp.Wd(d,1) = 2*dTgt*100/(tDive*60);
    
    % glider calculated target pitch, speed, glide angle
    idx = strfind(x, '$MHEAD_RNG_PITCHd_Wd');
    idxComma = regexp(x(idx:end), '\,');
    idxBreak = regexp(x(idx:end),'\n','once') + idx;
    pp.desPitch(d) = str2num(x(idxComma(3)+idx:idxComma(4)+idx-2));
    pp.desVertVel(d) = str2num(x(idxComma(4)+idx:idxComma(5)+idx-2));
    pp.desGlideAngle(d) = str2num(x(idxComma(5)+idx:idxComma(6)+idx-2));
    pp.dBdW(d) = str2num(x(idxComma(6)+idx:idxBreak-2));
    
    
    
    %% center parameters
    centersList = {'$C_VBD', '$C_PITCH', '$PITCH_GAIN', ...
        '$C_ROLL_DIVE', '$C_ROLL_CLIMB', '$GLIDE_SLOPE', '$MAX_BUOY'};
    for c = 1:length(centersList)
        idx = strfind(x, centersList{c});
        sl = length(centersList{c});
        idxBreak = regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
        cVal = str2num(x(idx+sl+1:idxBreak-1));
        pp.(centersList{c}(2:end))(d) = cVal;
    end
    
    
    
    %% pitch and speed actual values
    eng_pitchAng = ncread(ncFileName, 'eng_pitchAng');
    pp.pitchDive(d) = mean(eng_pitchAng(eng_pitchAng < 0));
    pp.pitchClimb(d) = mean(eng_pitchAng(eng_pitchAng > 0));
    
    vert_speed_gsm = ncread(ncFileName, 'vert_speed_gsm');
    pp.vertSpeedDive(d) = mean(vert_speed_gsm(vert_speed_gsm < 0));
    pp.vertSpeedClimb(d) = mean(vert_speed_gsm(vert_speed_gsm > 0));
    
    pp.stwDive(d) = abs(pp.vertSpeedDive(d))/sind(abs(pp.pitchDive(d)));
    pp.stwClimb(d) = abs(pp.vertSpeedClimb(d))/sind(abs(pp.pitchClimb(d)));
    
    
    
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
    
    % kJ used ***NEED TO CHECK THIS***
    pp.PMAR_kJ(d) = pp.PMAR_SEC(d)*pp.PMAR_MAMPS(d)*15/1000000;
    
    % free space
    if pmCard == 0
        idx = strfind(x, '$PM_FREEKB');
        sl = length('$PM_FREEKB');
        idxBreak = regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
        cVal = str2num(x(idx+sl+1:idxBreak-1));
        if ~isempty(cVal)
            pp.PM_FREEKB(d) = cVal;
        else pp.PM_FREEKB(d) = NaN; end
    elseif pmCard == 1
        if d == 118
            fidx = find(strcmp(['p607' num2str(d, '%04.f') '.004.pdos'], {pdos_files.name}));
        elseif d == 128
            fidx = find(strcmp(['p607' num2str(d-1, '%04.f') '.000.pdos'], {pdos_files.name}));
        elseif d == 149
            fidx = find(strcmp(['p607' num2str(d-1, '%04.f') '.000.pdos'], {pdos_files.name}));
        elseif d == 181
            fidx = find(strcmp(['p607' num2str(d-1, '%04.f') '.000.pdos'], {pdos_files.name}));
        elseif d == 217
            fidx = find(strcmp(['p607' num2str(d-1, '%04.f') '.000.pdos'], {pdos_files.name}));
        elseif d > 223
            fidx = find(strcmp(['p607' num2str(223, '%04.f') '.000.pdos'], {pdos_files.name}));
        else
            fidx = find(strcmp(['p607' num2str(d, '%04.f') '.000.pdos'], {pdos_files.name}));
        end
        xpdos = fileread([base_path pdos_files(fidx).name]);
        idx = strfind(xpdos, 'free card');
        idxComma = regexp(xpdos(idx(1):end), '\,');
        cVal = str2num(xpdos(idx(1) + idxComma(1):idx(2) - 5));
        if ~isempty(cVal)
            pp.PM_FREEKB(d) = cVal;
        else pp.PM_FREEKB(d) = NaN; end
    end
    
    pp.PM_FREEGB(d) = pp.PM_FREEKB(d)/1000000;
    
    % space used in that dive
    if d > 1
        pp.spaceUsedGB(d,1) = (pp.PM_FREEKB(d-1) - pp.PM_FREEKB(d))/(1000*1000);
    else pp.spaceUsedGB(d,1) = NaN; end
    
    % number of files recorded per dive
    pamFolders = dir([base_path 'pm' num2str(d,'%04.f') '*']);
    
    for pf = 1:length(pamFolders)
        xp = fileread([base_path pamFolders(pf).name '\pm_ch00.eng']);
        idx = regexp(xp, '%datafiles: ');
        sl = length('%datafiles: ');
        idxBreak = regexp(xp(idx+sl:end), '\n', 'once') + idx + sl;
        if strcmp(pamFolders(pf).name(end), 'a')
            pp.numFilesDive(d) = str2num(xp(idx+sl:idxBreak-2));
        elseif strcmp(pamFolders(pf).name(end), 'b')
            if ~isempty(idx)
                pp.numFilesClimb(d) = str2num(xp(idx+sl:idxBreak-2));
            else
                pp.numFilesClimb(d) = nan;
            end
        end
    end
    pp.numFiles(d) = pp.numFilesDive(d) + pp.numFilesClimb(d);
    
    
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
    % NEED TO CHECK UNITS HERE!!!!!!!!!!!!!
    
    
    %% depth average currents
    
    pp.dac_east(d) = ncread(ncFileName,'depth_avg_curr_east');
    pp.dac_north(d) = ncread(ncFileName,'depth_avg_curr_north');
    
    
    %% any errors?
    idx = strfind(x, '$ERRORS');
    sl = length('$ERRORS');
    idxBreak = regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
    cVal = x(idx+sl+1:idxBreak-1);
    pp.ERRORS{d} = cVal;
    
end

end