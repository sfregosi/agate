function plotPilotChecks(CONFIG, pp)
% PLOTPILOTCHECKS	Plot combined figure of essential pilot mission dchecks
%
%   Syntax:
%       OUTPUT = PLOTFLIGHTCHECKS(CONFIG, PP)
%
%   Description:
%       Create a single figure with multiple subplots that combines the
%       key mission/flight checks a pilot may need
%   Inputs:
%       CONFIG    [struct] agate global mission configuration from agate
%                 configuration file and initialized by agate.m
%       pp        [table] piloting parameters table created with
%                 extractPilotingParams.m
%
%	Outputs:
%       no output, creates figure
%
%   Examples:
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   26 May 2023
%   Updated:        4 June 2023
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figNum = 82;
% set position
figPosition = [100   60    1080   720];
% overwrite if in config
if isfield(CONFIG.plots, 'positions')
	% is a position defined for this figure
	fnIdx = find(figNum == CONFIG.plots.figNumList);
	if ~isempty(fnIdx)
		if ~isempty(CONFIG.plots.positions{fnIdx}) && ...
				length(CONFIG.plots.positions) >= fnIdx
			figPosition = CONFIG.plots.positions{fnIdx};
		end
	end
end

% set up figure and x axis
figure(figNum);
clf;
set(gcf, 'Name', 'Pilot Checks');

% set up subplots
t = tiledlayout(4, 2, 'TileSpacing', 'Compact');
% t = tiledlayout('flow', 'TileSpacing', 'Compact');

nexttile(1, [1 1])
humidity(pp)

nexttile(3, [1 1])
pressure(pp)

nexttile(2, [2 1])
A0_24V = 502;
battSpace(CONFIG, pp, A0_24V)

nexttile(5, [2 1])
minVolt(CONFIG,pp)

nexttile(6, [2 1])
devicePower(CONFIG, pp)

title(t, ['SG', CONFIG.glider(3:5) ' Dive' num2str(pp.diveNum(end))])
xlabel(t, 'days in mission')
set(gcf, 'Position', figPosition)

end

%%%%%%%%%%%%%%%%%%%
%% NESTED FUNCTIONS
%%%%%%%%%%%%%%%%%%%
% These are based on the plotBattUseFreeSpace, plotHumidityPressure,
% plotMinVolt, and plotVoltagePackUse functions.
% Those cannot just be automatically run here as nested tiles because of
% the figure number settings, but the basics of each is included as a
% nested function below, with some modifications to titles, etc

% humidity
function humidity(pp)
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1)); %#ok<DATNM>

plot(timeDays, pp.HUMID, '.');

xlim([0 max(timeDays)+5]);
% xticklabels([]);
ylabel('humidity [%]');
title('humidity');
set(gca, 'FontSize', 12)
grid on;
end

% pressure
function pressure(pp)
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1)); %#ok<DATNM>

plot(timeDays, pp.INTERNAL_PRESSURE, '.');

xlim([0 max(timeDays)+5]); 
% xlabel('days in mission');
ylabel('pressure [psi]');
title('internal pressure');
set(gca, 'FontSize', 12)
grid on;
end

% battery and free space
function battSpace(CONFIG, pp, A0_24V)

% should this plot have a second axis (aka is there a PAM system?)
if (isfield(CONFIG, 'pm') || isfield (CONFIG, 'ws')) && ...
		(CONFIG.pm.loggers == 1 || CONFIG.ws.loggers == 1)
	y2 = 1;
else
	y2 = 0;
	titleStr = 'battery remaining';
end

co = colororder;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1)); %#ok<DATNM>

if y2 == 1 % secondary y axis necessary
	yyaxis left
end
plot(timeDays, (A0_24V - pp.ampHrConsumed)/A0_24V*100, 'LineWidth', 2)
ylim([0 100]); ylabel('remaining battery [%]');
xlim([0 CONFIG.tmd + CONFIG.tmd*.1]); 
% xlabel('days in mission');

% if PMAR is being used, plot free space remaining on secondary y axis
if isfield(CONFIG, 'pm') && CONFIG.pm.loggers == 1
	titleStr = ' battery and space remaining';
	yyaxis right
	uniqueCards = unique(pp.activeCard);
	lineStyles = {'-', ':', '-', '-.'}; % options for up to 4 cards.
	for f = 1:length(uniqueCards)
		ac = uniqueCards(f);
		% this card only
		tmpTimeDays = timeDays(pp.activeCard == ac);
		tmpFreeGB = pp.(['pmFree_' num2str(ac,'0%d') '_GB'])(pp.activeCard == ac);
		plot(tmpTimeDays, tmpFreeGB, lineStyles{f}, 'LineWidth', 2)
		ylim([0 500]); ylabel('free space [GB]');
		yline(35, ':', '35 GB', 'Color', co(2,:), 'LineWidth', 1.5);
		% don't let free space drop below 7%/35 GB or it will stop recording
		hold on;
	end
	hold off;
end

% if WISPR is being used plot adjusted battery consumption (it is not
% accounted for internally by seaglider) on secondary y axis
if isfield(CONFIG, 'ws') && CONFIG.ws.loggers == 1
	titleStr = ' Battery remaining - reported and adjusted';
	yyaxis right
	plot(timeDays, (A0_24V - (pp.ampHrConsumed + pp.WS_ampHr))/A0_24V*100, ...
		'LineWidth', 2)
	ylim([0 100]); ylabel('WISPR adjusted battery [%]');

	% Link the 'Limits' property so they zoom together
	ax = gca();
	r1 = ax.YAxis(1);
	r2 = ax.YAxis(2);
	linkprop([r1 r2],'Limits');
end

% final formatting
grid on; title(titleStr);
if y2 == 1 % secondary y axis necessary
	yyaxis left
end
yline(30, '--', '30%', 'Color', co(1,:), 'LineWidth', 1.5); % 30% battery safety threshold
if ~isempty(CONFIG.tmd)
	xline(CONFIG.tmd, 'k-.', {'target mission duration'}, 'LineWidth', 1.5, ...
		'LabelHorizontalAlignment', 'right')
end
set(gca, 'FontSize', 12)

end


% minimum volts
function minVolt(CONFIG, pp)

timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1)); %#ok<DATNM> 
plot(timeDays, pp.minVolt_24, 'LineWidth', 2)
hold on
plot(timeDays, pp.minVolt_10, 'LineWidth', 2)
ylim([9 15]);ylabel('minimum voltage [V]');
xlim([0 max(timeDays)+5]); 
% xlabel('days in mission');

co = colororder;
% pull specified voltage lims from most recent dive
logFileList = dir(fullfile(CONFIG.path.bsLocal, ['p' CONFIG.glider(3:end) '*.log']));
x = fileread(fullfile(CONFIG.path.bsLocal, logFileList(end).name));

idx = strfind(x, '$MINV_24V');
sl = length('$MINV_24V');
idxBreak =  regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
val = str2double(x(idx+sl+1:idxBreak-1));
yline(val, '--', '$MINV\_24V', 'Color', co(1,:));

idx = strfind(x, '$MINV_10V');
sl = length('$MINV_10V');
idxBreak =  regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
val = str2double(x(idx+sl+1:idxBreak-1));
yline(val, '--', '$MINV\_10V', 'Color', co(2,:));

% finalize fig
grid on;
hold off;

title('minimum battery voltages');
set(gca, 'FontSize', 12)
legend('24V', '10V', 'orientation', 'horizontal', 'location', 'south')

end

% power draw by device
function devicePower(CONFIG, pp)

timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1)); %#ok<DATNM> 
plot(timeDays, pp.pkJ./pp.diveDur_min, 'LineWidth', 2);
hold on;
plot(timeDays, pp.rkJ./pp.diveDur_min, 'LineWidth', 2);
plot(timeDays, pp.vkJ./pp.diveDur_min, 'LineWidth', 2);

% add in pam info if present
if isfield(CONFIG, 'pm') && CONFIG.pm.loggers == 1
    plot(timeDays, pp.PMAR_kJ./pp.diveDur_min, 'LineWidth', 2);
		legendStrs = {'pitch', 'roll', 'vbd', 'pmar'};
end
if isfield(CONFIG, 'ws') && CONFIG.ws.loggers == 1
	plot(timeDays, pp.WS_kJ./pp.diveDur_min, 'LineWidth', 2);
	legendStrs = {'pitch', 'roll', 'vbd', 'wispr'};
end

ylim([0 max(pp.vkJ./pp.diveDur_min) + .1*max(pp.vkJ./pp.diveDur_min)]); 
ylabel('energy [kJ/min]');
xlim([0 max(timeDays)+5]); 
% xlabel('days in mission');
grid on;
hold off;

title('power draw by device');
if (isfield(CONFIG, 'pm') && CONFIG.pm.loggers == 1) || ...
		(isfield(CONFIG, 'ws') && CONFIG.ws.loggers == 1)
	legend(legendStrs, 'Location', 'EastOutside')
else
    hleg = legend('pitch', 'roll', 'vbd', 'Location', 'EastOutside');
    title(hleg, 'motors');
end

set(gca, 'FontSize', 12)

end


