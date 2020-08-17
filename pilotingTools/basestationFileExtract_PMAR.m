function extract = basestationFileExtract_PMAR(glider, pmCard, outDir)
% To extract glider files from the base station
% S. Fregosi 7/22/2016. Originally for AFFOGATO project/CatBasin deployment
% Updated 2020 02 07 SoCal 2020 deployment - work with PMAR xl - Card 0
% updated 2020 03 04 to work around no output from PMAR Card 1; removed URL

% Currently extracts .nc, .log, .eng, pm, pdos, cmd files using ssh protocol
% Inputs:
% glider    should be something like 'sg607'
% outDir    directory of where to save the downloaded files

% Original path used
% outDir=['C:\Users\sfreg_000\SkyDrive\gliders_local\AFFOGATO\'...
%    '2016_07_CatBasin\sg607\extractedFiles\'];

%% accesssing shell directly

% set up shell connection
ssh2_conn = ssh2_config('osudock2.coas.oregonstate.edu', ...
    'pilot', 'J33K35A#');
remotePath = ['/home/' glider '/'];
% ssh2_conn = ssh2_command(ssh2_conn,'pwd');
% ssh2_conn = ssh2_command(ssh2_conn,['ls -la /home/' glider '/p*.nc']);


%% NC FILES
[ssh2_conn, ncFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' glider '/p*.nc']);

% check which already have been downloaded.
for f = 1:length(ncFileList)
    if exist([outDir ncFileList{f}(end-10:end)])
        % don't download it again
    else
        ssh2_conn = scp_get(ssh2_conn, ncFileList{f}, outDir);
        disp([ncFileList{f} ' now saved']);
    end
end

% compiled .nc file
% compFileName = '/home/sg607/sg607_SoCal2020_5.0m_up_and_down_profile.nc';
% ssh2_conn = scp_get(ssh2_conn, compFileName, outDir);
% disp(['compiled nc file saved'])

disp('**End of .nc files**');

%% LOG FILES
[ssh2_conn, logFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' glider '/p' glider(3:end) '*.log']);

% check which already have been downloaded.
for f = 1:length(logFileList)
    if exist([outDir logFileList{f}(end-11:end)])
        % don't download it again
    else
        ssh2_conn = scp_get(ssh2_conn, logFileList{f}, outDir);
        disp([logFileList{f} ' now saved']);
    end
end
disp('**End of .log files**');


%% ENG FILES
[ssh2_conn, engFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' glider '/p' glider(3:end) '*.eng']);

% check which already have been downloaded.
for f = 1:length(engFileList)
    if exist([outDir engFileList{f}(end-11:end)])
        % don't download it again
    else
        ssh2_conn = scp_get(ssh2_conn, engFileList{f}, outDir);
        disp([engFileList{f} ' now saved']);
    end
end
disp('**End of .eng files**');



%% PMAR FILES

if pmCard == 0 % skip these when writing to card 1
    [ssh2_conn, pmarFolderList] = ssh2_command(ssh2_conn, ...
        ['ls -d /home/' glider '/pm*/']);
    
    % check which already have been downloaded.
    for f = 1:length(pmarFolderList)
        [ssh2_conn, pmarFileList] = ssh2_command(ssh2_conn, ...
            ['ls ' pmarFolderList{f} '*.eng']);
        if exist([outDir pmarFolderList{f}(end-7:end)], 'dir')
            % don't download it again
        else
            mkdir([outDir pmarFolderList{f}(end-7:end)]);
            ssh2_conn = scp_get(ssh2_conn, pmarFileList, [outDir pmarFolderList{f}(end-7:end)]);
            disp([pmarFolderList{f} ' now saved']);
        end
    end
    disp('**End of PMAR folders**');
end


%% CMD FILES
[ssh2_conn, cmdFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' glider '/cmdfile*.*']);

% extract all the first digits for dive number
diveNums = zeros(length(cmdFileList) - 1,1);
for l = 1:length(cmdFileList)
    pIdx = regexp(cmdFileList{l}, '\.');
    if length(pIdx) == 1
        diveNums(l,1) = str2num(cmdFileList{l}(pIdx + 1:end));
    else
        diveNums(l,1) = str2num(cmdFileList{l}(pIdx(1) + 1:pIdx(2)-1));
    end
end

% now find the index of the last cmdfile for that dive number
unqDives = unique(diveNums);
sumPerDive = [];
for u = 1:length(unqDives)
    uD = unqDives(u);
    sumPerDive = [sumPerDive; sum(diveNums == uD)];
end
sumPerDive = sumPerDive - 1; % for first cmdfile uploaded per dive

if strcmp(glider, 'sg607')
    % call 11 was on board so didnt come through
    sumPerDive(3,1) = 12;
end

% check which already have been downloaded.
for u = 1:length(unqDives)
    uD = unqDives(u);
    if sumPerDive(u) > 0
        cmdFileName = ['/home/' glider '/cmdfile.' num2str(uD) '.' ...
            num2str(sumPerDive(u))];
    elseif sumPerDive(u) == 0
        cmdFileName = ['/home/' glider '/cmdfile.' num2str(uD)];
    end
    % strip the folder
    slashIdx = regexp(cmdFileName, '\/');
    if exist([outDir cmdFileName(slashIdx(end)+1:end)], 'file')
        % don't download it again
    else
        try
            ssh2_conn = scp_get(ssh2_conn, cmdFileName, outDir);
            disp([cmdFileName ' now saved']);
        catch
            disp(['error with ' cmdFileName])
            %             if uD == 2
            %                 cmdFileName = '/home/sg607/cmdfile.2.12'; % call 11 was on board so didnt come through
            %                 ssh2_conn = scp_get(ssh2_conn, cmdFileName, outDir);
            %                 disp([cmdFileName ' now saved']);
            %             end
        end
    end
end
disp('**End of cmdfiles**');

%% PDOSCMDS.BAT FILES
[ssh2_conn, pdosFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' glider '/p' glider(3:end) '*.pdos']);

% check which already have been downloaded.
for f = 1:length(pdosFileList)
    if exist([outDir pdosFileList{f}(13:end)])
        % don't download it again
    else
        try
        ssh2_conn = scp_get(ssh2_conn, pdosFileList{f}, outDir);
        disp([pdosFileList{f} ' now saved']);
        catch
            disp('no pdos file to download')
        end
    end
end
disp('**End of .pdos files**');


%% close port
ssh2_conn = ssh2_close(ssh2_conn);



end
