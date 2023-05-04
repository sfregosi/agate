function ws = readws(wsFile)
% READWS    Read in wispr generated ws file and extract summary info
%
%	Syntax:
%		WS = READWS(WSFILE)
%
%	Description:
%		Read in ws****az files created by WISPR and downloaded/unzipped
%		from the basestation, then extract summary info on what times were
%		analyzed and how long processing took. This is used for general
%		monitoring of WISPR operation and to estimate power draw by the
%		RPi system.
%
%       Future functionality should also extract encounter information
%
%	Inputs:
%       wsFile  Optional argument specifying a file to read. If none
%               specified, will prompt for file selection; if not a
%               fullfile name with path, will prompt to select a file
%
%	Outputs:
%		ws      Structure with summary info including analysis start, stop,
%		        duration, and processing time
%
%	Examples:
%       readws(CONFIG, 'ws0001az');
%
%	See also
%       readpa
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	04 May 2023
%	Updated:
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% if CONFIG exists, use it to set up paths for file selection
global CONFIG
if isempty(CONFIG)
    clear -global CONFIG
    initialPath = pwd;
elseif ~isempty(CONFIG)
    if isfield(CONFIG.path, 'bsLocal')
        initialPath = CONFIG.path.bsLocal;
    else
        initialPath = CONFIG.path.mission;
    end
end

% if no file specified, prompt to select
if nargin < 1
    [name, path] = uigetfile({'*','All Files'}, 'Select ws file', initialPath);
    wsFile = fullfile(path, name);
end

% check that input wsFile has path
[path, ~, ~] = fileparts(wsFile);
if isempty(path)
    fprintf(1, 'No file path specified. Must select file.\n');
    [name, path] = uigetfile({'*','All Files'}, 'Select ws file', initialPath);
    wsFile = fullfile(path, name);
end

% create empty structure
ws = [];

% read in file
x = fileread(wsFile);

% time periods analyzed
ss = '$analyzed';
idx = strfind(x, ss);
idxb = regexp(x(idx:end), '\n', 'once');
idxc = regexp(x(idx:idx + idxb), ',');
ws.anStart = datetime(x(idx + idxc(1): idx + idxc(2) - 2), 'InputFormat', 'yyMMdd-HHmmss');
ws.anStart_str = datestr(ws.anStart);
ws.anStop = datetime(x(idx + idxc(2): idx + idxb - 2), 'InputFormat', 'yyMMdd-HHmmss');
ws.anStop_str = datestr(ws.anStop);
ws.anDur_min = minutes(ws.anStop - ws.anStart);

% processing time
ss = '$processtimesec';
idx = strfind(x, ss);
idxb = regexp(x(idx:end), '\n', 'once');
idxc = regexp(x(idx:idx + idxb), ',');
ws.procTime_sec = str2double(x(idx + idxc:idx + idxb - 2));

end