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
%       (pmar acoustic outputs); ws files (wispr acoustic outputs) and pdos
%       and cmd files (glider piloting files).
%
%       Only downloads new files (that haven't been previously downloaded).
%       To re-download a single file, delete that files corresponding line
%       in downloaded_files_cache.txt. To re-download all files, delete
%       download_files_cache.txt
%
%   Inputs:
%       CONFIG          Deployment parameters - glider serial num, mission
%                       ID, pmcard
%       path_bsLocal    Path to directory to save the downloaded files
%                       locally, e.g., path_bsLocal =
%                       fullfile(path_glider,'basestationFiles');
%
%   Outputs:
%       No variables, but downloads files directly to specified local path
%       and creates a 'downloaded_files_cache.txt' within path_bslocal
%       that lists all previously downloaded files (for speed)
%
%   Examples:
%       downloadBasestationFiles(CONFIG, path_bsLocal)
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%       D. Mellinger <David.Mellinger@oregonstate.edu> <https://github.com/DMellinger>
%
%   FirstVersion:   7/22/2016.
%                   Originally for AFFOGATO project/CatBasin deployment
%   Updated:        07 August 2024
%
%   Created with MATLAB ver.: 9.9.0.1524771 (R2020b) Update 2
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (nargin < 2 && isfield(CONFIG.path, 'bsLocal'))
  path_bsLocal = CONFIG.path.bsLocal;
end

%% set up cache file
if ~exist(fullfile(path_bsLocal, 'downloaded_files_cache.txt'), 'file')
	% create it and populate header lines
	fid = fopen(fullfile(path_bsLocal, 'downloaded_files_cache.txt'), 'w');
	fprintf(fid, ['# This file lists all basestation files that have been ' ...
		'downloaded and the times they were downloaded\n' ...
		'# To force a file to be re-downloaded, delete the corresponding ' ...
		'line from this file\n# Created %s\n'], datetime('now', 'Format', ...
		'HH:mm:ss dd MMM uuuu ZZZZ', 'TimeZone', '+0000'));
	fclose(fid);
end

if exist(fullfile(path_bsLocal, 'downloaded_files_cache.txt'), 'file')
	% read in the cached file (have to do this before specifying append or
	% it comes up empty)
	fid = fopen(fullfile(path_bsLocal, 'downloaded_files_cache.txt'), 'r');
	df = textscan(fid, '%s', 'Delimiter', '\n');
	fclose(fid);
	df = df{:};
end
% now re-open to append
fid = fopen(fullfile(path_bsLocal, 'downloaded_files_cache.txt'), 'a+');

fprintf(1, 'Starting basestation file download...\n')

%% access shell directly
% set up shell connection
ssh2_conn = ssh2_config(CONFIG.bs.host, ...
	CONFIG.bs.username, CONFIG.bs.password);

%% NC FILES
[ssh2_conn, ncFileList] = ssh2_command(ssh2_conn, ...
	['ls /home/' CONFIG.glider '/p' CONFIG.glider(3:end) '*.nc']);
[~, df] = downloadFileType(ncFileList, df, fid, path_bsLocal, ssh2_conn);
disp('**End of .nc files**');

%% LOG FILES
[ssh2_conn, logFileList] = ssh2_command(ssh2_conn, ...
	['ls /home/' CONFIG.glider '/p' CONFIG.glider(3:end) '*.log']);
[~, df] = downloadFileType(logFileList, df, fid, path_bsLocal, ssh2_conn);
disp('**End of .log files**');

%% ENG FILES
[ssh2_conn, engFileList] = ssh2_command(ssh2_conn, ...
	['ls /home/' CONFIG.glider '/p' CONFIG.glider(3:end) '*.eng']);
[~, df] = downloadFileType(engFileList, df, fid, path_bsLocal, ssh2_conn);
disp('**End of .eng files**');

%% ASC FILES
[ssh2_conn, ascFileList] = ssh2_command(ssh2_conn, ...
	['ls /home/' CONFIG.glider '/p' CONFIG.glider(3:end) '*.asc']);
[~, df] = downloadFileType(ascFileList, df, fid, path_bsLocal, ssh2_conn);
disp('**End of .asc files**');

%% DAT FILES
[ssh2_conn, datFileList] = ssh2_command(ssh2_conn, ...
	['ls /home/' CONFIG.glider '/p' CONFIG.glider(3:end) '*.dat']);
[~, df] = downloadFileType(datFileList, df, fid, path_bsLocal, ssh2_conn);
disp('**End of .dat files**');

%% PMAR FILES

if isfield(CONFIG, 'pm') && CONFIG.pm.loggers == 1
	% if CONFIG.pmCard == 0 % skip these when writing to card 1
	[ssh2_conn, pmarFolderList] = ssh2_command(ssh2_conn, ...
		['ls -d /home/' CONFIG.glider '/pm*/']);

	if ~isempty(pmarFolderList)
		% check which already have been downloaded.
		for f = 1:length(pmarFolderList)
			fMask = ~cellfun(@isempty, regexp(df, pmarFolderList{f}));
			if isempty(find(fMask, 1)) % doesn't exist in download cache file
				% make a folder on the basestation
				path_bsLocal_pm = fullfile(path_bsLocal, pmarFolderList{f}(end-7:end));
				mkdir(path_bsLocal_pm);
				% download new files
				[ssh2_conn, pmarFileList] = ssh2_command(ssh2_conn, ...
					['ls ' pmarFolderList{f} '*.eng']);
				[~, df] = downloadFileType(pmarFileList, df, fid, ...
					path_bsLocal_pm, ssh2_conn);
			end
		end
	end
	disp('**End of PMAR folders**');
end

%% WISPR FILES

if isfield(CONFIG, 'ws') && CONFIG.ws.loggers == 1
	[ssh2_conn, wsFileList] = ssh2_command(ssh2_conn, ...
		['ls /home/' CONFIG.glider '/ws*.x*']);
	[wsFiles, df] = downloadFileType(wsFileList, df, fid, path_bsLocal, ssh2_conn);
	for i = 1 : length(wsFiles)
		processWisprDetFile(path_bsLocal, wsFiles{i});
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
	sumPerDive = nan(length(unqDives),1);
	for u = 1:length(unqDives)
		uD = unqDives(u);
		sumPerDive(u) = sum(diveNums == uD);
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

% always download this one because it is updated after each dive
if ~isempty(udFile{:})
	try
		ssh2_conn = scp_get(ssh2_conn, udFile, path_bsLocal);
		fprintf(1, '%s saved\n', udFile{:});
	catch
		disp('no nc file to download')
	end
end

%% close port and file
ssh2_close(ssh2_conn);
fclose(fid);

end



%% %%%%%%%%%%%%%%%%
% NESTED FUNCTIONS
% %%%%%%%%%%%%%%%%%
function [downloadedFiles, df] = downloadFileType(fileList, df, fid, path_bsLocal, ssh2_conn)
% check which files for that extension have already been downloaded and
% download any that haven't. This works for .nc, .log, .eng., .asc, .dat, 
% pmar and wispr
%
% fileList      [cell] with all files of that type present on basestation
% df            [cell aray] list of previously downloaded files
% fid           [integer] file identifier for cache text file to write any
%               new downloaded files
% path_bsLocal  [string] location to save newly downloaded files
% ssh2_conn     [struct] active ssh connection

downloadedFiles = {};
for f = 1:length(fileList)
	if isempty(fileList{f})
		return
	else
		fMask = ~cellfun(@isempty, regexp(df, fileList{f}));
		if isempty(find(fMask, 1)) % doesn't exist in download cache file
			% download it
			ssh2_conn = scp_get(ssh2_conn, fileList{f}, path_bsLocal);
			disp([fileList{f} ' now saved']);
			downloadedFiles{end + 1} = fileList{f};		%#ok<AGROW>
			% add it to cache file
			fprintf(fid, '%s, %s\n', fileList{f}, datetime('now', 'Format', ...
				'HH:mm:ss dd MMM uuuu ZZZZ', 'TimeZone', '+0000'));
			% and add to df
			df{end+1} = sprintf('%s, %s\n', fileList{f}, datetime('now', 'Format', ...
				'HH:mm:ss dd MMM uuuu ZZZZ', 'TimeZone', '+0000')); %#ok<AGROW>
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