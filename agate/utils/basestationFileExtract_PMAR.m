function basestationFileExtract_PMAR(dPARAMS, bsConfig, path_bsLocal)
% BASESTATIONFILEEXTRACT_PMAR   download basestation files locally via SSH
%
%   Syntax:
%       basestationFileExtract_PMAR(dPARAMS, bsConfig, path_bsLocal)
%
%   Description:
%       Function to extract/download variety of glider piloting files
%       uploaded to the basestation, using SSH protocol. Currently extracts
%       .nc, .log, .eng, .asc, .dat, (glider data files); pm folders
%       (acoustic outputs);and pdos and cmd files (glider piloting files).
%       Only downloads new files (that haven't been previously downloaded)
%
%   Inputs:
%       dPARAMS   deployment parameters - glider serial num, survey ID, pmcard
%       bsConfig  struct with basestation configuration variables (url, pswrd)
%       path_bsLocal    directory of where to save the downloaded files
%                       locally, typically set to path_bsFilesLocal =
%                       fullfile(path_glider,'basestationFiles');
%
%   Outputs:
%       None. Downloads files directly to specified local path
%
%   Examples:
%
%   See also BASESTATIONFILEEXTRACT
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%   Created with MATLAB ver.: 9.9.0.1524771 (R2020b) Update 2
%
%   FirstVersion:   7/22/2016.
%                   Originally for AFFOGATO project/CatBasin deployment
%   Updated:
%       2020 02 07 SoCal 2020 deployment - work with PMAR - Card 0
%       2020 03 04 to work around no output from PMAR Card 1; removed URL
%       2022 04 05 partially set up bsConfig approach, build in catches
%           for empty dives
%       2022 07 19 added in .dat files to be extracted, updated help text
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% access shell directly
% set up shell connection
ssh2_conn = ssh2_config(bsConfig.host, ...
    bsConfig.username, bsConfig.password);

%% NC FILES
[ssh2_conn, ncFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' dPARAMS.glider '/p' dPARAMS.glider(3:end) '*.nc']);
downloadFileType(ncFileList, path_bsLocal, ssh2_conn);
disp('**End of .nc files**');

%% LOG FILES
[ssh2_conn, logFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' dPARAMS.glider '/p' dPARAMS.glider(3:end) '*.log']);
downloadFileType(logFileList, path_bsLocal, ssh2_conn);
disp('**End of .log files**');

%% ENG FILES
[ssh2_conn, engFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' dPARAMS.glider '/p' dPARAMS.glider(3:end) '*.eng']);
downloadFileType(engFileList, path_bsLocal, ssh2_conn);
disp('**End of .eng files**');

%% ASC FILES
[ssh2_conn, ascFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' dPARAMS.glider '/p' dPARAMS.glider(3:end) '*.asc']);
downloadFileType(ascFileList, path_bsLocal, ssh2_conn);
disp('**End of .asc files**');

%% DAT FILES
[ssh2_conn, datFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' dPARAMS.glider '/p' dPARAMS.glider(3:end) '*.dat']);
downloadFileType(datFileList, path_bsLocal, ssh2_conn);
disp('**End of .dat files**');

%% PMAR FILES

% if dPARAMS.pmCard == 0 % skip these when writing to card 1
[ssh2_conn, pmarFolderList] = ssh2_command(ssh2_conn, ...
    ['ls -d /home/' dPARAMS.glider '/pm*/']);

% check which already have been downloaded.
for f = 1:length(pmarFolderList)
    [ssh2_conn, pmarFileList] = ssh2_command(ssh2_conn, ...
        ['ls ' pmarFolderList{f} '*.eng']);
    if isempty(pmarFolderList{f})
        continue
    else
        if exist(fullfile(path_bsLocal, pmarFolderList{f}(end-7:end)), 'dir')
            % don't download it again
        else
            mkdir(fullfile(path_bsLocal, pmarFolderList{f}(end-7:end)));
            ssh2_conn = scp_get(ssh2_conn, pmarFileList, fullfile(path_bsLocal, pmarFolderList{f}(end-7:end)));
            disp([pmarFolderList{f} ' now saved']);
        end
    end
end
disp('**End of PMAR folders**');
% end


%% CMD FILES
[ssh2_conn, cmdFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' dPARAMS.glider '/cmdfile*.*']);

% extract all the first digits for dive number
diveNums = zeros(length(cmdFileList) - 1,1);
if ~isempty(diveNums)
    for l = 1:length(cmdFileList)
        pIdx = regexp(cmdFileList{l}, '\.');
        if length(pIdx) == 1
            diveNums(l,1) = str2double(cmdFileList{l}(pIdx + 1:end));
        else
            diveNums(l,1) = str2double(cmdFileList{l}(pIdx(1) + 1:pIdx(2)-1));
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

    % check which already have been downloaded.
    for u = 1:length(unqDives)
        uD = unqDives(u);
        if sumPerDive(u) > 0
            cmdFileName = ['/home/' dPARAMS.glider '/cmdfile.' num2str(uD) '.' num2str(sumPerDive(u))];
        elseif sumPerDive(u) == 0
            cmdFileName = ['/home/' dPARAMS.glider '/cmdfile.', num2str(uD)];
        end
        % strip the folder
        slashIdx = regexp(cmdFileName, '\/');
        if exist(fullfile(path_bsLocal, cmdFileName(slashIdx(end)+1:end)), 'file')
            % don't download it again
        else
            try
                ssh2_conn = scp_get(ssh2_conn, cmdFileName, path_bsLocal);
                disp([cmdFileName ' now saved']);
            catch
                disp(['error with ' cmdFileName])
                %             if uD == 2
                %                 cmdFileName = '\home\sg607\cmdfile.2.12'; % call 11 was on board so didnt come through
                %                 ssh2_conn = scp_get(ssh2_conn, cmdFileName, outDir);
                %                 disp([cmdFileName ' now saved']);
                %             end
            end
        end
    end
end % diveNums empty check
disp('**End of cmdfiles**');

%% PDOSCMDS.BAT FILES
[ssh2_conn, pdosFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' dPARAMS.glider '/p' dPARAMS.glider(3:end) '*.pdos']);

% check which already have been downloaded.
for f = 1:length(pdosFileList)
    if isempty(pdosFileList{f})
        continue
    else
        if exist(fullfile(path_bsLocal, pdosFileList{f}(13:end)), 'file')
            % don't download it again
        else
            try
                ssh2_conn = scp_get(ssh2_conn, pdosFileList{f}, path_bsLocal);
                disp([pdosFileList{f} ' now saved']);
            catch
                disp('no pdos file to download')
            end
        end
    end
end
disp('**End of .pdos files**');

%% get processed up_and_down_profile.nc file
[ssh2_conn, udFile] = ssh2_command(ssh2_conn, ...
    ['ls /home/' dPARAMS.glider '/' dPARAMS.glider '*_up_and_down_profile.nc']);


% check which already have been downloaded.
if ~isempty(udFile{:})
    try
        ssh2_conn = scp_get(ssh2_conn, udFile, path_bsLocal);
        fprintf(1, '%s saved\n', udFile{:});
    catch
        disp('no nc file to download')
    end
end


%% close port
ssh2_conn = ssh2_close(ssh2_conn);

end

%% %%%%%%%%%%%%%%%%
% NESTED FUNCTIONS
% %%%%%%%%%%%%%%%%%
function downloadFileType(fileList, path_bsLocal, ssh2_conn)
% check which files for that extension have already been downloaded and
% download any that haven't. This works for .nc, .log, .eng., .asc, and
% .dat
for f = 1:length(fileList)
    if isempty(fileList{f})
        return
    else
        pIdx = regexp(fileList{f}, 'p');
        if exist(fullfile(path_bsLocal, fileList{f}(pIdx:end)), 'file')
            % don't download it again
        else
            ssh2_conn = scp_get(ssh2_conn, fileList{f}, path_bsLocal);
            disp([fileList{f} ' now saved']);
        end
    end
end

end