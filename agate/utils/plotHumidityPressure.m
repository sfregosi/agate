function plotHumidityPressure(CONFIG, pp)
% PLOTHUMIDITYPRESSURE	Plot 2-panel fig with humidity and pressure over time 
%
%	Syntax:
%		PLOTHUMIDITYPRESSURE(CONFIG, PP)
%
%	Description:
%		Plot humidity and pressure as measured in the pressure housing, as
%		a 2-panel figure, over time (days into mission) with one data point
%		per dive
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
%       plotHumidityPressure(CONFIG, pp639)
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
figNum = CONFIG.figNumList(3);

figure(figNum); clf;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));
subplot(211);
plot(timeDays, pp.HUMID, '.');
xlim([0 max(timeDays)+5]);
ylabel('humidity');
title(['Glider ' CONFIG.glider ' Humidity']);
set(gca, 'FontSize', 14)
grid on;

subplot(212);
plot(timeDays, pp.INTERNAL_PRESSURE, '.');
xlim([0 max(timeDays)+5]); xlabel('Days in Mission');
ylabel('internal pressure');
title(['Glider ' CONFIG.glider ' Internal Pressure']);
set(gca, 'FontSize', 14)
grid on;

set(gcf, 'Position', [1200    40    600    400])

end

