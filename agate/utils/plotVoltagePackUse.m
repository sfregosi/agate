function plotVoltagePackUse(CONFIG, pp)
% PLOTVOLTAGEPACKUSE	Plot zoomed in view of glider path on bathymetry 
%
%	Syntax:
%		PLOTVOLTAGEPACKUSE(CONFIG, PP)
%
%	Description:
%		Plot power draw by different devices, each separately. Includes
%		VBD, pitch, and roll motors and PMAR. Power draw is on a by dive
%		basis (not normalized by dive duration) but is plotted over time
%		(days into mission)
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
%       plotVoltagePackUse(CONFIG, pp639)
%	See also
%       extractPilotingParams
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	unknown
%	Updated:        21 April 2023
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figNum = CONFIG.figNumList(2);

figure(figNum); clf;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));
plot(timeDays, pp.pkJ, 'LineWidth', 2);
hold on;
plot(timeDays, pp.rkJ, 'LineWidth', 2);
plot(timeDays, pp.vkJ, 'LineWidth', 2);
plot(timeDays, pp.PMAR_kJ, 'LineWidth', 2);
ylim([0 30]); ylabel('energy [kJ]');
xlim([0 max(timeDays)+5]); xlabel('Days in Mission');
grid on;
hold off;

title(['Glider ' CONFIG.glider ' Usage By Device']);
set(gca, 'FontSize', 14)
set(gcf, 'Position', [600    40    600    400])

legend('pitch motor', 'roll motor', 'vbd motor', 'pmar')
end

