function clog = combineErmaLogs(CONFIG, path_logs, verbose)
% COMBINEERMALOGS	One-line description here, please
%
%   Syntax:
%       OUTPUT = COMBINEERMALOGS(INPUT)
%
%   Description:
%       Detailed description here, please
%   Inputs:
%       CONFIG    [struct] agate global mission configuration structure
%       path_logs [string] fullfile path to the log files to be combined
%                 If this is not specified or is empty ([]) will use the
%                 basestation path from CONFIG
%       verbose   [logical] optional argument to print progress in Command
%                 Window. Default 'false', set to 'true' or '1' to print.
%
%	Outputs:
%       output  describe, please
%
%   Examples:
%
%   See also READERMAREPORT
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   13 March 2024
%   Updated:
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FOR TESTING %%%%%

% path_logs = 'D:\sg679_MHI_May2023\piloting\basestationFiles';
% verbose = true;

%%%%%%%%%%%%%%%%%%%

% check args
if nargin < 2 || isempty(path_logs)
	path_logs = CONFIG.path.bsLocal;
end

if nargin < 3 || isempty(verbose)
	verbose = 'false';
end


% get a list of all logs for this mission
logFiles = dir(fullfile(path_logs, 'ws*z'));

if verbose == true
	fprintf(1, 'Combining %i ERMA log files from %s\n', length(logFiles), path_logs);
end

for l = 1:length(logFiles)
	detFile = fullfile(logFiles(l).folder, logFiles(l).name);
	s = readErmaReport(detFile);

	% if s has some data
	if ~isempty(s.enc)
		if verbose == true
			fprintf(1, '%s: %i encounters parsed\n', logFiles(l).name, length(s.enc));
			x = 5;
		end
	elseif isempty(s.enc) && verbose == true
		fprintf(1, '%s: no encounters\n', logFiles(l).name);
	end


end


end