function downloadBasestationFiles(CONFIG)
%DOWNLOADBASESTATIONFILES   download basestation files locally via SFTP
%
%   Syntax:
%      DOWNLOADBASESTATIONFILES(CONFIG)
%
%   Description:
%       Download variety of glider piloting files from the remote
%       basestation using SFTP. Downloads all new (not previously
%       downloaded) .nc, .log, .eng, .asc, .dat, (glider data files) and
%       WISPR (ws*) files.
%
%       Download of PMAR (pm*) files/folders is untested.
%       Previous version also processed/unzipped ws* files using
%       `processWisprDetFile` but that is currently not working so that
%       step is commented out.
%       Previous version also downloaded pdos and cmdfiles (glider piloting
%       files) but that is not included here.
%
%       To redownload a file (e.g., if corrupt due to incomplete call in),
%       delete the file and re-run. The previous version generated a
%       'cache' file that listed all previously downloaded files for speed.
%       This could be implemented in the future.
%
%   Inputs:
%       CONFIG      [struct] mission/agate configuration variable.
%                   Required fields: CONFIG.bs.cnfFile (path to basestation
%                   configuration file containing url, username and either
%                   password or SSH key pair), CONFIG.path.bsLocal (folder
%                   to deposit downloaded files), and CONFIG.path.bsRemote
%                   (folder on basestation that contains the relevant files
%                   e.g., the 'current' folder if using
%                   basestation3/seaglider.pub)
%
%   Outputs:
%       Downloads files directly to specified CONFIG.path.bsLocal
%
%   Examples:
%       downloadBasestationFiles(CONFIG)
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%       D. Mellinger <David.Mellinger@oregonstate.edu> <https://github.com/DMellinger>
%
%   Updated:   07 July 2025
%
%   Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Get the right sftp() function. Since sftp can exist in multiple places,
% we need the right one - the one MATLAB has in its 'io' toolbox. (I
% thought using "matlab.io.sftp()" would work, but it doesn't.)
%
% Find the right sftp and get a handle to it. To find it among all the
% places where sftp() exists, find one whose path includes "toolbox/matlab"
% (or"toolbox\matlab"). Then cd to that directory, make a function handle
% (which will always be to a function in the current directory), and cd
% back. There has to be a better way to do this!

originalDir = pwd();
try		% use try/catch to cd back to originalDir in case of error
    all_sftps = which('-all', 'sftp');	% cell array of all sftp.m locations
    positions = regexpi(all_sftps, 'toolbox[/\\]matlab'); % find "toolbox/matlab"
    index = find(~cellfun('isempty', positions), 1); % pick the ones find() found
    sftpDir = fileparts(all_sftps{index});	% extract the directory name
    cd(sftpDir);
    matlabSFTP = @sftp;				% handle to the correct sftp
catch ERR
    cd(originalDir);
    rethrow(ERR);
end
cd(originalDir);		% restore user's original current directory

% Open connection using either username/password or username/encryptionkey.
if (isfield(CONFIG.bs, 'password') && ~isempty(CONFIG.password))
    % Use password.
    s = matlabSFTP(CONFIG.bs.host, CONFIG.username, CONFIG.password);
elseif(isfield(CONFIG.bs, 'publicKeyFile') && isfield(CONFIG.bs, 'privateKeyFile'))
    % Use encryption key.
    s = matlabSFTP(CONFIG.bs.host, CONFIG.bs.username, ...
        "PublicKeyFile", CONFIG.bs.publicKeyFile, ...
        "PrivateKeyFile", CONFIG.bs.privateKeyFile, ...
        "ConnectionTimeout", duration(minutes(30)));
else
    error('downloadBasestationFiles:NeedAuthentication', ...
        ['You must specify some way to authenticate on the remote basestation so I\n'...
        'can log in there. Normally you do this in a basestation configuration\n'...
        '.cnf file (you''re currently using %s ).\n'...
        'In that file, either specify CONFIG.bs.password, or specify both\n'...
        'CONFIG.bs.privateKeyFile and CONFIG.bs.publicKeyFile .'], CONFIG.bs.cnfFile);
end

% Make sure local directory for downloading files exists.
if (~mkdir(CONFIG.path.bsLocal))
    error('downloadBasestationFiles:CantMakeDir', "Unable to create or access %s", ...
        CONFIG.path.bsLocal);
end

% Download the files.
try			% use try/catch so we always close the sftp connection
    s.cd(CONFIG.path.bsRemote);
    % s.dir() is slow; do it once here instead of every time in downloadFileType.
    allRemoteFiles = { s.dir().name };
    pGlider = ['p' CONFIG.glider(end-2:end)];
    % Download the files.
    destDir = CONFIG.path.bsLocal;
    downloadFileType(s, [pGlider '.*\.nc$'],  '.nc',  allRemoteFiles, destDir);
    fprintf(1, '**End of .nc files**\n');
    downloadFileType(s, [pGlider '.*\.log$'], '.log', allRemoteFiles, destDir);
    fprintf(1, '**End of .log files**\n');
    downloadFileType(s, [pGlider '.*\.eng$'], '.eng', allRemoteFiles, destDir);
    fprintf(1, '**End of .eng files**\n');
    downloadFileType(s, [pGlider '.*\.asc$'], '.asc', allRemoteFiles, destDir);
    fprintf(1, '**End of .asc files**\n');
    downloadFileType(s, [pGlider '.*\.dat$'], '.dat', allRemoteFiles, destDir);
    fprintf(1, '**End of .dat files**\n');
    % PMAR files?
    if isfield(CONFIG, 'pm') && CONFIG.pm.loggers == 1
        % This pattern matches filenames starting with pm and having >=6 characters.
        downloadFileType(s, '^pm.....*', 'pm', allRemoteFiles, destDir);
        fprintf(1, '**End of PMAR folders**\n');
    end
    % WISPR files?
    if isfield(CONFIG, 'ws') && CONFIG.ws.loggers == 1
        % This pattern matches filenames starting with ws and having >=6 characters.
        toGet = downloadFileType(s, '^ws.....*', 'ws', allRemoteFiles, destDir);
        % 	% unzip these files so they are readable % THIS DOES NOT WORK!!! 2024
        % 	for wsf = 1:length(toGet)
        % 		processWisprDetFile(CONFIG, toGet{wsf});
        % 	end
        disp('**End of wispr files\n**');
    end

    % kmz (if basestation3); get every time
    kmzFile = [CONFIG.glider '.kmz'];
    if any(contains(allRemoteFiles, kmzFile))
        downloadSingleFile(s, kmzFile, destDir);
        fprintf(1, '**Downloaded .kmz file**\n');
    end
    % the up/down or timeseries file; get every time
    % old basestation calls it 'sgXXX_MissionStr_up_and_down_profile.nc'
    tsFile = [CONFIG.gmStr '_up_and_down_profile.nc'];
    if any(contains(allRemoteFiles, tsFile))
        downloadSingleFile(s, tsFile, destDir);
        fprintf(1, '**Downloaded up down profile .nc file**\n');
    end
    tsFile =  [CONFIG.gmStr '_timeseries.nc'];
    if any(contains(allRemoteFiles, tsFile))
        downloadSingleFile(s, tsFile, destDir);
        fprintf(1, '**Downloaded time series .nc file**\n');
    end

    s.close();
catch ERR
    s.close();
    rethrow(ERR);
end

end

%% downloadFileType
function toGet = downloadFileType(s, pattern, patName, allRemoteFiles, localDestDir)
% Check which files with extension 'ext' have already been downloaded over
% SFTP connection s and download any that haven't. This works for any
% extension (.nc, .log, .eng., etc.).
%
% Inputs:
%    s              open SFTP connection
%    pattern        [char] regular expression for matching remote file names
%    patName        [char] user-friendly name for pattern for showing progress
%    allRemoteFiles cell array of all filenames on the remote machine in
%                   the current (i.e., CONFIG.path.bsRemote) directory
%    localDestDir   [char] local directory where downloaded files are deposited
%
% Outputs:
%    toGet          [cell array] files that were downloaded, optional output

% Make a list of remote files matching pattern.
regexp_match = regexp(allRemoteFiles, pattern);
remoteFiles = allRemoteFiles(~cellfun(@isempty, regexp_match));

% Walk through remote file list and see which ones don't exist locally.
localFiles = { dir(localDestDir).name };	% all filenames in localDestDir
localExists = zeros(length(remoteFiles), 1);	% logical index w/existing files
for i = 1 : length(localExists)
    localExists(i) = any(~cellfun(@isempty, strfind(localFiles, remoteFiles{i})));
end
toGet = remoteFiles(~localExists);		% cell array of files to get

% Download any missing files.
% post-2024 changes (either MATLAB or seaglider.pub?) causes repeated
% timeouts or throttling. Will try each file 3 times or move on
maxAttempts = 3;

if (~isempty(toGet))
    fprintf('%d %s files: ', length(toGet), patName);
    for i = 1 : length(toGet)
        % This used to be "s.mget(toGet{i}, CONFIG.path.bsLocal)". But that takes
        % ~11 seconds per file (!!!), so I copied the meat out of s.mget here:
        options = struct("Mode", s.Mode, "RelativePathToRemoteFile", toGet{i}, ...
            "RelativePathToLocalFile", fullfile(localDestDir, toGet{i}));
       
        % set status
        success = false;
        for attempt = 1:maxAttempts
            try
                matlab.io.ftp.internal.matlab.mget(s.Connection, options);
                fprintf('.');
                success = true;
                break; % success, exit retry loop
            catch
                if attempt == maxAttempts
                    fprintf(1, 'Failed to download %s. Will need to retry downloadBasestationFiles. %s\n', ...
                        toGet{i}, ME.message);
                else
                    pause(2);
                    fprintf('/');
                end
            end
        end

        if ~success
            continue;
        end
    end
    fprintf('\n');
end

end   % function downloadFileType


%% downloadSingleFile
function downloadSingleFile(s, fileName, localDestDir)
% Download a single file of known name every time (overwrite old file as it
% gets updated with each surfacing
%
% Inputs:
%    s              open SFTP connection
%    fileName       [char] specified file name to download (not full path)
%    localDestDir   [char] local directory where downloaded files are deposited
%

options = struct("Mode", s.Mode, "RelativePathToRemoteFile", fileName, ...
    "RelativePathToLocalFile", fullfile(localDestDir, fileName));
matlab.io.ftp.internal.matlab.mget(s.Connection, options);

end % function downloadSingleFile
