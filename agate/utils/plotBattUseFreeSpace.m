function plotBattUseFreeSpace(CONFIG, pp, A0_24V, tmd)
% PLOTBATTUSEFREESPACE	Plot battery usage free space (acoustics) remaining
%
%	Syntax:
%		PLOTBATTUSEFREESPACE(CONFIG, PP, A0_24V, TMD)
%
%	Description:
%		Plot of battery usage (as a percent, left yaxis) and free space
%		remaining on the acoustic SD card (right yaxis) over the course of
%		the deployment. A target mission duration (in days) can be
%		specified as well as horizontal lines for battery and data space
%		margins of error (e.g., 7% capacity left on SD card)
%
%	Inputs:
%		CONFIG      Mission/agate global configuration variable
%       pp          Piloting parameters table created with
%                   extractPilotingParams.m
%       A0_24V      Value of the $A0_24V parameter with total available amp
%                   hours for this glider (e.g., 310 for 15V system)
%       tmd         target mission duration in days
%
%	Outputs:
%		no output, creates figure
%
%	Examples:
%       plotBattUseFreeSpace(CONFIG, pp639, 310, 60)
%	See also
%       extractPilotingParams
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	unknown
%	Updated:        23 April 2023
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if nargin < 3
    tmd = [];
end

figNum = CONFIG.plots.figNumList(1);
% set position
figPosition = [0    40    600   400];
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
yyaxis left
plot(timeDays, (A0_24V - pp.ampHrConsumed)/A0_24V*100, 'LineWidth', 2)
ylim([0 100]);ylabel('remaining battery [%]');
xlim([0 tmd + 10]); xlabel('days in mission');

co = colororder;
if CONFIG.pm.loggers == 1
    yyaxis right
    uniqueCards = unique(pp.activeCard);
    lineStyles = {'-', ':', '-', '-.'}; % options for up to 4 cards.
    for f = 1:length(uniqueCards)
        ac = uniqueCards(f);
        % this card only
        tmpTimeDays = timeDays(pp.activeCard == ac);
        tmpFreeGB = pp.(['pmFree_' num2str(ac,'0%d') '_GB'])(pp.activeCard == ac);
        plot(tmpTimeDays, tmpFreeGB, lineStyles{f}, 'LineWidth', 2)
        ylim([0 500]);ylabel('free space [GB]');
        yline(35, ':', '35 GB', 'Color', co(2,:), 'LineWidth', 1.5); % don't let free space drop below 7%/35 GB or it will stop recording
        hold on;
    end
    hold off;
end

grid on; title(['Glider ' CONFIG.glider ' Battery Usage and Free Space']);
yyaxis left
yline(30, '--', '30%', 'Color', co(1,:), 'LineWidth', 1.5); % 30% battery safety threshold
if ~isempty(tmd)
    xline(tmd, 'k-.', {'target mission duration'}, 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left')
end
set(gca, 'FontSize', 14)

set(gcf, 'Position', figPosition)


end

