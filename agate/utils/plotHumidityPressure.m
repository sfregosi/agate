function plotHumidityPressure(CONFIG, pp)
%PLOTHUMIDITYPRESSURE	Plot 2-panel fig with humidity and pressure over time
%
%   Syntax:
%       PLOTHUMIDITYPRESSURE(CONFIG, pp)
%
%   Description:
%       Plot humidity and pressure as measured in the pressure housing, as
%       a 2-panel figure, over time (days into mission) with one data point
%       per dive
%
%   Inputs:
%       CONFIG  agate mission configuration file with relevant mission and
%               glider information. Minimum CONFIG fields are 'glider'.
%               Optionally, the CONFIG.plots section can be set to specify
%               a figure number and set figure position.
%       pp      Piloting parameters table created with extractPilotingParams
%
%   Outputs:
%       no output, creates figure
%
%   Examples:
%       plotHumidityPressure(CONFIG, pp)
%
%   See also EXTRACTPILOTINGPARAMS
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
        figNum = CONFIG.plots.figNumList(2);
    end
end

% set position
figPosition = [1200    40    600    400];
% overwrite if in config
if isfield(CONFIG, 'plots') && ...
        isfield(CONFIG.plots, 'positions') && isfield(CONFIG.plots, 'figNumList')
    % is a position defined for this figure
    fnIdx = find(figNum == CONFIG.plots.figNumList);
    if length(CONFIG.plots.positions) >= fnIdx && ~isempty(CONFIG.plots.positions{fnIdx})
        figPosition = CONFIG.plots.positions{fnIdx};
    end
end

if isempty(figNum)
    figure;
else
    figure(figNum);
end

set(gcf, 'Name', 'Humidity & Pressure');
clf;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));
subplot(211);
plot(timeDays, pp.HUMID, '.');
xlim([0 max(timeDays)+5]);
xticklabels([]);
ylabel('humidity [%]');
% title(['Glider ' CONFIG.glider ' Humidity']);
title([CONFIG.glider ' Humidity & Internal Pressure'], 'FontSize', 14)
set(gca, 'FontSize', 12)
grid on;

subplot(212);
plot(timeDays, pp.INTERNAL_PRESSURE, '.');
xlim([0 max(timeDays)+5]); xlabel('days in mission');
ylabel('pressure [psi]');
% title(['Glider ' CONFIG.glider ' Internal Pressure']);
set(gca, 'FontSize', 12)
grid on;

set(gcf, 'Position', figPosition)

end

