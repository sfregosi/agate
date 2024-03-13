% WORKFLOW_PROCESSCETACEANENCOUNTERS
%	Workflow for creating summary plots and tables for cetacean encounters
%
%	Description:
%		This script takes inputs of glider positional data and cetacean
%		acoustic encounter data (identified by automated or manual methods)
%		and pairs them up to summarize cetacean encounters and create maps
%		of glider locations at the time of cetacean acoustic encounters
%
%       Sections:
%       (1) Cleanup encounter logs (either collapse Triton logs, or combine
%           ERMA detection logs
%       (2) Create encounter map
%
%	Notes
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	FirstVersion: 	09 March 2024
%	Updated:        13 March 2024
%
%    Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize agate - either specify a .cnf or leave blank to browse/select
agate secret/agate_config_sg679_MHI_May2023.cnf
global CONFIG

%% (1) Cleanup encounter logs

% ERMA detection logs
% ERMA detection logs are created per dive, so need to combine them all
ermaDets = combineErmaLogs(CONFIG.path.bsLocal, []);

% Triton detection logs
logFileName = [CONFIG.glider '_' CONFIG.mission '_MW.xls'];
logFile = fullfile(CONFIG.path.analysis, 'triton', 'wood', ...
	[glider '_' mission '_log_mw'], logFileName);
eventGap = 15;
[tl, tlm] = collapseTritonLog(logFile, eventGap);

%% (1) Create encounter map

% generate the basemap with bathymetry as figure 82, don't save .fig file
[baseFig] = createBasemap(CONFIG, 1, 82); 
