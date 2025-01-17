function plotVoltagePackUse_norm(CONFIG, pp)
%PLOTVOLTAGEPACKUSE_NORM	Plot power draw by device normalized by dive duration
%
%   Syntax:
%       PLOTVOLTAGEPACKUSE_NORM(CONFIG, pp)
%
%   Description:
%        Plot power draw by different devices, each separately. Includes
%        VBD, pitch, and roll motors and PMAR. Power draw is normalized by
%        dive duration (in minutes) and plotted over time (days into
%        mission)
%
%   Inputs:
%       CONFIG  agate mission configuration file with relevant mission and
%               glider information. Minimum CONFIG fields are 'glider'.
%               Optionally, the CONFIG.plots section can be set to specify
%               a figure number and set figure position
%       pp      Piloting parameters table created with extractPilotingParams
%
%   Outputs:
%       no output, creates figure
%
%   Examples:
%       plotVoltagePackUse_norm(CONFIG, pp639)
%
%	See also EXTRACTPILOTINGPARAMS, PLOTVOLTAGEPACKUSE
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   16 January 2025
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set figNum
figNum = []; % leave blank if not specified
% or pull from config if it is
if isfield(CONFIG, 'plots')
    if isfield(CONFIG.plots, 'figNumList')
        figNum = CONFIG.plots.figNumList(5);
    end
end

% set position
figPosition = [700    40    600    400];
% overwrite if in config
if isfield(CONFIG, 'plots') && ...
        isfield(CONFIG.plots, 'positions') && isfield(CONFIG.plots, 'figNumList')
    % is a position defined for this figure
    fnIdx = find(figNum == CONFIG.plots.figNumList);
    if length(CONFIG.plots.positions) >= fnIdx && ~isempty(CONFIG.plots.positions{fnIdx})
        figPosition = CONFIG.plots.positions{fnIdx};
    end
end

% set up figure and x axis
if isempty(figNum)
    figure;
else
    figure(figNum);
end 
set(gcf, 'Name', 'Normalized Power Draw by Device');
clf;

% plot
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));
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
xlim([0 max(timeDays)+5]); xlabel('days in mission');
grid on;
hold off;

title(['Glider ' CONFIG.glider ' Usage By Device - Normalized']);
if (isfield(CONFIG, 'pm') && CONFIG.pm.loggers == 1) || ...
		(isfield(CONFIG, 'ws') && CONFIG.ws.loggers == 1)
	legend(legendStrs, 'Location', 'EastOutside')
else
    hleg = legend('pitch', 'roll', 'vbd', 'Location', 'EastOutside');
    title(hleg, 'motors');
end

set(gca, 'FontSize', 12)
set(gcf, 'Position', figPosition)

end
