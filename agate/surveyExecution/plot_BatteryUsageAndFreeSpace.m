function plot_BatteryUsageAndFreeSpace(dPARAMS, pp, targetMissionDur)


if nargin < 3
    targetMissionDur = [];
end

figNum = dPARAMS.figNumList(1);

figure(figNum); clf;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));
yyaxis left
plot(timeDays, (310 - pp.ampHrConsumed)/310*100, 'LineWidth', 2)
ylim([0 100]);ylabel('Remaining battery %');
xlim([0 targetMissionDur + 10]); xlabel('Days in Mission');

yyaxis right
uniqueCards = unique(pp.activeCard);
lineStyles = {'-', ':', '-', '-.'}; % options for up to 4 cards.
for f = 1:length(uniqueCards)
    ac = uniqueCards(f);
    % this card only
    tmpTimeDays = timeDays(pp.activeCard == ac);
    tmpFreeGB = pp.(['pmFree_' num2str(ac,'0%d') '_GB'])(pp.activeCard == ac);
    plot(tmpTimeDays, tmpFreeGB, lineStyles{f}, 'LineWidth', 2)
    ylim([0 500]);ylabel('Free Space [GB]');
    hline(35, 'k:'); % don't let free space drop below 7%/35 GB or it will stop recording
    hold on;
end
hold off;

grid on; title(['Glider ' dPARAMS.glider ' Battery Usage and Free Space']);
yyaxis left
hline(30, 'k--') % 30% battery safety threshold
if ~isempty(targetMissionDur)
    vline(targetMissionDur, 'k-.')
end
set(gca, 'FontSize', 14)

set(gcf, 'Position', [0    40    600    400])


end

