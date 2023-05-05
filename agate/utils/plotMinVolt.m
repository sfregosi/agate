function plotMinVolt(CONFIG, pp)
%PLOTMINVOLT   Plot minimum reported battery voltage(s) over time
%
%   Syntax:
%       PLOTMINVOLT(CONFIG, pp)
%
%   Description:
%       Plot of minimum battery voltage(s) reported on each dive, over
%       time.
%       
%       For Rev B gliders, both 10V and 24V battery voltage is
%       plotted, even if it's a 2-15V glider.
%       
%       For Rev E gliders, a single voltage is reported and plotted
%
%   Inputs:
%       CONFIG   Mission/agate global configuration variable
%       pp       Piloting parameters table created with
%                extractPilotingParams.m
%
%   Outputs:
%       no output, creates figure
%
%	Examples:
%
%	See also EXTRACTPILOTINGPARAMS
%
%	Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   23 April 2023
%   Updated:        2 May 2023
% 
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


figNum = CONFIG.plots.figNumList(6);
% set position
figPosition = [800   40    600    400];
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
plot(timeDays, pp.minVolt_24, 'LineWidth', 2)
hold on
plot(timeDays, pp.minVolt_10, 'LineWidth', 2)
ylim([8 15]);ylabel('minimum voltage [V]');
xlim([0 max(timeDays)+5]); xlabel('days in mission');

co = colororder;
% pull specified voltage lims from most recent dive
logFileList = dir(fullfile(CONFIG.path.bsLocal, ['p' CONFIG.glider(3:end) '*.log']));
x = fileread(fullfile(CONFIG.path.bsLocal, logFileList(end).name));

idx = strfind(x, '$MINV_24V');
sl = length('$MINV_24V');
idxBreak =  regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
val = str2num(x(idx+sl+1:idxBreak-1));
yline(val, '--', '$MINV\_24V', 'Color', co(1,:));

idx = strfind(x, '$MINV_10V');
sl = length('$MINV_10V');
idxBreak =  regexp(x(idx+sl+1:end),'\n','once') + idx + sl;
val = str2num(x(idx+sl+1:idxBreak-1));
yline(val, '--', '$MINV\_10V', 'Color', co(2,:));

% finalize fig
grid on;
hold off;

title([CONFIG.glider ' Minimum Battery Voltages']);
set(gca, 'FontSize', 12)
legend('24V', '10V', 'orientation', 'horizontal', 'location', 'south')
set(gcf, 'Position', figPosition)

end

