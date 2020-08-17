function plot_BatteryUsageAndFreeSpace_SD2(glider, pp)

figure(450); clf;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));
yyaxis left
plot(timeDays, (310 - pp.ampHrConsumed)/310*100, 'LineWidth', 2)
ylim([0 100]);ylabel('Remaining battery %');
xlim([0 60]); xlabel('Days in Mission');
yyaxis right
plot(timeDays(1:117), pp.PM_FREEGB(1:117) + 499.87, 'LineWidth', 2)
hold on
plot(timeDays(118:end), pp.PM_FREEGB(118:end),'-', 'LineWidth', 2)
ylim([0 (1000)]);ylabel('Free Space [GB]');
hline(1000 - (499.87*.95), 'k:')
hline(500 - (499.87*.95), 'r-.')

grid on; title(['Glider ' glider ' Battery Usage and Free Space']);
yyaxis left
hline(30, 'b--')
% vline(45, 'k-.')
set(gca, 'FontSize', 14)
set(gcf, 'Position', [1650    700    800    650])


end

