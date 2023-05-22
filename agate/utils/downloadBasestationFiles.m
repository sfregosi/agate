function downloadBasestationFiles(CONFIG, path_bsLocal)
%DOWNLOADBASESTATIONFILES  download basestation files locally via SSH
%
%   Syntax:
%      DOWNLOADBASESTATIONFILES(CONFIG, path_bsLocal)
%
%   Description:
%       Function to extract/download variety of glider piloting files
%       uploaded to the basestation, using SSH protocol. Currently extracts
%       .nc, .log, .eng, .asc, .dat, (glider data files); pm folders
%       (acoustic outputs);and pdos and cmd files (glider piloting files).
%
%       Only downloads new files (that haven't been previously downloaded)
%
%   Inputs:
%       CONFIG          Deployment parameters - glider serial num, survey 
%                       ID, pmcard
%       path_bsLocal    Path to directory to save the downloaded files
%                       locally, e.g., path_bsLocal =
%                       fullfile(path_glider,'basestationFiles');
%
%   Outputs:
%       None. Downloads files directly to specified local path
%
%   Examples:
%
%   See also 
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%       D. Mellinger <David.Mellinger@oregonstate.edu> <https://github.com/DMellinger>
%
%   FirstVersion:   7/22/2016.
%                   Originally for AFFOGATO project/CatBasin deployment
%   Updated:        19 May 2023
%
%   Created with MATLAB ver.: 9.9.0.1524771 (R2020b) Update 2
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% access shell directly
% set up shell connection
ssh2_conn = ssh2_config(CONFIG.bs.host, ...
    CONFIG.bs.username, CONFIG.bs.password);

%% NC FILES
[ssh2_conn, ncFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' CONFIG.glider '/p' CONFIG.glider(3:end) '*.nc']);
downloadFileType(ncFileList, 'p', path_bsLocal, ssh2_conn);
disp('**End of .nc files**');

%% LOG FILES
[ssh2_conn, logFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' CONFIG.glider '/p' CONFIG.glider(3:end) '*.log']);
downloadFileType(logFileList, 'p', path_bsLocal, ssh2_conn);
disp('**End of .log files**');

%% ENG FILES
[ssh2_conn, engFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' CONFIG.glider '/p' CONFIG.glider(3:end) '*.eng']);
downloadFileType(engFileList, 'p', path_bsLocal, ssh2_conn);
disp('**End of .eng files**');

%% ASC FILES
[ssh2_conn, ascFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' CONFIG.glider '/p' CONFIG.glider(3:end) '*.asc']);
downloadFileType(ascFileList, 'p', path_bsLocal, ssh2_conn);
disp('**End of .asc files**');

%% DAT FILES
[ssh2_conn, datFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' CONFIG.glider '/p' CONFIG.glider(3:end) '*.dat']);
downloadFileType(datFileList, 'p', path_bsLocal, ssh2_conn);
disp('**End of .dat files**');

%% PMAR FILES

if isfield(CONFIG, 'pm') && CONFIG.pm.loggers == 1
    % if CONFIG.pmCard == 0 % skip these when writing to card 1
    [ssh2_conn, pmarFolderList] = ssh2_command(ssh2_conn, ...
        ['ls -d /home/' CONFIG.glider '/pm*/']);

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
end

%% WISPR FILES

if isfield(CONFIG, 'ws') && CONFIG.ws.loggers == 1
    [ssh2_conn, wsFileList] = ssh2_command(ssh2_conn, ...
        ['ls /home/' CONFIG.glider '/ws*.x*']);
    files = downloadFileType(wsFileList, 'ws', path_bsLocal, ssh2_conn);
    for i = 1 : length(files)
      processWisprDetFile(path_bsLocal, files{i});
    end
    % Should clean up and remove the .x00 files? Or move them to a subdirectory.
    disp('**End of wispr files**');
end


%% CMD FILES
[ssh2_conn, cmdFileList] = ssh2_command(ssh2_conn, ...
    ['ls /home/' CONFIG.glider '/cmdfile*.*']);

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
            cmdFileName = ['/home/' CONFIG.glider '/cmdfile.' num2str(uD) '.' num2str(sumPerDive(u))];
        elseif sumPerDive(u) == 0
            cmdFileName = ['/home/' CONFIG.glider '/cmdfile.', num2str(uD)];
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
    ['ls /home/' CONFIG.glider '/p' CONFIG.glider(3:end) '*.pdos']);

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
    ['ls /home/' CONFIG.glider '/' CONFIG.glider '*_up_and_down_profile.nc']);


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
function downloadedFiles = downloadFileType(fileList, matchExp, path_bsLocal, ssh2_conn)
% check which files for that extension have already been downloaded and
% download any that haven't. This works for .nc, .log, .eng., .asc, and
% .dat
downloadedFiles = {};
for f = 1:length(fileList)
    if isempty(fileList{f})
        return
    else
        mIdx = regexp(fileList{f}, matchExp);
        if exist(fullfile(path_bsLocal, fileList{f}(mIdx:end)), 'file')
            % don't download it again
        else
            ssh2_conn = scp_get(ssh2_conn, fileList{f}, path_bsLocal);
            disp([fileList{f} ' now saved']);
	    downloadedFiles{end + 1} = fileList{f};		%#ok<AGROW>
	    % Moved WISPR-file unzipping out of here because it seemed better to
	    % do it above where WISPR files are handled.
        end
    end
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function processWisprDetFile(path_bsLocal, filename)
% Unzip a WISPR/ERMA detection file, which typically has a name like
% ws0047az.x00, and remove the extraneous characters that show up in such files.
% The result is left in a file of the same name but without any extension.
% Assumes path_bsLocal/filename is a valid file name including an extension, and
% that it can be unzipped.
%
% The potential extraneous characters that get removed are extra ^M characters
% (ASCII 13) every 64 characters throughout the file - I don't know how/where
% these get in there - as well as 'W>' at the end of the file, which is left
% over from the WISPR-to-Seaglider communications protocol.
%
% Dave Mellinger, David.Mellinger@oregonstate.edu

% Unzip the file. gunzip creates an unzipped version without any extension.
[~, name, ext] = fileparts(filename);
gunzip(fullfile(path_bsLocal, [name, ext]));	% makes unzipped file sans ext

% Remove the stray ^M and ending "W>" characters. Done by reading the whole
% file, removing those characters, and writing back what's left.
fp = fopen(fullfile(path_bsLocal, name), 'r');
str = fread(fp).';				% read entire file as uint8s
fclose(fp);
str(str == 13) = [];				% remove ^M characters
if (length(str) >= 2 && strcmp(char(str(end-1 : end)), 'W>'))
    str = str(1 : end-2);			% remove trailing "W>"
end
fp = fopen(fullfile(path_bsLocal, name), 'w');
fwrite(fp, str);				% write str as uint8s
fclose(fp);

end