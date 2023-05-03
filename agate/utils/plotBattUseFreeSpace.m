function plotBattUseFreeSpace(CONFIG, pp, A0_24V)
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
%	Updated:        2 May 2023
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


figNum = CONFIG.plots.figNumList(3);
% set position
figPosition = [0    40    600   400];
% overwrite if in config
if isfield(CONFIG.plots, 'positions')
    % is a position defined for this figure
    fnIdx = find(figNum == CONFIG.plots.figNumList);
    if length(CONFIG.plots.positions) >= fnIdx && ...
            ~isempty(CONFIG.plots.positions{fnIdx})
        figPosition = CONFIG.plots.positions{fnIdx};
    end
end

% should this plot have a second axis (aka is there a PAM system?)
if (isfield(CONFIG, 'pm') || isfield (CONFIG, 'ws')) && ...
        (CONFIG.pm.loggers == 1 || CONFIG.ws.loggers == 1)
    y2 = 1;
    titleStr = [CONFIG.glider ' Battery Usage and Free Space'];
else
    y2 = 0;
    titleStr = [CONFIG.glider ' Battery Usage'];
end

% set up figure and x axis
figure(figNum); clf;
co = colororder;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));

if y2 == 1 % secondary y axis necessary
    yyaxis left
end
plot(timeDays, (A0_24V - pp.ampHrConsumed)/A0_24V*100, 'LineWidth', 2)
ylim([0 100]); ylabel('remaining battery [%]');
xlim([0 CONFIG.tmd + CONFIG.tmd*.1]); xlabel('days in mission');

% if PMAR is being used, plot free space remaining on secondary y axis
if isfield(CONFIG, 'pm') && CONFIG.pm.loggers == 1
    titleStr = [CONFIG.glider ' Battery Usage and Free Space'];
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
    titleStr = [CONFIG.glider ' Battery Usage Reported and Adjusted'];
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
        'LabelHorizontalAlignment', 'left')
end

set(gca, 'FontSize', 12)
set(gcf, 'Position', figPosition)



end
