function plotVoltagePackUse_norm(CONFIG, pp)
% PLOTVOLTAGEPACKUSE_NORM	Plot power draw by device normalized by dive duration
%
%	Syntax:
%		PLOTVOLTAGEPACKUSE_NORM(CONFIG, PP)
%
%	Description:
%		Plot power draw by different devices, each separately. Includes
%		VBD, pitch, and roll motors and PMAR. Power draw is normalized by
%       dive duration (in minutes) and plotted over time (days into
%       mission)
%
%	Inputs:
%		CONFIG      Mission/agate global configuration variable
%       pp          Piloting parameters table created with
%                   extractPilotingParams.m
%
%	Outputs:
%		no output, creates figure
%
%	Examples:
%       plotVoltagePackUse_norm(CONFIG, pp639)
%	See also
%       extractPilotingParams
%       plotVoltagePackUse
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	24 April 2023
%	Updated:
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figNum = CONFIG.plots.figNumList(7);
% set position
figPosition = [700    40    600    400];
% overwrite if in config
if isfield(CONFIG.plots, 'positions')
    % is a position defined for this figure
    fnIdx = find(figNum == CONFIG.plots.figNumList);
    if length(CONFIG.plots.positions) >= fnIdx && ~isempty(CONFIG.plots.positions{fnIdx})
        figPosition = CONFIG.plots.positions{fnIdx};
    end
end

figure(figNum); clf;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));
plot(timeDays, pp.pkJ./pp.diveDur_min, 'LineWidth', 2);
hold on;
plot(timeDays, pp.rkJ./pp.diveDur_min, 'LineWidth', 2);
plot(timeDays, pp.vkJ./pp.diveDur_min, 'LineWidth', 2);
if CONFIG.pm.loggers == 1
    plot(timeDays, pp.PMAR_kJ./pp.diveDur_min, 'LineWidth', 2);
end
ylim([0 max(pp.vkJ./pp.diveDur_min) + .1*max(pp.vkJ./pp.diveDur_min)]); 
ylabel('energy [kJ/min]');
xlim([0 max(timeDays)+5]); xlabel('days in mission');
grid on;
hold off;

title(['Glider ' CONFIG.glider ' Usage By Device - Normalized']);
if CONFIG.pm.loggers == 1
    legend('pitch motor', 'roll motor', 'vbd motor', 'pmar')
else
    legend('pitch motor', 'roll motor', 'vbd motor')
end

set(gca, 'FontSize', 14)
set(gcf, 'Position', figPosition)

end
