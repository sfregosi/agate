function downloadBasestationFiles1(CONFIG)
%downloadBasestationFiles1	download new glider files from basestation
% 
% downloadBasestationFiles1(CONFIG)
%   Download all .log, .nc, .asc, .eng, .dat, WISPR (ws*), and PMAR (pm*) files
%   from a basestation described in CONFIG.bs. This is a replacement for the
%   older downloadBasestationFiles() routine. In addition to CONFIG.bs, also
%   uses CONFIG.path.bsLocal, which says where to deposit the downloaded files.

% Get the right sftp() function. Since sftp can exist in multiple places, we
% need the right one - the one MATLAB has in its 'io' toolbox. (I thought using
% "matlab.io.sftp()" would work, but it doesn't.) 
% 
% Find the right sftp and get a handle to it. To find it among all the places
% where sftp() exists, find one whose path includes "toolbox/matlab" (or
% "toolbox\matlab"). Then cd to that directory, make a function handle (which
% will always be to a function in the current directory), and cd back. There has
% to be a better way to do this!
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
  s = matlabSFTP('seaglider.pub', CONFIG.username, CONFIG.password);
elseif(isfield(CONFIG.bs, 'publicKeyFile') && isfield(CONFIG.bs, 'privateKeyFile'))
  % Use encryption key.
  s = matlabSFTP('seaglider.pub', CONFIG.bs.username, ...
    "PublicKeyFile", CONFIG.bs.publicKeyFile, ...
    "PrivateKeyFile", CONFIG.bs.privateKeyFile);
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
  pGlider = ['p' CONFIG.glider(end-2 : end)];
  % Download the files.
  destDir = CONFIG.path.bsLocal;
  downloadFileType(s, [pGlider '.*\.nc$'],  '.nc',  allRemoteFiles, destDir);
  downloadFileType(s, [pGlider '.*\.log$'], '.log', allRemoteFiles, destDir);
  downloadFileType(s, [pGlider '.*\.eng$'], '.eng', allRemoteFiles, destDir);
  downloadFileType(s, [pGlider '.*\.asc$'], '.asc', allRemoteFiles, destDir);
  downloadFileType(s, [pGlider '.*\.dat$'], '.dat', allRemoteFiles, destDir);
  if isfield(CONFIG, 'pm') && CONFIG.pm.loggers == 1         % PMAR files?
    % This pattern matches filenames starting with pm and having >=6 characters.
    downloadFileType(s, '^pm.....*', 'pm', allRemoteFiles, destDir);
  end
  if isfield(CONFIG, 'ws') && CONFIG.ws.loggers == 1         % WISPR files?
    % This pattern matches filenames starting with ws and having >=6 characters.
    downloadFileType(s, '^ws.....*', 'ws', allRemoteFiles, destDir);
  end
  s.close();
catch ERR
  s.close();
  rethrow(ERR);
end

end

%% downloadFileType
function downloadFileType(s, pattern, patName, allRemoteFiles, localDestDir)
% Check which files with extension 'ext' have already been downloaded over SFTP
% connection s and download any that haven't. This works for any extension (.nc,
% .log, .eng., etc.). 
%    s			open SFTP connection
%    pattern		regular expression for matching remote file names
%    patName		user-friendly name for pattern for showing progress
%    allRemoteFiles	cell array of all filenames on the remote machine in the
%			current (i.e., CONFIG.path.bsRemote) directory
%    localDestDir	local directory where downloaded files are deposited

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
if (~isempty(toGet))
  fprintf('%d %s files: ', length(toGet), patName);
  for i = 1 : length(toGet)
    fprintf('.');
    % This used to be "s.mget(toGet{i}, CONFIG.path.bsLocal)". But that takes
    % ~11 seconds per file (!!!), so I copied the meat out of s.mget here:
    options = struct("Mode", s.Mode, "RelativePathToRemoteFile", toGet{i}, ...
      "RelativePathToLocalFile", fullfile(localDestDir, toGet{i}));
    matlab.io.ftp.internal.matlab.mget(s.Connection, options);
  end
  fprintf('\n');
end

end   % function downloadFileType
