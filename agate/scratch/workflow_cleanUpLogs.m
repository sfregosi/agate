% WORKFLOW_CLEANLOGS.M
%	Example workflow for cleaning up/combining Triton or ERMA logs
%
%	Description:
%		Detailed description here, please
%
%	Notes
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	FirstVersion: 	13 March 2024
%	Updated:
%
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% created this placeholder but have done no work on it. 

% see glider-mhi repo for example from MHI project - workflow_cleanUpLogs.m


% workflow for cleaning up Triton logs for fkw analysis
%
% This requires the agate-public repository, access at:
%                                       (github.com/sfregosi/agate-public)
%
% S. Fregosi 15 February 2023

addpath(genpath('C:\Users\Selene.Fregosi\Documents\GitHub\agate-public'));

path_analysis = 'C:\Users\Selene.Fregosi\Documents\GitHub\glider-MHI\analysis\';

glider = 'sg639'; mission = 'MHI_Apr2023'; 
% glider = 'sg680'; mission = 'MHI_Apr2022';
% glider = 'sg679'; mission = 'MHI_May2023'; 

% logFileName = [glider '_' mission '_MW.xls'];
% logFile = fullfile(path_analysis, 'wood', [glider '_' mission '_log_mw'], ...
% 	logFileName);
% logFile = ['C:\Users\Selene.Fregosi\Documents\GitHub\glider-MHI\' ...
%     'analysis\wood\' glider '_MHI_log_mw\', glider '_MHI_log_mw_sf.xls'];

logFileName = [glider '_' mission '_MW_recheck.xls'];
logFile = fullfile(path_analysis, 'wood', [glider '_' mission '_recheck_mw'], ...
	logFileName);
eventGap = 15;

[tl, tlm] = collapseTritonLog(logFile, eventGap);
save(fullfile(path_analysis, 'fkw', [glider '_' mission '_log_merged.mat']), ...
	'tl', 'tlm');

% simplify for banter and add glider to eventID string
eventStr = arrayfun(@(x) num2str(x, '%02.f'), tl.eventNum, 'UniformOutput', 0);
gc = cell(height(tl), 1);
gc(:) = {glider};
tl.eventID = cellfun(@(x,y) [x '_' y], gc, eventStr, 'UniformOutput', 0);

eventStr = arrayfun(@(x) num2str(x, '%02.f'), tlm.eventNum, 'UniformOutput', 0);
gc = cell(height(tlm), 1);
gc(:) = {glider};
tlm.eventID = cellfun(@(x,y) [x '_' y], gc, eventStr, 'UniformOutput', 0);

tls = tlm(:, [2 3 4 7]);
tls.Properties.VariableNames = {'start', 'end', 'sp', 'id'};
tls.start.Format = 'MM/dd/uuuu HH:mm:ss';
tls.end.Format = 'MM/dd/uuuu HH:mm:ss';
writetable(tls, fullfile(path_analysis, 'fkw', [glider '_' mission '_log_merged.csv']));




