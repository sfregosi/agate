% WORKFLOW_CLEANLOGS.M
%	Example workflow for cleaning up/combining Triton or ERMA logs
%
%	Description:
%		Example/template workflow demonstrating how to clean up cetacean
%		event logs, either manually or automaticaly identified, for further
%		processing with other agate tools or with PAMpal. 
%		Two log formats are covered:
%
%		Triton logs: Uses COLLAPSETRITONLOG to compress a raw Triton log
%		to one entry per event - merging rows where multiple signal
%		types (e.g., clicks and whistles) were logged under a single
%		event, and optionally merging separate events that fall within
%		a specified time gap of one another. TRITONLOGTOPAMPAL is then
%		used to reformat the collapsed log into the column structure
%		required to build a PAMpal AcousticStudy event table.
%
%		ERMA logs: [TODO - fill in once ERMA workflow functions exist]
%
%		This script is intended as a copy-and-edit starting point rather
%		than a function - update the file paths, log filename, and
%		event-merging gap for your specific dataset/mission before
%		running.
%
%	Notes
%
%	See also COLLAPSETRITONLOG, TRITONLOGTOPAMPAL
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	Updated: 2026 July 29
%
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% SCRATCH STAGE

% make sure agate is on the path!
addpath(genpath('C:\Users\User.Name\Documents\MATLAB\agate'))
% initializing agate is not necessary for this workflow, but CONFIG could
% be used optionally to streamline your working directory/paths

% set path to logs (to be used in file inputs and as save locations below)
path_logs = 'Z:\triton_logs\';
% set glider ID (used as prefix for eventIDs, naming)
glider = 'sgXXX';

%% Workflow to work with Triton logs
% Collapse events with multiple signal types into single events and
% optionally merge events within some set time (e.g., 15 mins) of eachother

% specify log file to process
logFile = fullfile(path_logs, 'sgXXX_mission_analyst.xlsx');

% set max gap between events in minutes
eventGap = 15;

% collapse log events
[tl, tlm] = collapseTritonLog(logFile, eventGap);

% simplify format for PAMpal
% create new simplified table for PAMpal processing
tls = tritonLogToPampal(tlm, glider);

% add the PAMpal eventID to tlm for reference
tlm.eventID = tls.id; 

% save everything
[~, lfName, ~] = fileparts(logFile);
save(fullfile(path_logs, [lfName '_collapsed.mat']), 'tl', 'tlm');
writetable(tls, fullfile(path_logs, [lfName '_collapsed_forPAMpal.csv']));

%% Workflow to do stuff with ERMA logs